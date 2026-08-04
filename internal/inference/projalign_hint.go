package inference

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// Shape-only projection hint (ablation unit).
//
// Unlike the align_projection ReAct tool, this path never appears in the tool
// list, the workflow steps, or the iteration budget: the shape is fetched once
// while the prompt is being built and injected as a single static paragraph.
// To drop the whole experiment: set PROJALIGN_MODE=off (or delete this file
// plus the two guarded call sites in react.go).

const (
	projAlignModeOff   = "off"
	projAlignModeShape = "shape"
	projAlignModeTool  = "tool"

	projAlignHintTimeout = 25 * time.Second
)

// shapeHintPrecision is per-class precision measured offline on the v2 dev split
// (n=1534, output/eval_mps_dev_v2). Shapes below shapeHintMinPrecision are
// dropped rather than injected — "table" is close to a coin flip.
var shapeHintPrecision = map[string]float64{
	"list":   0.971,
	"scalar": 0.940,
	"entity": 0.827,
	"table":  0.583,
}

const shapeHintMinPrecision = 0.80

// ProjAlignModeFromEnv resolves the aligner mode. Default off — shape/tool are
// opt-in ablations (EX probes showed no reliable gain).
func ProjAlignModeFromEnv() string {
	switch strings.ToLower(strings.TrimSpace(os.Getenv("PROJALIGN_MODE"))) {
	case projAlignModeShape:
		return projAlignModeShape
	case projAlignModeTool:
		return projAlignModeTool
	default:
		return projAlignModeOff
	}
}

// projAlignMode resolves the configured mode, falling back to the environment.
func (p *Pipeline) projAlignMode() string {
	if p.config == nil {
		return projAlignModeOff
	}
	mode := strings.ToLower(strings.TrimSpace(p.config.ProjAlignMode))
	if mode == "" {
		mode = ProjAlignModeFromEnv()
	}
	switch mode {
	case projAlignModeTool, projAlignModeShape, projAlignModeOff:
		return mode
	}
	return projAlignModeShape
}

// projAlignToolActive reports whether the ReAct tool variant is in play. When
// false the prompt keeps its pre-aligner tool list and workflow numbering.
func (p *Pipeline) projAlignToolActive() bool {
	return p.config != nil && p.config.EnableProjAlignTool && p.projAlignMode() == projAlignModeTool
}

// FetchProjAlignShape asks the aligner for the projection shape only.
// Returns "" on any failure or on a shape we do not trust — callers treat an
// empty result as "no hint" and continue unchanged.
func FetchProjAlignShape(
	ctx context.Context,
	baseURL, question, evidence, schemaText string,
	logger *InferenceLogger,
) string {
	logf := func(format string, a ...interface{}) {
		if logger != nil {
			logger.Printf(format, a...)
		}
	}
	if strings.TrimSpace(question) == "" || strings.TrimSpace(schemaText) == "" {
		return ""
	}
	if strings.TrimSpace(baseURL) == "" {
		baseURL = ProjAlignURLFromEnv()
	}
	baseURL = strings.TrimRight(baseURL, "/")

	body, err := json.Marshal(projAlignRequest{
		Instruction:  projAlignInstruction,
		Input:        buildProjAlignUserInput(question, evidence, schemaText),
		MaxNewTokens: 96,
	})
	if err != nil {
		return ""
	}

	url := baseURL + "/v1/projalign"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return ""
	}
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: projAlignHintTimeout}
	resp, err := client.Do(req)
	if err != nil {
		logf("🎨 shape hint skipped (aligner unreachable %s): %v\n", url, err)
		return ""
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if resp.StatusCode != http.StatusOK {
		logf("🎨 shape hint skipped (aligner HTTP %d)\n", resp.StatusCode)
		return ""
	}

	var out projAlignResponse
	if err := json.Unmarshal(raw, &out); err != nil {
		logf("🎨 shape hint skipped (bad envelope): %v\n", err)
		return ""
	}
	shape := parseAlignShape(out.Text)
	if shape == "" {
		logf("🎨 shape hint skipped (no shape in %q)\n", truncateStr(strings.TrimSpace(out.Text), 120))
		return ""
	}
	if shapeHintPrecision[shape] < shapeHintMinPrecision {
		logf("🎨 shape hint dropped: %s (offline precision %.1f%% < %.0f%%)\n",
			shape, shapeHintPrecision[shape]*100, shapeHintMinPrecision*100)
		return ""
	}
	logf("🎨 shape hint: %s (aligner %.1fs, precision %.1f%%)\n",
		shape, out.LatencyS, shapeHintPrecision[shape]*100)
	return shape
}

// parseAlignShape pulls the shape out of the aligner's JSON. The model is only
// given 96 tokens, so the fields array is often truncated — a plain regex-free
// scan keeps the shape usable even when the JSON never closes.
func parseAlignShape(text string) string {
	var parsed struct {
		Shape string `json:"shape"`
	}
	trimmed := strings.TrimSpace(text)
	if err := json.Unmarshal([]byte(trimmed), &parsed); err == nil {
		if _, ok := shapeHintPrecision[parsed.Shape]; ok {
			return parsed.Shape
		}
	}
	lower := strings.ToLower(trimmed)
	idx := strings.Index(lower, `"shape"`)
	if idx < 0 {
		return ""
	}
	rest := lower[idx+len(`"shape"`):]
	for shape := range shapeHintPrecision {
		if pos := strings.Index(rest, `"`+shape+`"`); pos >= 0 && pos < 8 {
			return shape
		}
	}
	return ""
}

// FormatShapeHintForPrompt renders the hint as static context. Empty shape →
// empty string, so the prompt is byte-identical to a run without the aligner.
func FormatShapeHintForPrompt(shape string) string {
	var detail string
	switch shape {
	case "scalar":
		detail = "a single aggregate value — one row, one column, aggregate without GROUP BY"
	case "list":
		detail = "several rows of the same column(s) — no aggregate and no LIMIT"
	case "entity":
		detail = "one single row without aggregation — often needs ORDER BY ... LIMIT 1"
	default:
		return ""
	}
	return fmt.Sprintf(`Result Shape Prior: %s (%s)
This is a statistical prior over the answer's shape only — it says nothing about which columns, tables or joins to use. Ignore it silently when the question or Evidence implies a different shape.

`, strings.ToUpper(shape), detail)
}

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

	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
)

const (
	defaultProjAlignURL     = "http://10.26.132.52:18080"
	defaultProjAlignTimeout = 60 * time.Second
	projAlignInstruction    = "Predict BIRD gold SQL output projection as JSON " +
		"(keys: shape, fields[{name,kind}]). label_version=v2."
)

// ProjAlignTool calls the remote Projection Aligner HTTP service (Mac MPS).
// Soft taste reference — agent decides whether to follow.
type ProjAlignTool struct {
	baseURL    string
	dbName     string
	question   string
	evidence   string
	schemaText string
	logger     *InferenceLogger
	client     *http.Client
}

// NewProjAlignTool builds the tool. baseURL empty → PROJALIGN_URL env → default.
func NewProjAlignTool(baseURL, dbName, question, evidence, schemaText string) *ProjAlignTool {
	if strings.TrimSpace(baseURL) == "" {
		baseURL = strings.TrimSpace(os.Getenv("PROJALIGN_URL"))
	}
	if baseURL == "" {
		baseURL = defaultProjAlignURL
	}
	return &ProjAlignTool{
		baseURL:    strings.TrimRight(baseURL, "/"),
		dbName:     dbName,
		question:   question,
		evidence:   evidence,
		schemaText: schemaText,
		client:     &http.Client{Timeout: defaultProjAlignTimeout},
	}
}

func (t *ProjAlignTool) Name() string { return "align_projection" }

func (t *ProjAlignTool) Description() string {
	return `Consult the BIRD Projection Taste Aligner (specialist LoRA) for soft projection guidance.
Input: leave empty / "auto" to use the current question + linked schema (recommended).
Optional: short note is ignored; tool always uses bound question/evidence/schema.
Output: suggested shape + ordered fields[{name,kind}] from BIRD gold taste.
IMPORTANT: This is CONTEXT, not a hard contract — you may override when evidence/schema disagree.`
}

type projAlignRequest struct {
	Instruction  string `json:"instruction"`
	Input        string `json:"input"`
	MaxNewTokens int    `json:"max_new_tokens"`
}

type projAlignResponse struct {
	Text         string  `json:"text"`
	LatencyS     float64 `json:"latency_s"`
	Device       string  `json:"device"`
	InputTokens  int     `json:"input_tokens"`
	OutputTokens int     `json:"output_tokens"`
}

func (t *ProjAlignTool) Call(ctx context.Context, input string) (string, error) {
	logf := func(format string, a ...interface{}) {
		if t.logger != nil {
			t.logger.Printf(format, a...)
		} else {
			fmt.Printf(format, a...)
		}
	}
	_ = strings.TrimSpace(input)
	logf("\n🎨 Tool Call [align_projection]:\n")

	if strings.TrimSpace(t.question) == "" {
		msg := "❌ align_projection: no question bound"
		logf("Output: %s\n", msg)
		return msg, nil
	}
	if strings.TrimSpace(t.schemaText) == "" {
		msg := "❌ align_projection: empty schema (linker selected no tables?)"
		logf("Output: %s\n", msg)
		return msg, nil
	}

	userInput := buildProjAlignUserInput(t.question, t.evidence, t.schemaText)
	body, _ := json.Marshal(projAlignRequest{
		Instruction:  projAlignInstruction,
		Input:        userInput,
		MaxNewTokens: 96,
	})

	url := t.baseURL + "/v1/projalign"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		msg := fmt.Sprintf("❌ align_projection: build request failed: %v", err)
		logf("Output: %s\n", msg)
		return msg, nil
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := t.client.Do(req)
	if err != nil {
		msg := fmt.Sprintf("❌ align_projection unreachable (%s): %v\nContinue without it — write SQL from schema/evidence yourself.", url, err)
		logf("Output: %s\n", msg)
		return msg, nil
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if resp.StatusCode != http.StatusOK {
		msg := fmt.Sprintf("❌ align_projection HTTP %d: %s\nContinue without it.", resp.StatusCode, truncateStr(string(raw), 200))
		logf("Output: %s\n", msg)
		return msg, nil
	}

	var out projAlignResponse
	if err := json.Unmarshal(raw, &out); err != nil {
		msg := fmt.Sprintf("❌ align_projection bad JSON: %v\nContinue without it.", err)
		logf("Output: %s\n", msg)
		return msg, nil
	}
	pred := strings.TrimSpace(out.Text)
	if pred == "" {
		msg := "❌ align_projection returned empty text. Continue without it."
		logf("Output: %s\n", msg)
		return msg, nil
	}

	var sb strings.Builder
	sb.WriteString("✓ Projection Taste Aligner suggestion (SOFT REFERENCE — context over control):\n")
	sb.WriteString(pred)
	sb.WriteString("\n\nHow to use:\n")
	sb.WriteString("- shape/fields reflect BIRD gold *taste* (what columns to return / count-vs-list quirks).\n")
	sb.WriteString("- Prefer this when it matches the question + evidence.\n")
	sb.WriteString("- OVERRIDE freely if it conflicts with evidence formulas, linked schema, or verify_sql.\n")
	sb.WriteString("- You still own JOIN/filters/SQL correctness. Do not treat this as a forced SELECT list.\n")
	if out.LatencyS > 0 {
		sb.WriteString(fmt.Sprintf("(aligner latency=%.1fs device=%s)\n", out.LatencyS, out.Device))
	}
	msg := sb.String()
	logf("Output: %s\n", msg)
	return msg, nil
}

func buildProjAlignUserInput(question, evidence, schema string) string {
	var b strings.Builder
	b.WriteString("You predict the BIRD gold SQL output projection (not the full SQL).\n")
	b.WriteString("Return ONLY a JSON object with keys:\n")
	b.WriteString("  shape: one of \"scalar\" | \"list\" | \"entity\" | \"table\"\n")
	b.WriteString("  fields: ordered list of {name, kind} where kind in col|count|avg|sum|max|min|star\n")
	b.WriteString("Rules:\n")
	b.WriteString("- Follow gold taste: if gold returns a row list instead of COUNT, use shape=list.\n")
	b.WriteString("- field.name is a SHORT label: SQL alias if present, else bare column name ")
	b.WriteString("(NO table prefix like T1./movies.).\n")
	b.WriteString("- For aggregates: kind encodes the agg; name is the aggregated column ")
	b.WriteString("(or \"*\" for COUNT(*)).\n")
	b.WriteString("- Do NOT put full SQL expressions into name (no COUNT(...), no AVG(...)).\n")
	b.WriteString("- Preserve field ORDER as in the gold SELECT list.\n\n")
	b.WriteString(schema)
	b.WriteString("\n\nQuestion: ")
	b.WriteString(question)
	b.WriteString("\nEvidence: ")
	b.WriteString(emptyNone(evidence))
	b.WriteString("\n")
	return b.String()
}

func emptyNone(s string) string {
	if strings.TrimSpace(s) == "" {
		return "(none)"
	}
	return s
}

func truncateStr(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "..."
}

// BuildAlignerSchemaText builds v2-style Tables/Columns text for linked tables.
func BuildAlignerSchemaText(shared *contextpkg.SharedContext, dbName string, tables []string) string {
	if dbName == "" && shared != nil {
		dbName = shared.DatabaseName
	}
	var lines []string
	lines = append(lines, "Database: "+dbName, "Tables/Columns:")
	if shared == nil || len(tables) == 0 {
		lines = append(lines, "(schema unavailable)")
		return strings.Join(lines, "\n")
	}

	// Preserve linker order; case-insensitive lookup
	byLower := map[string]string{}
	for name := range shared.Tables {
		byLower[strings.ToLower(name)] = name
	}

	emitted := 0
	for _, want := range tables {
		key := byLower[strings.ToLower(want)]
		if key == "" {
			continue
		}
		tm := shared.Tables[key]
		if tm == nil {
			continue
		}
		cols := make([]string, 0, len(tm.Columns))
		for i, c := range tm.Columns {
			if i >= 40 {
				cols = append(cols, "...")
				break
			}
			cols = append(cols, c.Name)
		}
		lines = append(lines, fmt.Sprintf("- %s(%s)", key, strings.Join(cols, ", ")))
		emitted++
	}
	if emitted == 0 {
		lines = append(lines, "(no matching tables in rich context)")
	}
	return strings.Join(lines, "\n")
}

// ProjAlignURLFromEnv returns configured aligner base URL.
func ProjAlignURLFromEnv() string {
	if v := strings.TrimSpace(os.Getenv("PROJALIGN_URL")); v != "" {
		return strings.TrimRight(v, "/")
	}
	return defaultProjAlignURL
}

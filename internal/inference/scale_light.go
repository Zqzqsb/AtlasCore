package inference

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"sort"
	"strings"
)

// ScaleCandidate is one SQL candidate from scale_light.
type ScaleCandidate struct {
	SQL       string
	Source    string // e.g. primary / temp_0.3 / contract_strict
	ExecOK    bool
	ExecErr   string
	ResultKey string
	RowCount  int
}

// SelectByExecutionVote groups candidates by execution result fingerprint and
// picks the largest group (ties → first executable in original order).
func SelectByExecutionVote(cands []ScaleCandidate) (string, []ScaleCandidate) {
	if len(cands) == 0 {
		return "", cands
	}

	type group struct {
		key   string
		count int
		first int
		sql   string
	}
	groups := map[string]*group{}
	var order []string

	for i, c := range cands {
		if !c.ExecOK || c.ResultKey == "" {
			continue
		}
		g, ok := groups[c.ResultKey]
		if !ok {
			g = &group{key: c.ResultKey, first: i, sql: c.SQL}
			groups[c.ResultKey] = g
			order = append(order, c.ResultKey)
		}
		g.count++
	}

	if len(groups) == 0 {
		// Fallback: first non-empty SQL
		for _, c := range cands {
			if strings.TrimSpace(c.SQL) != "" {
				return c.SQL, cands
			}
		}
		return "", cands
	}

	best := groups[order[0]]
	for _, k := range order[1:] {
		g := groups[k]
		if g.count > best.count || (g.count == best.count && g.first < best.first) {
			best = g
		}
	}
	return best.sql, cands
}

// FingerprintQueryResult builds a stable key from columns + sorted row tuples.
func FingerprintQueryResult(columns []string, rows []map[string]interface{}, maxRows int) string {
	cols := append([]string{}, columns...)
	sort.Strings(cols)

	if maxRows <= 0 {
		maxRows = 50
	}
	type tuple []string
	var tuples []string
	limit := len(rows)
	if limit > maxRows {
		limit = maxRows
	}
	for i := 0; i < limit; i++ {
		row := rows[i]
		parts := make([]string, len(cols))
		for j, c := range cols {
			parts[j] = fmt.Sprintf("%v", row[c])
		}
		tuples = append(tuples, strings.Join(parts, "\x1f"))
	}
	sort.Strings(tuples)

	payload, _ := json.Marshal(struct {
		Cols  []string `json:"c"`
		Rows  []string `json:"r"`
		Total int      `json:"n"`
	}{Cols: cols, Rows: tuples, Total: len(rows)})

	sum := sha256.Sum256(payload)
	return hex.EncodeToString(sum[:16])
}

// RunScaleLight generates multiple SQL variants and selects by execution vote.
// primarySQL should already be produced by the main ReAct/one-shot path.
func (p *Pipeline) RunScaleLight(ctx context.Context, query, contextPrompt, crossTableSummary, primarySQL string, result *Result) (string, []ScaleCandidate, error) {
	n := p.config.ScaleCandidates
	if n < 2 {
		return primarySQL, nil, nil
	}

	cands := []ScaleCandidate{}

	// Evaluate helper
	evalOne := func(sql, source string) ScaleCandidate {
		c := ScaleCandidate{SQL: strings.TrimSpace(sql), Source: source}
		if c.SQL == "" {
			c.ExecErr = "empty sql"
			return c
		}
		data, err := p.adapter.ExecuteQuery(ctx, c.SQL)
		if err != nil {
			c.ExecErr = err.Error()
			return c
		}
		c.ExecOK = true
		c.RowCount = data.RowCount
		c.ResultKey = FingerprintQueryResult(data.Columns, data.Rows, 50)
		return c
	}

	cands = append(cands, evalOne(primarySQL, "primary"))

	variants := scalePromptVariants(n - 1)
	basePrompt := p.buildPrompt(query, contextPrompt, crossTableSummary, false)

	for i, variant := range variants {
		prompt := basePrompt + "\n" + variant.suffix
		resp, err := p.llm.Call(ctx, prompt)
		result.LLMCalls++
		if err != nil {
			cands = append(cands, ScaleCandidate{Source: variant.name, ExecErr: err.Error()})
			continue
		}
		p.promptTexts = append(p.promptTexts, prompt)
		p.responseTexts = append(p.responseTexts, resp)
		sql := p.extractSQL(resp)
		cands = append(cands, evalOne(sql, fmt.Sprintf("%s_%d", variant.name, i)))
	}

	chosen, cands := SelectByExecutionVote(cands)
	if chosen == "" {
		chosen = primarySQL
	}
	return chosen, cands, nil
}

type scaleVariant struct {
	name   string
	suffix string
}

func scalePromptVariants(k int) []scaleVariant {
	all := []scaleVariant{
		{name: "direct", suffix: "Variant instruction: Prefer a more direct SQL with fewer subqueries when equivalent.\nOutput Format B (Final Answer) only — do not call tools."},
		{name: "decomp", suffix: "Variant instruction: Mentally decompose the question into filters / joins / aggregation, then write SQL.\nOutput Format B (Final Answer) only — do not call tools."},
		{name: "strict_proj", suffix: "Variant instruction: Be stricter on projection — only columns required by the OUTPUT CONTRACT / question.\nOutput Format B (Final Answer) only — do not call tools."},
		{name: "evidence", suffix: "Variant instruction: Re-read Evidence carefully; encode every evidence formula literally.\nOutput Format B (Final Answer) only — do not call tools."},
		{name: "alt_join", suffix: "Variant instruction: Consider an alternative join path if multiple FKs exist; still return correct projection.\nOutput Format B (Final Answer) only — do not call tools."},
		{name: "safe_null", suffix: "Variant instruction: Guard against NULL traps (IS NULL / IFNULL) when evidence implies missing values.\nOutput Format B (Final Answer) only — do not call tools."},
		{name: "order_limit", suffix: "Variant instruction: If ranking/top-N is implied, ensure ORDER BY + LIMIT are present.\nOutput Format B (Final Answer) only — do not call tools."},
	}
	if k > len(all) {
		k = len(all)
	}
	if k < 0 {
		k = 0
	}
	return all[:k]
}

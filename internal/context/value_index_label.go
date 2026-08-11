package context

import (
	"context"
	"fmt"
	"strings"

	"github.com/tmc/langchaingo/llms"

	"github.com/Zqzqsb/AtlasCore/internal/valueindex"
)

// LabelValueIndexHeuristic stamps include/exclude/unknown on every column using
// deterministic name/type gates (no LLM). Safe default before index build.
func (c *SharedContext) LabelValueIndexHeuristic() (include, exclude, unknown int) {
	if c == nil {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	for tName, table := range c.Tables {
		if table == nil {
			continue
		}
		if table.Name == "" {
			table.Name = tName
		}
		for i := range table.Columns {
			col := &table.Columns[i]
			spec := valueindex.ColumnSpec{
				Table: tName, Column: col.Name, DeclType: col.Type,
				IsPK: col.IsPrimaryKey, NRows: table.RowCount,
			}
			if col.ValueStats != nil {
				spec.NDV = col.ValueStats.DistinctCount
			}
			policy, kind, reason := valueindex.HeuristicPolicy(spec)
			col.ValueIndexPolicy = policy
			col.ValueIndexPolicySource = "heuristic"
			col.ValueIndexPolicyReason = reason
			if kind != "" {
				col.ValueIndexKind = kind
			}
			switch policy {
			case valueindex.PolicyInclude:
				include++
			case valueindex.PolicyExclude:
				exclude++
			default:
				unknown++
			}
		}
	}
	if c.ValueIndex == nil {
		c.ValueIndex = &ValueIndexInfo{}
	}
	c.ValueIndex.LabelSource = "heuristic"
	return include, exclude, unknown
}

// LabelValueIndexWithLLM asks the model for include/exclude on TEXT columns that
// are not already hard-excluded by HeuristicPolicy. Hard gates always win.
func (c *SharedContext) LabelValueIndexWithLLM(ctx context.Context, llm llms.Model) (include, exclude, unknown int, err error) {
	if c == nil {
		return 0, 0, 0, fmt.Errorf("nil context")
	}
	if llm == nil {
		return 0, 0, 0, fmt.Errorf("nil llm")
	}
	// Seed with heuristic so PK/time/etc. stay excluded even if LLM is noisy.
	c.LabelValueIndexHeuristic()

	type cand struct {
		key, line string
	}
	var cands []cand
	c.mu.RLock()
	for tName, table := range c.Tables {
		if table == nil {
			continue
		}
		for _, col := range table.Columns {
			if col.ValueIndexPolicy == valueindex.PolicyExclude && col.ValueIndexPolicyReason != "other_text" {
				// keep hard excludes; allow LLM to decide unknown/other_text and includes
				if col.ValueIndexPolicyReason == "primary_key" || col.ValueIndexPolicyReason == "name_gate" ||
					col.ValueIndexPolicyReason == "non_text_type" {
					continue
				}
			}
			if !valueindex.IsTextDecl(col.Type) || col.IsPrimaryKey {
				continue
			}
			ndv := 0
			if col.ValueStats != nil {
				ndv = col.ValueStats.DistinctCount
			}
			line := fmt.Sprintf("%s.%s | type=%s ndv=%d rows=%d meaning=%s",
				tName, col.Name, col.Type, ndv, table.RowCount, trimRunes(col.OfficialMeaning, 80))
			cands = append(cands, cand{key: strings.ToLower(tName + "." + col.Name), line: line})
		}
	}
	c.mu.RUnlock()
	if len(cands) == 0 {
		return c.countPolicies()
	}

	var b strings.Builder
	b.WriteString("You label columns for a business-value inverted index used in Text-to-SQL linking.\n")
	b.WriteString("For each column output ONE line: table.column | include|exclude|unknown | short reason\n")
	b.WriteString("include = high-value entity/category literals worth indexing (customer/product/city/status...)\n")
	b.WriteString("exclude = ids, timestamps, free text, urls, PII, codes not used as filter names\n")
	b.WriteString("unknown = unsure\n")
	b.WriteString("Max 80 lines. No markdown.\n\nColumns:\n")
	limit := len(cands)
	if limit > 80 {
		limit = 80
	}
	for i := 0; i < limit; i++ {
		b.WriteString(cands[i].line)
		b.WriteByte('\n')
	}

	resp, err := llm.Call(ctx, b.String())
	if err != nil {
		return 0, 0, 0, err
	}
	parsed := parseValueIndexLabels(resp)

	c.mu.Lock()
	defer c.mu.Unlock()
	for tName, table := range c.Tables {
		if table == nil {
			continue
		}
		for i := range table.Columns {
			col := &table.Columns[i]
			key := strings.ToLower(tName + "." + col.Name)
			// Never override hard heuristic excludes.
			if col.ValueIndexPolicy == valueindex.PolicyExclude &&
				(col.ValueIndexPolicyReason == "primary_key" || col.ValueIndexPolicyReason == "name_gate" ||
					col.ValueIndexPolicyReason == "non_text_type") {
				continue
			}
			if lab, ok := parsed[key]; ok {
				col.ValueIndexPolicy = lab.policy
				col.ValueIndexPolicySource = "llm"
				col.ValueIndexPolicyReason = lab.reason
				if lab.policy == valueindex.PolicyInclude && col.ValueIndexKind == "" {
					col.ValueIndexKind = "entity"
				}
			}
		}
	}
	if c.ValueIndex == nil {
		c.ValueIndex = &ValueIndexInfo{}
	}
	c.ValueIndex.LabelSource = "llm"
	inc, exc, unk := c.countPoliciesUnlocked()
	return inc, exc, unk, nil
}

type viLabel struct {
	policy, reason string
}

func parseValueIndexLabels(resp string) map[string]viLabel {
	out := map[string]viLabel{}
	for _, line := range strings.Split(resp, "\n") {
		line = strings.TrimSpace(line)
		line = strings.TrimPrefix(line, "- ")
		line = strings.TrimPrefix(line, "* ")
		if line == "" {
			continue
		}
		parts := strings.Split(line, "|")
		if len(parts) < 2 {
			continue
		}
		left := strings.TrimSpace(strings.ReplaceAll(parts[0], "`", ""))
		policy := strings.ToLower(strings.TrimSpace(parts[1]))
		reason := ""
		if len(parts) >= 3 {
			reason = strings.TrimSpace(parts[2])
		}
		switch policy {
		case valueindex.PolicyInclude, valueindex.PolicyExclude, valueindex.PolicyUnknown:
		default:
			continue
		}
		segs := strings.Split(left, ".")
		if len(segs) != 2 {
			continue
		}
		key := strings.ToLower(strings.TrimSpace(segs[0]) + "." + strings.TrimSpace(segs[1]))
		out[key] = viLabel{policy: policy, reason: reason}
	}
	return out
}

func (c *SharedContext) countPolicies() (include, exclude, unknown int, err error) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	include, exclude, unknown = c.countPoliciesUnlocked()
	return
}

func (c *SharedContext) countPoliciesUnlocked() (include, exclude, unknown int) {
	for _, table := range c.Tables {
		if table == nil {
			continue
		}
		for _, col := range table.Columns {
			switch col.ValueIndexPolicy {
			case valueindex.PolicyInclude:
				include++
			case valueindex.PolicyExclude:
				exclude++
			default:
				unknown++
			}
		}
	}
	return
}

func trimRunes(s string, n int) string {
	s = strings.TrimSpace(s)
	r := []rune(s)
	if len(r) <= n {
		return s
	}
	return string(r[:n]) + "…"
}

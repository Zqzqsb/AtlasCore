package valueindex

import (
	"context"
	"fmt"
	"sort"
	"strings"
)

// Hit is a value→column match (deterministic positive evidence).
type Hit struct {
	Table        string  `json:"table"`
	Column       string  `json:"column"`
	DisplayValue string  `json:"display_value"`
	MatchedText  string  `json:"matched_text"`
	MatchType    string  `json:"match_type"` // exact|token
	Score        float32 `json:"score"`
	ValueKind    string  `json:"value_kind,omitempty"`
}

// Lookup scores query text against the inverted index.
// Exact normalized match ranks above token overlap.
func (s *Store) Lookup(ctx context.Context, query string, topK int) ([]Hit, error) {
	if s == nil || s.db == nil {
		return nil, fmt.Errorf("valueindex: nil store")
	}
	if topK <= 0 {
		topK = 20
	}
	norm := Normalize(query)
	if norm == "" {
		return nil, nil
	}

	// 1) Exact normalized value hits
	rows, err := s.db.QueryContext(ctx, `
		SELECT table_name, column_name, display_value, value_kind
		FROM documents WHERE normalized_value = ? LIMIT ?`, norm, topK)
	if err != nil {
		return nil, err
	}
	var hits []Hit
	seen := map[string]bool{}
	for rows.Next() {
		var h Hit
		if err := rows.Scan(&h.Table, &h.Column, &h.DisplayValue, &h.ValueKind); err != nil {
			_ = rows.Close()
			return nil, err
		}
		h.MatchedText = query
		h.MatchType = "exact"
		h.Score = 1.0
		key := h.Table + "\x00" + h.Column + "\x00" + h.DisplayValue
		seen[key] = true
		hits = append(hits, h)
	}
	_ = rows.Close()
	if len(hits) >= topK {
		return hits[:topK], nil
	}

	// 2) Token overlap
	toks := Tokens(norm)
	if len(toks) == 0 {
		return hits, nil
	}
	type agg struct {
		table, column, display, kind string
		terms                        int
		bestType                     string
	}
	scores := map[int]*agg{}
	for _, tok := range toks {
		qrows, err := s.db.QueryContext(ctx, `
			SELECT p.doc_id, p.token_type, d.table_name, d.column_name, d.display_value, d.value_kind
			FROM postings p
			JOIN documents d ON d.doc_id = p.doc_id
			WHERE p.token = ? AND p.token_type = ?
			LIMIT 200`, tok.Token, tok.Type)
		if err != nil {
			return hits, err
		}
		for qrows.Next() {
			var docID int
			var tokenType, table, column, display, kind string
			if err := qrows.Scan(&docID, &tokenType, &table, &column, &display, &kind); err != nil {
				_ = qrows.Close()
				return hits, err
			}
			key := table + "\x00" + column + "\x00" + display
			if seen[key] {
				continue
			}
			a := scores[docID]
			if a == nil {
				a = &agg{table: table, column: column, display: display, kind: kind, bestType: tokenType}
				scores[docID] = a
			}
			a.terms++
			if tokenType == "word" || tokenType == "cjk3" {
				a.bestType = tokenType
			}
		}
		_ = qrows.Close()
	}

	var ranked []Hit
	nTok := float32(len(toks))
	for _, a := range scores {
		score := float32(a.terms) / nTok
		if a.bestType == "word" {
			score += 0.15
		}
		if score > 1 {
			score = 1
		}
		ranked = append(ranked, Hit{
			Table: a.table, Column: a.column, DisplayValue: a.display,
			MatchedText: query, MatchType: "token", Score: score, ValueKind: a.kind,
		})
	}
	sort.Slice(ranked, func(i, j int) bool {
		if ranked[i].Score != ranked[j].Score {
			return ranked[i].Score > ranked[j].Score
		}
		return ranked[i].Table+"."+ranked[i].Column < ranked[j].Table+"."+ranked[j].Column
	})
	for _, h := range ranked {
		if len(hits) >= topK {
			break
		}
		hits = append(hits, h)
	}
	return hits, nil
}

// FormatHitsCompact renders short positive-evidence lines for linker prompts.
func FormatHitsCompact(hits []Hit) string {
	if len(hits) == 0 {
		return ""
	}
	var b strings.Builder
	b.WriteString("Value index matches (deterministic positive evidence; not proof of absence):\n")
	for _, h := range hits {
		fmt.Fprintf(&b, "- %s.%s = %q (query %q, %s, score=%.2f)\n",
			h.Table, h.Column, h.DisplayValue, h.MatchedText, h.MatchType, h.Score)
	}
	return b.String()
}

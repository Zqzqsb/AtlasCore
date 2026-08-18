package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/Zqzqsb/AtlasCore/internal/inference"
	"github.com/Zqzqsb/AtlasCore/internal/valueindex"
)

func main() {
	contextDir := flag.String("context-dir", "contexts/sqlite/bird_heldout_v1_vi", "RC directory containing value_index sidecars")
	limit := flag.Int("limit", 30, "Questions to audit (0 = all)")
	flag.Parse()

	var tests []map[string]any
	var golds []map[string]any
	b, _ := os.ReadFile("benchmarks/bird/heldout_v1_smoke/test.json")
	_ = json.Unmarshal(b, &tests)
	b, _ = os.ReadFile("benchmarks/bird/heldout_v1_smoke_private/gold.json")
	_ = json.Unmarshal(b, &golds)

	n := *limit
	if n <= 0 {
		n = len(tests)
	}
	if len(tests) < n {
		n = len(tests)
	}
	fired, useful, exactUseful, totalHits, noiseHits := 0, 0, 0, 0, 0
	for i := 0; i < n; i++ {
		db := tests[i]["db_id"].(string)
		q := tests[i]["question"].(string)
		ev, _ := tests[i]["evidence"].(string)
		gsql := golds[i]["SQL"].(string)
		path := filepath.Join(*contextDir, "value_index", db+".sqlite")
		st, err := valueindex.OpenStore(path)
		if err != nil {
			fmt.Printf("#%d %s NO_STORE\n", i, db)
			continue
		}
		qs := inference.ExtractValueIndexQueries(q, ev)
		var all []valueindex.Hit
		seen := map[string]bool{}
		for _, query := range qs {
			hits, _ := st.Lookup(context.Background(), query, 8)
			for _, h := range hits {
				if !keep(h) {
					continue
				}
				k := h.Table + "." + h.Column + "=" + h.DisplayValue
				if seen[k] {
					continue
				}
				seen[k] = true
				all = append(all, h)
			}
		}
		_ = st.Close()
		if len(all) == 0 {
			fmt.Printf("#%d %s q=%d hits=0 queries=%v\n", i, db, len(qs), qs)
			continue
		}
		fired++
		totalHits += len(all)
		u, eu := 0, 0
		gU := strings.ToUpper(gsql)
		for _, h := range all {
			ok := strings.Contains(gU, strings.ToUpper(h.Table)) || strings.Contains(gsql, h.DisplayValue)
			if ok {
				u++
			} else {
				noiseHits++
			}
			if ok && strings.EqualFold(h.MatchType, "exact") {
				eu++
			}
		}
		if u > 0 {
			useful++
		}
		if eu > 0 {
			exactUseful++
		}
		fmt.Printf("#%d %s queries=%d hits=%d usefulHits=%d/%d exactU=%d first=%s.%s=%q(%s)\n",
			i, db, len(qs), len(all), u, len(all), eu, all[0].Table, all[0].Column, all[0].DisplayValue, all[0].MatchType)
	}
	noiseRatio := 0.0
	if totalHits > 0 {
		noiseRatio = float64(noiseHits) / float64(totalHits)
	}
	fmt.Printf("\nSUMMARY n=%d fired=%d useful_any=%d exact_useful_any=%d totalHits=%d noiseHits=%d noise_ratio=%.2f\n",
		n, fired, useful, exactUseful, totalHits, noiseHits, noiseRatio)
}

// Mirrors inference.keepValueIndexHit (exact, or long substring token).
func keep(h valueindex.Hit) bool {
	if strings.EqualFold(h.MatchType, "exact") {
		return true
	}
	q := strings.TrimSpace(strings.ToLower(h.MatchedText))
	d := strings.TrimSpace(strings.ToLower(h.DisplayValue))
	if len([]rune(q)) < 5 || d == "" {
		return false
	}
	return strings.Contains(d, q)
}

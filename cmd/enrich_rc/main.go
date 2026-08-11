package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/tmc/langchaingo/llms"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
	"github.com/Zqzqsb/AtlasCore/internal/llm"
)

// enrich_rc re-runs deterministic RC enrichment (sample values, FK cardinality,
// join paths, text-shape ProfileNL) on existing context JSON.
// Optionally bake official column_meaning, label value-index columns, and build
// a per-DB business-value inverted index sidecar (iter14).
//
// Example (held-out offline build):
//
//	go run ./cmd/enrich_rc \
//	  --context-dir contexts/sqlite/bird_heldout_v1_vi \
//	  --db-dir benchmarks/bird/heldout_v1_smoke/test_databases \
//	  --column-meaning benchmarks/bird/heldout_v1_smoke/column_meaning.json \
//	  --value-index --value-index-label heuristic
func main() {
	contextDir := flag.String("context-dir", "contexts/sqlite/bird_heldout_v1", "Directory of RC JSON files")
	dbDir := flag.String("db-dir", "benchmarks/bird/heldout_v1_smoke/test_databases", "Directory of sqlite DBs (<db>/<db>.sqlite)")
	columnMeaningPath := flag.String("column-meaning", "", "Optional column_meaning.json to bake into OfficialMeaning")
	valueIndex := flag.Bool("value-index", true, "Build per-DB business-value inverted index sidecar under <context-dir>/value_index/")
	valueIndexLabel := flag.String("value-index-label", "heuristic", "Column policy labeling: heuristic | llm | off")
	labelModel := flag.String("label-model", "deepseek-v4-flash", "LLM for --value-index-label=llm")
	limit := flag.Int("limit", 0, "Max DBs to enrich (0 = all)")
	dbFilter := flag.String("db", "", "Only enrich this db_id")
	resumeAfter := flag.String("resume-after", "", "Skip DBs with name <= this (lexicographic), e.g. ice_hockey_draft")
	skipEnriched := flag.Bool("skip-enriched", false, "Skip DBs that already have non-empty join_paths")
	quiet := flag.Bool("quiet", false, "Less logging")
	flag.Parse()

	labelMode := strings.ToLower(strings.TrimSpace(*valueIndexLabel))
	switch labelMode {
	case "heuristic", "llm", "off":
	default:
		log.Fatalf("invalid --value-index-label %q (want heuristic|llm|off)", *valueIndexLabel)
	}

	var meaningRaw map[string]string
	if *columnMeaningPath != "" {
		data, err := os.ReadFile(*columnMeaningPath)
		if err != nil {
			log.Fatalf("read column-meaning: %v", err)
		}
		if err := json.Unmarshal(data, &meaningRaw); err != nil {
			log.Fatalf("parse column-meaning: %v", err)
		}
		fmt.Printf("📚 Loaded column_meaning entries: %d\n", len(meaningRaw))
	}

	var labelLLM llms.Model
	if labelMode == "llm" {
		m, err := llm.CreateLLMByType(llm.ModelType(*labelModel))
		if err != nil {
			log.Fatalf("label-model: %v", err)
		}
		labelLLM = m
		fmt.Printf("🏷️  Value-index label model: %s\n", *labelModel)
	}

	entries, err := os.ReadDir(*contextDir)
	if err != nil {
		log.Fatalf("read context-dir: %v", err)
	}

	ctx := context.Background()
	done, fail, skipped := 0, 0, 0
	start := time.Now()

	for _, ent := range entries {
		if ent.IsDir() || !strings.HasSuffix(ent.Name(), ".json") {
			continue
		}
		dbID := strings.TrimSuffix(ent.Name(), ".json")
		if *dbFilter != "" && dbID != *dbFilter {
			continue
		}
		if *resumeAfter != "" && dbID <= *resumeAfter {
			skipped++
			continue
		}
		if *limit > 0 && done+fail >= *limit {
			break
		}

		jsonPath := filepath.Join(*contextDir, ent.Name())
		if *skipEnriched {
			if sharedPeek, err := contextpkg.LoadContextFromFile(jsonPath); err == nil && len(sharedPeek.JoinPaths) > 0 {
				skipped++
				if !*quiet {
					fmt.Printf("skip %s (already has join_paths)\n", dbID)
				}
				continue
			}
		}

		sqlitePath := filepath.Join(*dbDir, dbID, dbID+".sqlite")
		if _, err := os.Stat(sqlitePath); err != nil {
			alt := filepath.Join(*dbDir, dbID+".sqlite")
			if _, err2 := os.Stat(alt); err2 == nil {
				sqlitePath = alt
			} else {
				log.Printf("skip %s: sqlite not found under %s", dbID, *dbDir)
				fail++
				continue
			}
		}

		shared, err := contextpkg.LoadContextFromFile(jsonPath)
		if err != nil {
			log.Printf("load %s: %v", dbID, err)
			fail++
			continue
		}
		shared.Quiet = *quiet

		dbAdapter, err := adapter.NewAdapter(&adapter.DBConfig{
			Type:     "sqlite",
			FilePath: sqlitePath,
		})
		if err != nil {
			log.Printf("adapter %s: %v", dbID, err)
			fail++
			continue
		}
		if err := dbAdapter.Connect(ctx); err != nil {
			log.Printf("connect %s: %v", dbID, err)
			fail++
			continue
		}

		if err := shared.EnrichDeterministic(ctx, dbAdapter); err != nil && !*quiet {
			log.Printf("enrich warn %s: %v", dbID, err)
		}
		_ = dbAdapter.Close()

		nMeaning := 0
		if len(meaningRaw) > 0 {
			lookup := contextpkg.ParseColumnMeaningForDB(meaningRaw, dbID)
			nMeaning = shared.ApplyOfficialMeanings(lookup)
			shared.RefreshColumnGrounding()
		}

		nInc, nExc, nUnk := 0, 0, 0
		switch labelMode {
		case "heuristic":
			nInc, nExc, nUnk = shared.LabelValueIndexHeuristic()
		case "llm":
			var lerr error
			nInc, nExc, nUnk, lerr = shared.LabelValueIndexWithLLM(ctx, labelLLM)
			if lerr != nil {
				log.Printf("value-index label %s: %v (fallback heuristic)", dbID, lerr)
				nInc, nExc, nUnk = shared.LabelValueIndexHeuristic()
			}
		}

		nVIDocs, nVICols := 0, 0
		if *valueIndex {
			outPath := contextpkg.ValueIndexSidecarPath(*contextDir, dbID)
			rel := filepath.ToSlash(filepath.Join("value_index", dbID+".sqlite"))
			rep, err := shared.BuildValueIndex(ctx, sqlitePath, outPath, rel, contextpkg.DefaultValueIndexOptions())
			if err != nil {
				log.Printf("value-index %s: %v", dbID, err)
				fail++
				continue
			}
			if rep != nil {
				nVIDocs, nVICols = rep.Documents, rep.ColumnsIndexed
			}
		}

		if err := shared.SaveToFile(jsonPath); err != nil {
			log.Printf("save %s: %v", dbID, err)
			fail++
			continue
		}

		nFK, nJoin, nSample, nProfile := countEnrichSignals(shared)
		fmt.Printf("✓ %s  fk_card=%d  join_paths=%d  samples=%d  profile_nl=%d  meaning=%d  label=%s(+%d/-%d/?%d)  value_index=%dcols/%ddocs\n",
			dbID, nFK, nJoin, nSample, nProfile, nMeaning, labelMode, nInc, nExc, nUnk, nVICols, nVIDocs)
		done++
	}

	fmt.Printf("\nDone: %d ok, %d fail, %d skipped, elapsed %s\n",
		done, fail, skipped, time.Since(start).Round(time.Second))
}

func countEnrichSignals(shared *contextpkg.SharedContext) (fkCard, joinPaths, sampleCols, profileCols int) {
	joinPaths = len(shared.JoinPaths)
	for _, t := range shared.Tables {
		for _, fk := range t.ForeignKeys {
			if fk.Cardinality != "" {
				fkCard++
			}
		}
		for _, col := range t.Columns {
			if col.ValueStats != nil && len(col.ValueStats.SampleValues) > 0 {
				sampleCols++
			}
			if strings.TrimSpace(col.ProfileNL) != "" {
				profileCols++
			}
		}
	}
	return
}

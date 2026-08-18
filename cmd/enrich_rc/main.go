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
	"github.com/Zqzqsb/AtlasCore/internal/birddesc"
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
//	  --value-index --value-index-label sampled
func main() {
	contextDir := flag.String("context-dir", "contexts/sqlite/bird_heldout_v1", "Directory of RC JSON files")
	dbDir := flag.String("db-dir", "benchmarks/bird/heldout_v1_smoke/test_databases", "Directory of sqlite DBs (<db>/<db>.sqlite)")
	columnMeaningPath := flag.String("column-meaning", "", "Optional column_meaning.json to bake into OfficialMeaning")
	valueIndex := flag.Bool("value-index", true, "Build per-DB business-value inverted index sidecar under <context-dir>/value_index/")
	phase := flag.String("phase", "all", "Phase: stats | plan | build | all")
	valueIndexLabel := flag.String("value-index-label", "sampled", "Column planning: sampled | sampled+llm | heuristic | llm | existing | off")
	labelModel := flag.String("label-model", "deepseek-v4-flash", "LLM for --value-index-label=llm")
	limit := flag.Int("limit", 0, "Max DBs to enrich (0 = all)")
	dbFilter := flag.String("db", "", "Only enrich this db_id")
	resumeAfter := flag.String("resume-after", "", "Skip DBs with name <= this (lexicographic), e.g. ice_hockey_draft")
	skipEnriched := flag.Bool("skip-enriched", false, "Skip DBs that already have non-empty join_paths")
	quiet := flag.Bool("quiet", false, "Less logging")
	flag.Parse()

	phaseName := strings.ToLower(strings.TrimSpace(*phase))
	switch phaseName {
	case "stats", "plan", "build", "all":
	default:
		log.Fatalf("invalid --phase %q (want stats|plan|build|all)", *phase)
	}
	needStats := phaseName == "stats" || phaseName == "all"
	needPlan := phaseName == "plan" || phaseName == "all"
	needBuild := phaseName == "build" || phaseName == "all"

	labelMode := strings.ToLower(strings.TrimSpace(*valueIndexLabel))
	switch labelMode {
	case "sampled", "sampled+llm", "heuristic", "llm", "existing", "off":
	default:
		log.Fatalf("invalid --value-index-label %q", *valueIndexLabel)
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
	if labelMode == "llm" || labelMode == "sampled+llm" {
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
	var planReport []planSummary

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
		if needStats && *skipEnriched {
			if sharedPeek, err := contextpkg.LoadContextFromFile(jsonPath); err == nil && len(sharedPeek.JoinPaths) > 0 {
				skipped++
				if !*quiet {
					fmt.Printf("skip %s (already has join_paths)\n", dbID)
				}
				continue
			}
		}

		sqlitePath := filepath.Join(*dbDir, dbID, dbID+".sqlite")
		if needStats || needBuild {
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
		}

		shared, err := contextpkg.LoadContextFromFile(jsonPath)
		if err != nil {
			log.Printf("load %s: %v", dbID, err)
			fail++
			continue
		}
		shared.Quiet = *quiet

		if desc, err := birddesc.LoadForDB(*dbDir, dbID); err != nil {
			log.Printf("official desc %s: %v", dbID, err)
		} else if desc != nil {
			shared.SetOfficialDesc(desc)
		}

		if needStats {
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
		}

		nMeaning := 0
		if needStats || needPlan {
			nMeaning = shared.BakeOfficialDesc()
		}
		if (needStats || needPlan) && len(meaningRaw) > 0 {
			lookup := contextpkg.ParseColumnMeaningForDB(meaningRaw, dbID)
			if n := shared.ApplyOfficialMeanings(lookup); n > 0 {
				nMeaning += n
				shared.RefreshColumnGrounding()
			}
		}

		nInc, nExc, nReview := 0, 0, 0
		if needPlan || (needBuild && labelMode != "existing" && labelMode != "off") {
			switch labelMode {
			case "sampled":
				nInc, nExc, nReview = shared.LabelValueIndexSampled()
			case "sampled+llm":
				var lerr error
				nInc, nExc, nReview, lerr = shared.LabelValueIndexSampledWithLLM(ctx, labelLLM)
				if lerr != nil {
					log.Printf("sampled+llm plan %s: %v (keeping sampled review)", dbID, lerr)
					nInc, nExc, nReview = shared.LabelValueIndexSampled()
				}
			case "heuristic":
				nInc, nExc, nReview = shared.LabelValueIndexHeuristic()
			case "llm":
				var lerr error
				nInc, nExc, nReview, lerr = shared.LabelValueIndexWithLLM(ctx, labelLLM)
				if lerr != nil {
					log.Printf("value-index label %s: %v (fallback sampled)", dbID, lerr)
					nInc, nExc, nReview = shared.LabelValueIndexSampled()
				}
			}
		}
		if needBuild && labelMode == "existing" {
			nInc, nExc, nReview = countExistingPlan(shared)
			if nInc+nExc+nReview == 0 {
				log.Printf("value-index %s: no existing plan; run --phase plan first", dbID)
				fail++
				continue
			}
		}
		if needPlan {
			planReport = append(planReport, summarizePlan(dbID, shared, nInc, nExc, nReview))
		}

		nVIDocs, nVICols := 0, 0
		if needBuild && *valueIndex {
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
		fmt.Printf("✓ %s phase=%s  fk_card=%d  join_paths=%d  samples=%d  profile_nl=%d  meaning=%d  plan=%s(+%d/-%d/review%d)  value_index=%dcols/%ddocs\n",
			dbID, phaseName, nFK, nJoin, nSample, nProfile, nMeaning, labelMode, nInc, nExc, nReview, nVICols, nVIDocs)
		done++
	}

	if needPlan {
		if err := savePlanReport(*contextDir, labelMode, planReport); err != nil {
			log.Printf("save plan report: %v", err)
		}
	}
	fmt.Printf("\nDone: %d ok, %d fail, %d skipped, elapsed %s\n",
		done, fail, skipped, time.Since(start).Round(time.Second))
}

type planSummary struct {
	DBID               string `json:"db_id"`
	Include            int    `json:"include"`
	Exclude            int    `json:"exclude"`
	Review             int    `json:"review"`
	EstimatedDocuments int    `json:"estimated_documents"`
}

func summarizePlan(dbID string, shared *contextpkg.SharedContext, include, exclude, review int) planSummary {
	out := planSummary{DBID: dbID, Include: include, Exclude: exclude, Review: review}
	for _, table := range shared.Tables {
		for _, col := range table.Columns {
			if col.ValueIndexPolicy == "include" {
				out.EstimatedDocuments += col.ValueIndexEstimatedDocs
			}
		}
	}
	return out
}

func countExistingPlan(shared *contextpkg.SharedContext) (include, exclude, review int) {
	for _, table := range shared.Tables {
		for _, col := range table.Columns {
			switch col.ValueIndexPolicy {
			case "include":
				include++
			case "exclude":
				exclude++
			case "review", "unknown":
				review++
			}
		}
	}
	return
}

func savePlanReport(contextDir, mode string, rows []planSummary) error {
	dir := filepath.Join(contextDir, "value_index")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	payload := struct {
		Planner   string        `json:"planner"`
		CreatedAt time.Time     `json:"created_at"`
		Databases []planSummary `json:"databases"`
	}{Planner: mode, CreatedAt: time.Now().UTC(), Databases: rows}
	data, err := json.MarshalIndent(payload, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(dir, "plan.json"), append(data, '\n'), 0o644)
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

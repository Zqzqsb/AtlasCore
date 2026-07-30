package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
)

// enrich_rc re-runs deterministic RC enrichment (sample values, FK cardinality,
// join paths) on existing context JSON — no LLM. Use after RC gen upgrades
// without regenerating LLM Phase 2/3.
//
// Example (held-out):
//
//	go run ./cmd/enrich_rc \
//	  --context-dir contexts/sqlite/bird_heldout_v1 \
//	  --db-dir benchmarks/bird/heldout_v1_smoke/test_databases
func main() {
	contextDir := flag.String("context-dir", "contexts/sqlite/bird_heldout_v1", "Directory of RC JSON files")
	dbDir := flag.String("db-dir", "benchmarks/bird/heldout_v1_smoke/test_databases", "Directory of sqlite DBs (<db>/<db>.sqlite)")
	limit := flag.Int("limit", 0, "Max DBs to enrich (0 = all)")
	dbFilter := flag.String("db", "", "Only enrich this db_id")
	quiet := flag.Bool("quiet", false, "Less logging")
	flag.Parse()

	entries, err := os.ReadDir(*contextDir)
	if err != nil {
		log.Fatalf("read context-dir: %v", err)
	}

	ctx := context.Background()
	done, fail := 0, 0
	start := time.Now()

	for _, ent := range entries {
		if ent.IsDir() || !strings.HasSuffix(ent.Name(), ".json") {
			continue
		}
		dbID := strings.TrimSuffix(ent.Name(), ".json")
		if *dbFilter != "" && dbID != *dbFilter {
			continue
		}
		if *limit > 0 && done+fail >= *limit {
			break
		}

		jsonPath := filepath.Join(*contextDir, ent.Name())
		sqlitePath := filepath.Join(*dbDir, dbID, dbID+".sqlite")
		if _, err := os.Stat(sqlitePath); err != nil {
			// try flat layout
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

		if err := shared.SaveToFile(jsonPath); err != nil {
			log.Printf("save %s: %v", dbID, err)
			fail++
			continue
		}

		nFK, nJoin, nSample := countEnrichSignals(shared)
		fmt.Printf("✓ %s  fk_card=%d  join_paths=%d  cols_with_samples=%d\n",
			dbID, nFK, nJoin, nSample)
		done++
	}

	fmt.Printf("\nDone: %d ok, %d fail, elapsed %s\n", done, fail, time.Since(start).Round(time.Second))
}

func countEnrichSignals(shared *contextpkg.SharedContext) (fkCard, joinPaths, sampleCols int) {
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
		}
	}
	return
}

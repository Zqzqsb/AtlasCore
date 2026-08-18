package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"

	"github.com/Zqzqsb/AtlasCore/internal/inference"

	"github.com/tmc/langchaingo/llms"
)

type evalShardStats struct {
	Success      int
	TotalTime    float64
	TotalLLM     int
	TotalTokens  int
	TotalClarify int
}

func splitRanges(n, parts int) [][2]int {
	if n <= 0 || parts <= 0 {
		return nil
	}
	if parts > n {
		parts = n
	}
	base, rem := n/parts, n%parts
	out := make([][2]int, 0, parts)
	start := 0
	for i := 0; i < parts; i++ {
		sz := base
		if i < rem {
			sz++
		}
		if sz == 0 {
			continue
		}
		out = append(out, [2]int{start, start + sz})
		start += sz
	}
	return out
}

func runParallelEval(
	ctx context.Context,
	examples []interface{},
	outputDir string,
	benchmark, dbDir, contextDir, logMode, groundingMode, modeName string,
	mode EvalMode,
	llmModel llms.Model,
	columnMeaning inference.ColumnMeaningStore,
	stripGoldFields bool,
	workers int,
) evalShardStats {
	ranges := splitRanges(len(examples), workers)
	if len(ranges) == 0 {
		return evalShardStats{}
	}
	fmt.Printf("🔀 parallel=%d shards=%d questions=%d\n", workers, len(ranges), len(examples))

	type shardResult struct {
		dir   string
		stats evalShardStats
		err   error
	}
	results := make([]shardResult, len(ranges))
	var wg sync.WaitGroup
	for i, rg := range ranges {
		wg.Add(1)
		go func(idx, lo, hi int) {
			defer wg.Done()
			dir := filepath.Join(outputDir, fmt.Sprintf("p%d", idx))
			st, err := runEvalShard(ctx, examples[lo:hi], lo, len(examples), dir,
				benchmark, dbDir, contextDir, logMode, groundingMode, modeName,
				mode, llmModel, columnMeaning, stripGoldFields)
			results[idx] = shardResult{dir: dir, stats: st, err: err}
		}(i, rg[0], rg[1])
	}
	wg.Wait()

	var dirs []string
	var agg evalShardStats
	for i, r := range results {
		if r.err != nil {
			log.Fatalf("shard p%d: %v", i, r.err)
		}
		dirs = append(dirs, r.dir)
		agg.Success += r.stats.Success
		agg.TotalTime += r.stats.TotalTime
		agg.TotalLLM += r.stats.TotalLLM
		agg.TotalTokens += r.stats.TotalTokens
		agg.TotalClarify += r.stats.TotalClarify
	}
	if err := mergeShardOutputs(dirs, outputDir); err != nil {
		log.Fatalf("merge shards: %v", err)
	}
	return agg
}

func runEvalShard(
	ctx context.Context,
	examples []interface{},
	indexBase, totalCount int,
	outputDir string,
	benchmark, dbDir, contextDir, logMode, groundingMode, modeName string,
	mode EvalMode,
	llmModel llms.Model,
	columnMeaning inference.ColumnMeaningStore,
	stripGoldFields bool,
) (evalShardStats, error) {
	var st evalShardStats
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return st, err
	}
	logsDir := filepath.Join(outputDir, "logs")
	if err := os.MkdirAll(logsDir, 0755); err != nil {
		return st, err
	}
	sqlFile, err := os.Create(filepath.Join(outputDir, "predict.sql"))
	if err != nil {
		return st, err
	}
	defer sqlFile.Close()
	jsonFile, err := os.Create(filepath.Join(outputDir, "results.json"))
	if err != nil {
		return st, err
	}
	defer jsonFile.Close()
	infFile, err := os.Create(filepath.Join(outputDir, "inference.log"))
	if err != nil {
		return st, err
	}
	defer infFile.Close()

	jsonFile.WriteString("[\n")
	evalLogger := inference.NewInferenceLogger()

	for i, example := range examples {
		globalI := indexBase + i
		result := evalOneExample(ctx, example, globalI, totalCount, benchmark, dbDir, contextDir,
			logMode, groundingMode, modeName, mode, llmModel, columnMeaning, stripGoldFields,
			logsDir, evalLogger)

		if result.Status == "success" {
			st.Success++
		}
		st.TotalTime += result.TimeSeconds
		st.TotalLLM += result.LLMCalls
		st.TotalTokens += result.TotalTokens
		st.TotalClarify += result.ClarifyCount

		if i > 0 {
			jsonFile.WriteString(",\n")
		}
		jsonData, mErr := json.MarshalIndent(result, "  ", "  ")
		if mErr != nil {
			log.Printf("shard marshal: %v", mErr)
		} else {
			jsonFile.WriteString("  " + string(jsonData))
		}
		writePredictLine(sqlFile, result)
		fmt.Fprintf(infFile, "[%04d] %s | Q: %s\n", globalI+1, result.DbID, result.Question)
		fmt.Fprintf(infFile, "       Pred: %s\n\n", result.GeneratedSQL)
		sqlFile.Sync()
		jsonFile.Sync()
		runtime.GC()
	}
	jsonFile.WriteString("\n]\n")
	return st, nil
}

func evalOneExample(
	ctx context.Context,
	example interface{},
	globalI, totalCount int,
	benchmark, dbDir, contextDir, logMode, groundingMode, modeName string,
	mode EvalMode,
	llmModel llms.Model,
	columnMeaning inference.ColumnMeaningStore,
	stripGoldFields bool,
	logsDir string,
	evalLogger *inference.InferenceLogger,
) EvalResult {
	var exampleDbID, exampleQuestion, exampleGoldSQL, exampleEvidence string
	switch e := example.(type) {
	case SpiderExample:
		exampleDbID, exampleQuestion, exampleGoldSQL = e.DbID, e.Question, e.Query
	case BirdExample:
		exampleDbID, exampleQuestion, exampleGoldSQL, exampleEvidence = e.DbID, e.Question, e.SQL, e.Evidence
	}

	logFileName := fmt.Sprintf("%04d_%s.log", globalI+1, exampleDbID)
	logFilePath := filepath.Join(logsDir, logFileName)
	logFile, logErr := os.Create(logFilePath)
	if logErr != nil {
		log.Printf("Warning: Failed to create log file %s: %v", logFilePath, logErr)
	} else {
		evalLogger.SetFile(logFile)
		evalLogger.FileOnly("========================================\n")
		evalLogger.FileOnly("Example: %04d\n", globalI+1)
		evalLogger.FileOnly("DB: %s\n", exampleDbID)
		evalLogger.FileOnly("Question: %s\n", exampleQuestion)
		evalLogger.FileOnly("Gold SQL: %s\n", exampleGoldSQL)
		if exampleEvidence != "" {
			evalLogger.FileOnly("Evidence: %s\n", exampleEvidence)
		}
		evalLogger.FileOnly("Mode: %s\n", modeName)
		evalLogger.FileOnly("========================================\n\n")
	}

	var result EvalResult
	switch e := example.(type) {
	case SpiderExample:
		fmt.Printf("[%d/%d] DB: %s\n", globalI+1, totalCount, e.DbID)
		result = evaluateSpider(ctx, llmModel, e, dbDir, contextDir, mode, logMode, evalLogger, groundingMode)
	case BirdExample:
		fmt.Printf("[%d/%d] DB: %s\n", globalI+1, totalCount, e.DbID)
		result = evaluateBird(ctx, llmModel, e, dbDir, contextDir, mode, logMode, evalLogger, columnMeaning, groundingMode, stripGoldFields)
	}

	if logFile != nil {
		evalLogger.FileOnly("\n[Result]\n")
		evalLogger.FileOnly("  Generated SQL: %s\n", result.GeneratedSQL)
		evalLogger.FileOnly("  Status: %s\n", result.Status)
		evalLogger.CloseFile()
	}
	return result
}

func writePredictLine(sqlFile *os.File, result EvalResult) {
	sql := result.GeneratedSQL
	if sql == "" {
		sql = "SELECT 1"
	}
	sql = strings.TrimSpace(sql)
	sql = strings.TrimSuffix(sql, ";")
	sql = strings.ReplaceAll(sql, "\n", " ")
	sql = strings.ReplaceAll(sql, "\r", " ")
	sql = strings.Join(strings.Fields(sql), " ")
	fmt.Fprintf(sqlFile, "%s\t%s\n", sql, result.DbID)
}

func mergeShardOutputs(shardDirs []string, dest string) error {
	if err := os.MkdirAll(filepath.Join(dest, "logs"), 0755); err != nil {
		return err
	}
	pred, err := os.Create(filepath.Join(dest, "predict.sql"))
	if err != nil {
		return err
	}
	defer pred.Close()
	inf, err := os.Create(filepath.Join(dest, "inference.log"))
	if err != nil {
		return err
	}
	defer inf.Close()

	var merged []json.RawMessage
	for _, dir := range shardDirs {
		pf, err := os.Open(filepath.Join(dir, "predict.sql"))
		if err != nil {
			return err
		}
		_, err = io.Copy(pred, pf)
		_ = pf.Close()
		if err != nil {
			return err
		}
		if b, err := os.ReadFile(filepath.Join(dir, "inference.log")); err == nil {
			_, _ = inf.Write(b)
		}
		raw, err := os.ReadFile(filepath.Join(dir, "results.json"))
		if err != nil {
			return err
		}
		var part []json.RawMessage
		if err := json.Unmarshal(raw, &part); err != nil {
			return fmt.Errorf("results.json in %s: %w", dir, err)
		}
		merged = append(merged, part...)

		logDir := filepath.Join(dir, "logs")
		ents, _ := os.ReadDir(logDir)
		for _, e := range ents {
			if e.IsDir() {
				continue
			}
			src := filepath.Join(logDir, e.Name())
			dst := filepath.Join(dest, "logs", e.Name())
			if err := copyFile(src, dst); err != nil {
				return err
			}
		}
	}
	out, err := json.MarshalIndent(merged, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(dest, "results.json"), append(out, '\n'), 0644)
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	return err
}

func printEvalSummary(benchmark, modeName, modelName, outputDir string, totalCount int, st evalShardStats) {
	fmt.Println()
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	fmt.Println("📊 Evaluation Summary")
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	fmt.Printf("Benchmark: %s | Mode: %s | Model: %s\n", benchmark, modeName, modelName)
	fmt.Printf("Total: %d\n", totalCount)
	if totalCount > 0 {
		fmt.Printf("Success: %d (%.1f%%)\n", st.Success, float64(st.Success)/float64(totalCount)*100)
		fmt.Printf("Failed: %d\n", totalCount-st.Success)
		fmt.Printf("Avg Time: %.2fs\n", st.TotalTime/float64(totalCount))
		fmt.Printf("Avg LLM Calls: %.1f\n", float64(st.TotalLLM)/float64(totalCount))
		fmt.Printf("Total Tokens: %d (Avg: %d per query)\n", st.TotalTokens, st.TotalTokens/totalCount)
	}
	absOutputDir, _ := filepath.Abs(outputDir)
	fmt.Printf("\n✅ Results saved to: %s/\n", outputDir)
	fmt.Printf("  - results.json\n  - predict.sql\n  - logs/\n  - p*/ (per-shard working dirs)\n")
	fmt.Printf("  cd %s\n", absOutputDir)
}

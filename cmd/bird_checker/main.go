package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"reactsql/internal/adapter"
	"reactsql/internal/llm"

	langllm "github.com/tmc/langchaingo/llms"
)

// ─────────────────────────────────────────────────────
// Data structures
// ─────────────────────────────────────────────────────

// ErrorCase represents one error case from the analysis results
type ErrorCase struct {
	ID         int        `json:"id"`
	DBID       string     `json:"db_id"`
	Question   string     `json:"question"`
	Difficulty string     `json:"difficulty"`
	GTSQL      string     `json:"gt_sql"`
	PredSQL    string     `json:"pred_sql"`
	GTResult   ExecResult `json:"gt_result"`
	PredResult ExecResult `json:"pred_result"`
	ErrorType  string     `json:"error_type"`  // row_count / data_mismatch / execution / timeout
	ErrorReason string   `json:"error_reason"`
}

type ExecResult struct {
	Success bool       `json:"Success"`
	Error   string     `json:"Error"`
	Rows    [][]string `json:"Rows"`
}

// BirdEntry represents one entry in dev.json
type BirdEntry struct {
	QuestionID int    `json:"question_id"`
	DBID       string `json:"db_id"`
	Question   string `json:"question"`
	Evidence   string `json:"evidence"`
	SQL        string `json:"SQL"`
	Difficulty string `json:"difficulty"`
}

// SuspiciousCase represents a case flagged as suspicious
type SuspiciousCase struct {
	ID              int    `json:"id"`
	DBID            string `json:"db_id"`
	Question        string `json:"question"`
	Evidence        string `json:"evidence"`
	Difficulty      string `json:"difficulty"`
	GoldSQL         string `json:"gold_sql"`
	PredSQL         string `json:"pred_sql"`
	GoldResultBrief string `json:"gold_result_brief"`
	PredResultBrief string `json:"pred_result_brief"`
	ErrorType       string `json:"error_type"`
	SuspicionType   string `json:"suspicion_type"`
	SuspicionReason string `json:"suspicion_reason"`
	Phase           string `json:"phase"` // "rule" or "llm"
	LLMVerdict      string `json:"llm_verdict,omitempty"`     // GOLD_CORRECT / GOLD_SUSPICIOUS / PRED_BETTER
	LLMExplanation  string `json:"llm_explanation,omitempty"` // LLM's reasoning
}

// ─────────────────────────────────────────────────────
// Phase 1: Rule-based scanning
// ─────────────────────────────────────────────────────

var (
	reLimitN   = regexp.MustCompile(`(?i)ORDER\s+BY\s+.+LIMIT\s+(\d+)`)
	reASC      = regexp.MustCompile(`(?i)ORDER\s+BY\s+\S+\s+ASC`)
	reDESC     = regexp.MustCompile(`(?i)ORDER\s+BY\s+\S+\s+DESC`)
	reHighest  = regexp.MustCompile(`(?i)\b(highest|most|greatest|maximum|max|best|largest|top|biggest)\b`)
	reLowest   = regexp.MustCompile(`(?i)\b(lowest|least|minimum|min|worst|smallest|bottom|fewest)\b`)
	reCurrTime = regexp.MustCompile(`(?i)\bCURRENT_(TIMESTAMP|DATE|TIME)\b`)
)

func checkSortDirection(ec ErrorCase, evidence string) *SuspiciousCase {
	goldSQL := strings.ToUpper(ec.GTSQL)
	question := ec.Question

	// Check if gold uses ASC but question asks for highest/most
	goldHasASC := reASC.MatchString(ec.GTSQL) && !reDESC.MatchString(ec.GTSQL)
	goldHasDESC := reDESC.MatchString(ec.GTSQL) && !reASC.MatchString(ec.GTSQL)
	qAsksHighest := reHighest.MatchString(question)
	qAsksLowest := reLowest.MatchString(question)

	// Also check evidence for direction hints
	if evidence != "" {
		if reHighest.MatchString(evidence) {
			qAsksHighest = true
		}
		if reLowest.MatchString(evidence) {
			qAsksLowest = true
		}
	}

	_ = goldSQL

	if goldHasASC && qAsksHighest && !qAsksLowest {
		return &SuspiciousCase{
			SuspicionType:   "sort_direction_error",
			SuspicionReason: fmt.Sprintf("Question asks for highest/most/best but gold SQL uses ORDER BY ASC (ascending). Likely should be DESC."),
			Phase:           "rule",
		}
	}

	if goldHasDESC && qAsksLowest && !qAsksHighest {
		return &SuspiciousCase{
			SuspicionType:   "sort_direction_error",
			SuspicionReason: fmt.Sprintf("Question asks for lowest/least/worst but gold SQL uses ORDER BY DESC (descending). Likely should be ASC."),
			Phase:           "rule",
		}
	}

	return nil
}

func checkCurrentTimestamp(ec ErrorCase) *SuspiciousCase {
	if reCurrTime.MatchString(ec.GTSQL) {
		return &SuspiciousCase{
			SuspicionType:   "current_timestamp_dependency",
			SuspicionReason: "Gold SQL uses CURRENT_TIMESTAMP/CURRENT_DATE/CURRENT_TIME which produces non-deterministic results.",
			Phase:           "rule",
		}
	}
	return nil
}

func checkTieHandling(ec ErrorCase, dbDir string) *SuspiciousCase {
	if !reLimitN.MatchString(ec.GTSQL) {
		return nil
	}

	// Only check LIMIT 1 cases for tie handling
	matches := reLimitN.FindStringSubmatch(ec.GTSQL)
	if len(matches) < 2 || matches[1] != "1" {
		return nil
	}

	// Only relevant for row_count errors where pred has MORE rows
	if ec.ErrorType != "row_count" {
		return nil
	}

	predRows := len(ec.PredResult.Rows)
	goldRows := len(ec.GTResult.Rows)
	if predRows <= goldRows {
		return nil // Pred has fewer/same rows, not a tie issue
	}

	// Check if pred SQL uses a subquery pattern (WHERE = (SELECT MAX/MIN ...))
	// which would be the correct tie-handling approach
	predUpper := strings.ToUpper(ec.PredSQL)
	if strings.Contains(predUpper, "SELECT MAX") || strings.Contains(predUpper, "SELECT MIN") {
		// Pred uses subquery approach, could be handling ties correctly
		return &SuspiciousCase{
			SuspicionType:   "tie_handling",
			SuspicionReason: fmt.Sprintf("Gold uses ORDER BY...LIMIT 1 (returns 1 row), pred uses subquery approach (returns %d rows). Pred may correctly handle ties.", predRows-1),
			Phase:           "rule",
		}
	}

	return nil
}

func checkCastTrimIssue(ec ErrorCase) *SuspiciousCase {
	if ec.ErrorType != "data_mismatch" {
		return nil
	}

	// Check if results differ only by CAST/type
	if !ec.GTResult.Success || !ec.PredResult.Success {
		return nil
	}
	if len(ec.GTResult.Rows) != len(ec.PredResult.Rows) {
		return nil
	}
	if len(ec.GTResult.Rows) < 2 {
		return nil
	}

	// Check for numeric precision differences
	goldUpper := strings.ToUpper(ec.GTSQL)
	predUpper := strings.ToUpper(ec.PredSQL)

	castInPred := strings.Contains(predUpper, "CAST(") && !strings.Contains(goldUpper, "CAST(")
	castInGold := strings.Contains(goldUpper, "CAST(") && !strings.Contains(predUpper, "CAST(")

	if castInPred || castInGold {
		return &SuspiciousCase{
			SuspicionType:   "cast_difference",
			SuspicionReason: fmt.Sprintf("Gold and pred differ in CAST usage. gold_has_CAST=%v, pred_has_CAST=%v. May cause data type mismatch.", castInGold, castInPred),
			Phase:           "rule",
		}
	}

	// Check for TRIM differences
	trimInPred := strings.Contains(predUpper, "TRIM(") && !strings.Contains(goldUpper, "TRIM(")
	trimInGold := strings.Contains(goldUpper, "TRIM(") && !strings.Contains(predUpper, "TRIM(")

	if trimInPred || trimInGold {
		return &SuspiciousCase{
			SuspicionType:   "trim_difference",
			SuspicionReason: fmt.Sprintf("Gold and pred differ in TRIM usage. gold_has_TRIM=%v, pred_has_TRIM=%v.", trimInGold, trimInPred),
			Phase:           "rule",
		}
	}

	return nil
}

func checkGoldSQLSyntaxSuspicion(ec ErrorCase) *SuspiciousCase {
	// Intentionally conservative — complex syntax checks are deferred to LLM Phase 2.
	// Only flag clearly wrong patterns here.
	return nil
}

// ─────────────────────────────────────────────────────
// Phase 2: LLM classification
// ─────────────────────────────────────────────────────

const llmPromptTemplate = `You are an expert SQL evaluator for the BIRD text-to-SQL benchmark. Your task is to determine whether the Gold (reference) SQL or the Predicted SQL is more correct for the given question.

## Question
%s

## Evidence (hint from benchmark)
%s

## Database
%s

## Gold SQL
%s

## Gold Result (%d data rows)
%s

## Predicted SQL
%s

## Predicted Result (%d data rows)
%s

## Error Classification
%s

## Task
Analyze both SQL queries and their results. Determine which one better answers the question. Consider:
1. Does the Gold SQL correctly interpret the question's intent?
2. Does the Predicted SQL provide a more accurate answer?
3. Are there any issues with the Gold SQL (wrong sort direction, missing tie handling, wrong column, wrong filter, etc.)?
4. Could the Gold SQL itself be incorrect?

Respond in EXACTLY this JSON format (no markdown, no extra text):
{"verdict": "GOLD_CORRECT|GOLD_SUSPICIOUS|PRED_BETTER", "explanation": "brief explanation in English"}`

func buildLLMPrompt(ec ErrorCase, evidence string) string {
	goldRowCount := 0
	predRowCount := 0
	goldBrief := "Execution failed"
	predBrief := "Execution failed"

	if ec.GTResult.Success && len(ec.GTResult.Rows) > 0 {
		goldRowCount = len(ec.GTResult.Rows) - 1
		goldBrief = formatResultBrief(ec.GTResult.Rows, 5)
	}
	if ec.PredResult.Success && len(ec.PredResult.Rows) > 0 {
		predRowCount = len(ec.PredResult.Rows) - 1
		predBrief = formatResultBrief(ec.PredResult.Rows, 5)
	}

	return fmt.Sprintf(llmPromptTemplate,
		ec.Question,
		evidence,
		ec.DBID,
		ec.GTSQL,
		goldRowCount, goldBrief,
		ec.PredSQL,
		predRowCount, predBrief,
		ec.ErrorReason,
	)
}

func formatResultBrief(rows [][]string, maxRows int) string {
	if len(rows) == 0 {
		return "(empty)"
	}

	var sb strings.Builder
	// Header
	sb.WriteString("| " + strings.Join(rows[0], " | ") + " |\n")

	// Data rows (max N)
	shown := 0
	for i := 1; i < len(rows) && shown < maxRows; i++ {
		sb.WriteString("| " + strings.Join(rows[i], " | ") + " |\n")
		shown++
	}
	if len(rows)-1 > maxRows {
		sb.WriteString(fmt.Sprintf("... and %d more rows\n", len(rows)-1-maxRows))
	}

	return sb.String()
}

// ─────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────

func loadErrorCases(resultsDir string) ([]ErrorCase, error) {
	var cases []ErrorCase

	errorDirs := []struct {
		dir       string
		errorType string
	}{
		{"incorrect_row_count", "row_count"},
		{"incorrect_data_mismatch", "data_mismatch"},
		{"incorrect_execution", "execution"},
		{"incorrect_timeout", "timeout"},
	}

	for _, ed := range errorDirs {
		dirPath := filepath.Join(resultsDir, ed.dir)
		entries, err := os.ReadDir(dirPath)
		if err != nil {
			continue
		}

		for _, entry := range entries {
			if !strings.HasSuffix(entry.Name(), ".json") {
				continue
			}

			data, err := os.ReadFile(filepath.Join(dirPath, entry.Name()))
			if err != nil {
				continue
			}

			var raw map[string]interface{}
			if err := json.Unmarshal(data, &raw); err != nil {
				continue
			}

			ec := ErrorCase{
				ErrorType: ed.errorType,
			}

			if v, ok := raw["id"].(float64); ok {
				ec.ID = int(v)
			}
			if v, ok := raw["db_id"].(string); ok {
				ec.DBID = v
			}
			if v, ok := raw["question"].(string); ok {
				ec.Question = v
			}
			if v, ok := raw["difficulty"].(string); ok {
				ec.Difficulty = v
			}
			if v, ok := raw["gt_sql"].(string); ok {
				ec.GTSQL = v
			}
			if v, ok := raw["pred_sql"].(string); ok {
				ec.PredSQL = v
			}
			if v, ok := raw["error_reason"].(string); ok {
				ec.ErrorReason = v
			}

			// Parse gt_result
			if gtRes, ok := raw["gt_result"].(map[string]interface{}); ok {
				ec.GTResult = parseExecResult(gtRes)
			}
			// Parse pred_result
			if predRes, ok := raw["pred_result"].(map[string]interface{}); ok {
				ec.PredResult = parseExecResult(predRes)
			}

			cases = append(cases, ec)
		}
	}

	sort.Slice(cases, func(i, j int) bool { return cases[i].ID < cases[j].ID })
	return cases, nil
}

func parseExecResult(m map[string]interface{}) ExecResult {
	er := ExecResult{}
	if v, ok := m["Success"].(bool); ok {
		er.Success = v
	}
	if v, ok := m["Error"].(string); ok {
		er.Error = v
	}
	if rows, ok := m["Rows"].([]interface{}); ok {
		for _, row := range rows {
			if arr, ok := row.([]interface{}); ok {
				var strRow []string
				for _, cell := range arr {
					strRow = append(strRow, fmt.Sprintf("%v", cell))
				}
				er.Rows = append(er.Rows, strRow)
			}
		}
	}
	return er
}

func loadBirdDev(devPath string) (map[int]BirdEntry, error) {
	data, err := os.ReadFile(devPath)
	if err != nil {
		return nil, err
	}

	var entries []BirdEntry
	if err := json.Unmarshal(data, &entries); err != nil {
		return nil, err
	}

	m := make(map[int]BirdEntry, len(entries))
	for _, e := range entries {
		m[e.QuestionID] = e
	}
	return m, nil
}

func briefResult(rows [][]string, maxRows int) string {
	if len(rows) == 0 {
		return "(empty)"
	}
	return formatResultBrief(rows, maxRows)
}

// ─────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────

func main() {
	resultsDir := flag.String("results", "", "Path to results directory (e.g., results/bird/20260301_180516_react+rich_context+clarify)")
	devPath := flag.String("dev", "benchmarks/bird/dev/dev.json", "Path to BIRD dev.json")
	dbDir := flag.String("db-dir", "benchmarks/bird/dev/dev_databases", "Path to BIRD databases")
	outputPath := flag.String("output", "", "Output file path (default: <results>/suspicious_cases.json)")
	skipLLM := flag.Bool("skip-llm", false, "Skip Phase 2 (LLM classification)")
	llmConcurrency := flag.Int("llm-concurrency", 5, "Max concurrent LLM calls")
	flag.Parse()

	if *resultsDir == "" {
		// Auto-discover latest bird results
		entries, err := os.ReadDir("results/bird")
		if err != nil {
			fmt.Println("❌ No results/bird directory found. Use --results flag.")
			os.Exit(1)
		}
		latest := ""
		for _, e := range entries {
			if e.IsDir() && e.Name() > latest {
				latest = e.Name()
			}
		}
		if latest == "" {
			fmt.Println("❌ No result directories found under results/bird/")
			os.Exit(1)
		}
		dir := filepath.Join("results", "bird", latest)
		resultsDir = &dir
		fmt.Printf("📂 Auto-selected: %s\n", *resultsDir)
	}

	if *outputPath == "" {
		out := filepath.Join(*resultsDir, "suspicious_cases.json")
		outputPath = &out
	}

	// ── Load data ──
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	fmt.Println("🔍 BIRD Gold SQL Checker")
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	fmt.Printf("Loading error cases from: %s\n", *resultsDir)
	errorCases, err := loadErrorCases(*resultsDir)
	if err != nil {
		fmt.Printf("❌ Failed to load error cases: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("✅ Loaded %d error cases\n", len(errorCases))

	fmt.Printf("Loading BIRD dev.json from: %s\n", *devPath)
	birdEntries, err := loadBirdDev(*devPath)
	if err != nil {
		fmt.Printf("❌ Failed to load dev.json: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("✅ Loaded %d BIRD entries\n", len(birdEntries))

	_ = dbDir // Reserved for future tie-checking with actual DB execution

	// ── Phase 1: Rule-based scanning ──
	fmt.Println("\n━━━ Phase 1: Rule-based scanning ━━━")

	var ruleSuspicious []*SuspiciousCase
	var phase2Candidates []ErrorCase // Cases to send to LLM

	ruleStats := make(map[string]int)

	for _, ec := range errorCases {
		evidence := ""
		if be, ok := birdEntries[ec.ID]; ok {
			evidence = be.Evidence
		}

		var found *SuspiciousCase

		// Run all rule checks
		checks := []*SuspiciousCase{
			checkSortDirection(ec, evidence),
			checkCurrentTimestamp(ec),
			checkTieHandling(ec, *dbDir),
			checkCastTrimIssue(ec),
			checkGoldSQLSyntaxSuspicion(ec),
		}

		for _, c := range checks {
			if c != nil {
				found = c
				break // Take first match
			}
		}

		if found != nil {
			found.ID = ec.ID
			found.DBID = ec.DBID
			found.Question = ec.Question
			found.Evidence = evidence
			found.Difficulty = ec.Difficulty
			found.GoldSQL = ec.GTSQL
			found.PredSQL = ec.PredSQL
			found.GoldResultBrief = briefResult(ec.GTResult.Rows, 3)
			found.PredResultBrief = briefResult(ec.PredResult.Rows, 3)
			found.ErrorType = ec.ErrorType
			ruleSuspicious = append(ruleSuspicious, found)
			ruleStats[found.SuspicionType]++
		} else {
			// Send to Phase 2
			phase2Candidates = append(phase2Candidates, ec)
		}
	}

	fmt.Printf("\n📊 Phase 1 Results:\n")
	fmt.Printf("  Rule-flagged:     %d cases\n", len(ruleSuspicious))
	for typ, count := range ruleStats {
		fmt.Printf("    %-25s %d\n", typ, count)
	}
	fmt.Printf("  Remaining for LLM: %d cases\n", len(phase2Candidates))

	// ── Phase 2: LLM classification ──
	var llmSuspicious []*SuspiciousCase

	if !*skipLLM && len(phase2Candidates) > 0 {
		fmt.Println("\n━━━ Phase 2: LLM classification ━━━")

		model, err := llm.CreateLLMByType(llm.ModelDeepSeekV32)
		if err != nil {
			fmt.Printf("❌ Failed to create LLM: %v\n", err)
			fmt.Println("Skipping Phase 2.")
		} else {
			fmt.Printf("Using model: %s\n", llm.GetModelDisplayName(llm.ModelDeepSeekV32))
			fmt.Printf("Concurrency: %d\n", *llmConcurrency)
			fmt.Printf("Processing %d cases...\n\n", len(phase2Candidates))

			llmSuspicious = runLLMClassification(model, phase2Candidates, birdEntries, *llmConcurrency)
		}
	} else if *skipLLM {
		fmt.Println("\n⏭️  Phase 2 skipped (--skip-llm)")
	}

	// ── Combine and save results ──
	allSuspicious := append(ruleSuspicious, llmSuspicious...)
	sort.Slice(allSuspicious, func(i, j int) bool {
		return allSuspicious[i].ID < allSuspicious[j].ID
	})

	// Save
	output, err := json.MarshalIndent(allSuspicious, "", "  ")
	if err != nil {
		fmt.Printf("❌ Failed to serialize results: %v\n", err)
		os.Exit(1)
	}

	if err := os.WriteFile(*outputPath, output, 0644); err != nil {
		fmt.Printf("❌ Failed to write output: %v\n", err)
		os.Exit(1)
	}

	// ── Summary ──
	fmt.Println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	fmt.Println("📊 Final Summary")
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	fmt.Printf("  Total error cases:       %d\n", len(errorCases))
	fmt.Printf("  Rule-flagged:            %d\n", len(ruleSuspicious))
	fmt.Printf("  LLM-flagged suspicious:  %d\n", len(llmSuspicious))
	fmt.Printf("  Total suspicious:        %d\n", len(allSuspicious))
	fmt.Printf("  Output saved to: %s\n", *outputPath)

	// Print suspicion type breakdown
	typeBreakdown := make(map[string]int)
	verdictBreakdown := make(map[string]int)
	for _, s := range allSuspicious {
		typeBreakdown[s.SuspicionType]++
		if s.LLMVerdict != "" {
			verdictBreakdown[s.LLMVerdict]++
		}
	}
	fmt.Println("\n  By suspicion type:")
	for typ, count := range typeBreakdown {
		fmt.Printf("    %-30s %d\n", typ, count)
	}
	if len(verdictBreakdown) > 0 {
		fmt.Println("\n  LLM verdicts:")
		for verdict, count := range verdictBreakdown {
			fmt.Printf("    %-30s %d\n", verdict, count)
		}
	}
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
}

// runLLMClassification runs LLM on all phase2 candidates concurrently
func runLLMClassification(model langllm.Model, candidates []ErrorCase, birdEntries map[int]BirdEntry, concurrency int) []*SuspiciousCase {
	var mu sync.Mutex
	var suspicious []*SuspiciousCase
	var processed int64
	total := int64(len(candidates))

	sem := make(chan struct{}, concurrency)
	var wg sync.WaitGroup

	startTime := time.Now()

	for _, ec := range candidates {
		wg.Add(1)
		sem <- struct{}{}

		go func(ec ErrorCase) {
			defer wg.Done()
			defer func() { <-sem }()

			evidence := ""
			if be, ok := birdEntries[ec.ID]; ok {
				evidence = be.Evidence
			}

			prompt := buildLLMPrompt(ec, evidence)

			ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
			defer cancel()

			resp, err := model.GenerateContent(ctx, []langllm.MessageContent{
				{
					Parts: []langllm.ContentPart{langllm.TextContent{Text: prompt}},
					Role:  langllm.ChatMessageTypeHuman,
				},
			},
				langllm.WithTemperature(0.0),
				langllm.WithMaxTokens(500),
			)

			done := atomic.AddInt64(&processed, 1)

			if err != nil {
				if done%10 == 0 {
					fmt.Printf("  ⏳ %d/%d (%.0f%%) — LLM error for id=%d: %v\n",
						done, total, float64(done)/float64(total)*100, ec.ID, err)
				}
				return
			}

			if len(resp.Choices) == 0 {
				return
			}

			text := resp.Choices[0].Content

			// Parse JSON response
			verdict, explanation := parseLLMResponse(text)

			if done%20 == 0 {
				elapsed := time.Since(startTime)
				rate := float64(done) / elapsed.Seconds()
				eta := time.Duration(float64(total-done)/rate) * time.Second
				fmt.Printf("  ⏳ %d/%d (%.0f%%) — %.1f/s, ETA: %s\n",
					done, total, float64(done)/float64(total)*100, rate, eta.Round(time.Second))
			}

			if verdict == "GOLD_SUSPICIOUS" || verdict == "PRED_BETTER" {
				sc := &SuspiciousCase{
					ID:              ec.ID,
					DBID:            ec.DBID,
					Question:        ec.Question,
					Evidence:        evidence,
					Difficulty:      ec.Difficulty,
					GoldSQL:         ec.GTSQL,
					PredSQL:         ec.PredSQL,
					GoldResultBrief: briefResult(ec.GTResult.Rows, 3),
					PredResultBrief: briefResult(ec.PredResult.Rows, 3),
					ErrorType:       ec.ErrorType,
					SuspicionType:   "llm_flagged",
					SuspicionReason: explanation,
					Phase:           "llm",
					LLMVerdict:      verdict,
					LLMExplanation:  explanation,
				}

				mu.Lock()
				suspicious = append(suspicious, sc)
				mu.Unlock()
			}
		}(ec)
	}

	wg.Wait()

	elapsed := time.Since(startTime)
	fmt.Printf("\n✅ LLM classification done: %d/%d processed in %s\n", processed, total, elapsed.Round(time.Second))
	fmt.Printf("   Flagged as suspicious: %d\n", len(suspicious))

	return suspicious
}

func parseLLMResponse(text string) (verdict, explanation string) {
	// Try to parse JSON from response
	text = strings.TrimSpace(text)

	// Remove markdown code blocks if present
	text = strings.TrimPrefix(text, "```json")
	text = strings.TrimPrefix(text, "```")
	text = strings.TrimSuffix(text, "```")
	text = strings.TrimSpace(text)

	var result struct {
		Verdict     string `json:"verdict"`
		Explanation string `json:"explanation"`
	}

	if err := json.Unmarshal([]byte(text), &result); err == nil {
		return result.Verdict, result.Explanation
	}

	// Fallback: try to find JSON in the text
	start := strings.Index(text, "{")
	end := strings.LastIndex(text, "}")
	if start >= 0 && end > start {
		jsonStr := text[start : end+1]
		if err := json.Unmarshal([]byte(jsonStr), &result); err == nil {
			return result.Verdict, result.Explanation
		}
	}

	// Last resort: look for keywords
	textUpper := strings.ToUpper(text)
	if strings.Contains(textUpper, "PRED_BETTER") {
		return "PRED_BETTER", text
	}
	if strings.Contains(textUpper, "GOLD_SUSPICIOUS") {
		return "GOLD_SUSPICIOUS", text
	}
	return "GOLD_CORRECT", text
}

// Ensure adapter is imported (for future tie-checking)
var _ = adapter.DBConfig{}

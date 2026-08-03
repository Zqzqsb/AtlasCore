package inference

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"

	"github.com/tmc/langchaingo/agents"
	"github.com/tmc/langchaingo/tools"
)

// oneShotGeneration one-shot SQL generation
func (p *Pipeline) oneShotGeneration(ctx context.Context, query string, contextPrompt string, crossTableSummary string) (string, error) {
	prompt := p.buildPrompt(query, contextPrompt, crossTableSummary, false)

	p.Logger.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	p.Logger.Println(" SQL Generation (One-shot) - Prompt to LLM:")
	p.Logger.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	p.Logger.Println(prompt)
	p.Logger.Println()

	// Call LLM with backoff retry
	var response string
	var err error
	maxRetries := 2
	backoffDelays := []time.Duration{1 * time.Second, 3 * time.Second}

	for attempt := 0; attempt <= maxRetries; attempt++ {
		response, err = p.llm.Call(ctx, prompt)
		if err == nil {
			break
		}

		// If retries left, wait and retry
		if attempt < maxRetries {
			delay := backoffDelays[attempt]
		p.Logger.Printf("⚠️  SQL Generation failed (attempt %d/%d): %v\n", attempt+1, maxRetries+1, err)
			p.Logger.Printf("⏳ Retrying after %v...\n\n", delay)
			time.Sleep(delay)
		}
	}

	if err != nil {
		return "", fmt.Errorf("LLM call failed after %d attempts: %w", maxRetries+1, err)
	}

	// Record tokens
	p.promptTexts = append(p.promptTexts, prompt)
	p.responseTexts = append(p.responseTexts, response)

	p.Logger.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	p.Logger.Println("💡 SQL Generation - LLM Response:")
	p.Logger.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	p.Logger.Println(response)
	p.Logger.Println()

	// Extract SQL
	sql := p.extractSQL(response)

	p.Logger.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	p.Logger.Println(" Extracted SQL:")
	p.Logger.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	p.Logger.Println(sql)
	p.Logger.Println()

	return sql, nil
}

// reactLoop ReAct loop
func (p *Pipeline) reactLoop(ctx context.Context, query string, contextPrompt string, crossTableSummary string, result *Result) (string, error) {
	// Create tools
	sqlTool := &SQLTool{
		adapter:   p.adapter,
		useDryRun: p.config.UseDryRun,
		logger:    p.Logger,
	}

	clarifyTool := &ClarifyTool{
		resultFields:            p.config.ResultFields,
		resultFieldsDescription: p.config.ResultFieldsDescription,
		logger:                  p.Logger,
	}

	// Create verify_sql tool
	verifySQLTool := NewVerifySQLTool(p.adapter, p.config.DBType)
	verifySQLTool.logger = p.Logger
	verifySQLTool.question = query
	if p.config.OutputContract != nil {
		verifySQLTool.contract = p.config.OutputContract
	}
	if p.context != nil {
		verifySQLTool.joinHints = CollectJoinCardHints(p.context, result.SelectedTables)
		if len(verifySQLTool.joinHints) > 0 {
			p.Logger.Printf("🔗 verify_sql join cardinality hints: %d 1:N edges\n", len(verifySQLTool.joinHints))
		}
	}

	// Create ReAct Agent
	var toolsList []tools.Tool
	toolsList = []tools.Tool{sqlTool, verifySQLTool}

	if p.config.ClarifyMode == "on" {
		toolsList = append(toolsList, clarifyTool)
	}

	if p.config.EnableProposeFields {
		proposeTool := &ProposeFieldsTool{logger: p.Logger}
		toolsList = append(toolsList, proposeTool)
	}

	if p.config.EnableProbeTool {
		probeTool := NewProbeColumnTool(p.adapter, p.config.DBType)
		probeTool.logger = p.Logger
		toolsList = append(toolsList, probeTool)
	}

	if p.config.EnableProjAlignTool {
		qOnly, evOnly := splitQuestionEvidence(query)
		schemaTxt := BuildAlignerSchemaText(p.context, p.config.DBName, result.SelectedTables)
		alignTool := NewProjAlignTool(p.config.ProjAlignURL, p.config.DBName, qOnly, evOnly, schemaTxt)
		alignTool.logger = p.Logger
		toolsList = append(toolsList, alignTool)
		p.Logger.Printf("🎨 align_projection tool ready (url=%s, tables=%v)\n",
			alignTool.baseURL, result.SelectedTables)
	}

	if p.config.EnableProofread {
		updateTool := NewUpdateRichContextTool(p.config.DBName, p.config.DBType, p.config.Benchmark)
		updateTool.logger = p.Logger
		toolsList = append(toolsList, updateTool)
	}

	// Create handler to collect ReAct steps
	reactHandler := &PrettyReActHandler{logMode: p.config.LogMode, logger: p.Logger}

	// Set up streaming callback if available (for real-time step notifications)
	if p.stepCallback != nil {
		reactHandler.SetStepNotifier(func(step CollectedStep, eventType string) {
			p.stepCallback(ReActStep{
				Step:        step.Step,
				Thought:     step.Thought,
				Action:      step.Action,
				ActionInput: step.ActionInput,
				Observation: step.Observation,
				Phase:       "sql_generation",
			}, eventType)
		})
	}

	// Tell the model a realistic iteration count so it doesn't rush
	// Allow slightly more actual iterations as safety margin
	claimedMaxIterations := 10
	actualMaxIterations := 15

	executor, err := agents.Initialize(
		p.llm,
		toolsList,
		agents.ZeroShotReactDescription,
		agents.WithMaxIterations(actualMaxIterations),
		agents.WithCallbacksHandler(reactHandler),
		// When the model dumps bare SQL (no Action / Final Answer), feed a format hint
		// and let it retry instead of killing the loop immediately.
		agents.WithParserErrorHandler(agents.NewParserErrorHandler(formatReactParseError)),
	)
	if err != nil {
		return "", err
	}

	// Build Prompt - pass claimed iterations to prompt
	prompt := p.buildPrompt(query, contextPrompt, crossTableSummary, true)

	// Print key info only, skip full prompt（avoid duplicate Best Practices etc.）
	p.Logger.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	p.Logger.Printf("🔄 Starting ReAct Loop (Claimed %d, Actual Max %d iterations)\n", claimedMaxIterations, actualMaxIterations)
	p.Logger.Printf("Question: %s\n", query)
	p.Logger.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	agentResult, err := executor.Call(ctx, map[string]any{"input": prompt})

	// Collect ReAct steps from handler (also needed for parse-failure recovery)
	collectedSteps := reactHandler.GetCollectedSteps()
	for _, step := range collectedSteps {
		result.ReActSteps = append(result.ReActSteps, ReActStep{
			Thought:     step.Thought,
			Action:      step.Action,
			ActionInput: step.ActionInput,
			Observation: step.Observation,
			Phase:       "sql_generation",
		})
	}
	result.LLMCalls += len(collectedSteps)
	result.SQLExecutions += sqlTool.ExecutionCount
	result.ClarifyCount = clarifyTool.ClarifyCount

	if err != nil {
		if sql := recoverSQLAfterReactFailure(err, verifySQLTool); sql != "" {
			p.Logger.Printf("\n⚠️  ReAct parse/format failed; recovered SQL fallback:\n%s\n\n", sql)
			return sql, nil
		}
		p.Logger.Printf("\n❌ ReAct Loop failed: %v\n\n", err)
		return "", err
	}

	p.Logger.Println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	p.Logger.Println("✅ ReAct Loop completed successfully")
	p.Logger.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	// Extract final SQL
	if output, ok := agentResult["output"].(string); ok {
		sql := p.extractSQL(output)
		return sql, nil
	}

	return "", fmt.Errorf("no SQL generated")
}

// formatReactParseError turns a langchaingo parse error into an observation that
// steers the model back to Final Answer / Action format (esp. bare-SQL dumps).
func formatReactParseError(errStr string) string {
	raw := unwrapParseErrorOutput(errStr)
	raw = stripOuterQuotes(raw)
	if looksLikeSQL(raw) {
		return fmt.Sprintf(
			"Parse error: output was not in Action/Final Answer format.\n"+
				"If the following SQL is your final answer, reply EXACTLY:\n"+
				"Final Answer: %s\n"+
				"Otherwise use:\nAction: verify_sql\nAction Input: <sql>",
			raw,
		)
	}
	return "Parse error: use format \"Thought: ...\\nAction: <tool>\\nAction Input: <input>\" " +
		"or \"Final Answer: <SQL only>\". Do not output bare SQL without the Final Answer: prefix."
}

// recoverSQLAfterReactFailure salvages SQL when the executor still fails after retries
// (bare SQL dump, or last successful verify_sql).
func recoverSQLAfterReactFailure(err error, verify *VerifySQLTool) string {
	if err == nil {
		return ""
	}
	if !errors.Is(err, agents.ErrUnableToParseOutput) &&
		!strings.Contains(err.Error(), agents.ErrUnableToParseOutput.Error()) {
		return ""
	}
	if raw := unwrapParseErrorOutput(err.Error()); looksLikeSQL(raw) {
		return normalizeRecoveredSQL(raw)
	}
	if verify != nil && looksLikeSQL(verify.LastValidSQL) {
		return normalizeRecoveredSQL(verify.LastValidSQL)
	}
	return ""
}

func unwrapParseErrorOutput(errStr string) string {
	const marker = "unable to parse agent output:"
	idx := strings.Index(strings.ToLower(errStr), marker)
	if idx >= 0 {
		return strings.TrimSpace(errStr[idx+len(marker):])
	}
	return strings.TrimSpace(errStr)
}

func stripOuterQuotes(s string) string {
	s = strings.TrimSpace(s)
	if len(s) >= 2 {
		if (s[0] == '"' && s[len(s)-1] == '"') || (s[0] == '\'' && s[len(s)-1] == '\'') {
			return strings.TrimSpace(s[1 : len(s)-1])
		}
	}
	return s
}

func looksLikeSQL(s string) bool {
	s = normalizeRecoveredSQL(s)
	if s == "" {
		return false
	}
	upper := strings.ToUpper(s)
	return strings.HasPrefix(upper, "SELECT") ||
		strings.HasPrefix(upper, "WITH") ||
		strings.HasPrefix(upper, "INSERT") ||
		strings.HasPrefix(upper, "UPDATE") ||
		strings.HasPrefix(upper, "DELETE")
}

func normalizeRecoveredSQL(s string) string {
	s = strings.TrimSpace(s)
	s = stripOuterQuotes(s)
	// Strip markdown fences (```sql ... ``` / ``` ... ```)
	if strings.HasPrefix(s, "```") {
		s = strings.TrimPrefix(s, "```")
		s = strings.TrimSpace(s)
		if len(s) >= 3 && strings.EqualFold(s[:3], "sql") {
			s = strings.TrimSpace(s[3:])
		}
		if idx := strings.Index(s, "```"); idx >= 0 {
			s = s[:idx]
		}
	}
	s = strings.TrimSpace(s)
	s = stripOuterQuotes(s)
	// If still contaminated, take from first SELECT/WITH
	upper := strings.ToUpper(s)
	for _, kw := range []string{"SELECT ", "SELECT\n", "SELECT\t", "WITH ", "WITH\n"} {
		if idx := strings.Index(upper, kw); idx > 0 {
			s = strings.TrimSpace(s[idx:])
			break
		}
	}
	return strings.TrimSpace(s)
}

// buildPrompt builds prompt
func (p *Pipeline) buildPrompt(query string, contextPrompt string, crossTableSummary string, isReact bool) string {
	var sb strings.Builder

	sb.WriteString("You are a SQL expert. Generate SQL to answer the question.\n\n")

	// Database type info
	if p.config.DBType != "" {
		sb.WriteString(fmt.Sprintf("**Database Type: %s**\n", p.config.DBType))
		sb.WriteString(fmt.Sprintf("CRITICAL: Write SQL that strictly follows %s syntax rules.\n", p.config.DBType))
		sb.WriteString("Common syntax differences to watch:\n")
		switch p.config.DBType {
		case "SQLite":
			sb.WriteString("- Use double quotes for identifiers if needed, single quotes for strings\n")
			sb.WriteString("- No LIMIT offset without LIMIT clause\n")
			sb.WriteString("- Use || for string concatenation\n")
		case "MySQL":
			sb.WriteString("- Use backticks for identifiers, single quotes for strings\n")
			sb.WriteString("- LIMIT syntax: LIMIT offset, count\n")
			sb.WriteString("- Use CONCAT() for string concatenation\n")
		case "PostgreSQL":
			sb.WriteString("- Use double quotes for identifiers, single quotes for strings\n")
			sb.WriteString("- LIMIT syntax: LIMIT count OFFSET offset\n")
			sb.WriteString("- Use || for string concatenation\n")
		}
		sb.WriteString("\n")
	}

	// Rich Context
	if contextPrompt != "" {
		sb.WriteString("Database Schema:\n")
		sb.WriteString(contextPrompt)
		sb.WriteString("\n\n")
	}

	// Cross-table quality summary (smart injection from full-table analysis)
	if crossTableSummary != "" {
		sb.WriteString(crossTableSummary)
		sb.WriteString("\n")
	}

	// SQL Best Practices (only added with Rich Context)
	// These are enhanced hints from onboarding, should not be used in baseline
	if p.config.UseRichContext {
		// JOIN paths and field semantics (only in Rich Context mode)
		if p.context != nil {
			if joinPathsPrompt := p.context.FormatJoinPathsForPrompt(); joinPathsPrompt != "" {
				sb.WriteString(joinPathsPrompt)
			}
			if fieldSemanticsPrompt := p.context.FormatFieldSemanticsForPrompt(); fieldSemanticsPrompt != "" {
				sb.WriteString(fieldSemanticsPrompt)
			}
		}

		sb.WriteString("IMPORTANT: Rich Context may be outdated or incorrect. When Rich Context conflicts with actual database data, trust the database.\n\n")

		if p.config.Benchmark == "bird" {
			sb.WriteString(p.buildBirdBestPractices())
		} else {
			sb.WriteString(p.buildSpiderBestPractices())
		}
	}

	sb.WriteString(fmt.Sprintf("Question: %s\n\n", query))

	// force mode: mandatory field info in prompt
	if p.config.ClarifyMode == "force" && len(p.config.ResultFields) > 0 {
		sb.WriteString("⚠️ REQUIRED OUTPUT FIELDS:\n")
		fieldsStr := strings.Join(p.config.ResultFields, ", ")
		sb.WriteString(fmt.Sprintf("Your SQL SELECT clause MUST return EXACTLY these fields in this EXACT ORDER: %s\n", fieldsStr))
		if p.config.ResultFieldsDescription != "" {
			sb.WriteString(fmt.Sprintf("Field descriptions: %s\n", p.config.ResultFieldsDescription))
		}
		sb.WriteString("\nCRITICAL: The SELECT output column names must match these fields. You may still use table.column syntax in the SQL body for disambiguation.\n")
		sb.WriteString("Any deviation from this field list will be considered INCORRECT.\n\n")
	} else if p.config.EnableOutputContract && p.config.OutputContract != nil {
		sb.WriteString(p.config.OutputContract.FormatForPrompt())
	}

	if isReact {
		// Tools available
		sb.WriteString(`Available Tools:
- execute_sql: Execute SQL and see results
- verify_sql: Verify SQL correctness — checks syntax, executes, and reports row count + sample results + warnings`)
		if p.config.ClarifyMode == "on" {
			sb.WriteString(`
- clarify_fields: Ask which fields to return (when question doesn't specify)`)
		}
		if p.config.EnableProposeFields {
			sb.WriteString(`
- propose_output_fields: Propose output columns yourself (gold-free substitute for clarify)`)
		}
		if p.config.EnableProbeTool {
			sb.WriteString(`
- probe_column_values: Probe DISTINCT values of table.column before using string literals (input: table.column or table.column|limit)`)
		}
		if p.config.EnableProjAlignTool {
			sb.WriteString(`
- align_projection: Consult BIRD projection taste aligner (soft shape/fields hint; input: auto)`)
		}
		if p.config.EnableProofread {
			sb.WriteString(`
- update_rich_context: Update expired/incorrect Rich Context`)
		}

		if p.config.EnableProjAlignTool {
			sb.WriteString(`

Projection Taste Aligner — CONTEXT OVER CONTROL:
- After schema linking, call align_projection ONCE (Action Input: auto) before drafting final SQL.
- It is a specialist model trained on BIRD gold *projection taste* (shape + ordered fields), NOT a SQL writer.
- Treat its JSON as soft context / taste reference — helpful for count-vs-list quirks and which columns to return.
- You remain in control: OVERRIDE when it conflicts with Evidence, linked schema, or verify_sql.
- Do NOT treat it as a forced SELECT list. JOIN/filters/SQL correctness stay your responsibility.
`)
		}

		// Workflow
		sb.WriteString(`

Workflow:
1. Analyze question and schema`)
		step := 2
		if p.config.EnableProjAlignTool {
			sb.WriteString(fmt.Sprintf(`
%d. Call align_projection (input: auto) for soft projection taste — then decide whether to follow it`, step))
			step++
		}
		if p.config.ClarifyMode == "on" {
			sb.WriteString(fmt.Sprintf(`
%d. If unclear which columns needed → use clarify_fields`, step))
			step++
			sb.WriteString(fmt.Sprintf(`
%d. If string values uncertain → use probe_column_values (preferred) or execute_sql`, step))
			step++
		} else if p.config.EnableProposeFields {
			sb.WriteString(fmt.Sprintf(`
%d. If output columns are still ambiguous after align_projection → optional propose_output_fields`, step))
			step++
			if p.config.EnableProbeTool {
				sb.WriteString(fmt.Sprintf(`
%d. If string/enum literals uncertain (see Value Probe Hints) → use probe_column_values BEFORE writing WHERE`, step))
				step++
			}
		} else if p.config.EnableProbeTool {
			sb.WriteString(fmt.Sprintf(`
%d. If string/enum literals uncertain → use probe_column_values BEFORE writing WHERE`, step))
			step++
		} else {
			sb.WriteString(fmt.Sprintf(`
%d. If string values missing from Rich Context → use execute_sql to find them`, step))
			step++
		}
		if p.config.EnableProofread {
			sb.WriteString(fmt.Sprintf(`
%d. If Rich Context conflicts with actual data → use update_rich_context`, step))
			step++
		}
		sb.WriteString(fmt.Sprintf(`
%d. Write SQL following best practices
%d. MANDATORY: Use verify_sql to check your SQL before giving Final Answer
%d. If verify_sql reports issues → fix and re-verify
%d. Provide Final Answer

`, step, step+1, step+2, step+3))

		// Output format
		sb.WriteString(`Output Format (choose ONE):
A) Use tool:
   Thought: [reasoning]
   Action: [tool_name]
   Action Input: [input]

B) Give answer:
   Thought: [reasoning]
   Final Answer: [SQL only, no markdown]

⚠️ NEVER write "Action: None"! If no tool needed, use option B.

`)

		// Critical rules
		sb.WriteString(`Critical Rules:
1. ONE action per iteration — never output multiple Action/Action Input pairs in a single response
2. Field Order: SELECT fields MUST match expected order exactly
3. Iterations: 10 max (update_rich_context doesn't count). Track: "Iteration X/10"
4. MUST verify: Always call verify_sql before Final Answer
5. No repetition: If stuck, try different approach
6. Final Answer: SQL only, no explanations
7. NEVER give up: Always output a valid SQL query. NEVER output comments, empty strings, or SELECT 0/1.
   If you cannot find the right table or column, write your best-guess query.

`)

		// In ReAct mode, re-emphasize field requirements (prevent long-range attention loss)
		if p.config.ClarifyMode == "force" && len(p.config.ResultFields) > 0 {
			sb.WriteString(`
⚠️ REMINDER - REQUIRED OUTPUT FIELDS ⚠️
Before Final Answer, verify your SQL returns these EXACT fields in EXACT order:
`)
			fieldsStr := strings.Join(p.config.ResultFields, ", ")
			sb.WriteString(fmt.Sprintf("Required: %s\n", fieldsStr))
			if p.config.ResultFieldsDescription != "" {
				sb.WriteString(fmt.Sprintf("(%s)\n", p.config.ResultFieldsDescription))
			}
			sb.WriteString(`If field is a name/description, JOIN the referenced table. Do NOT return IDs when names are required.
`)
		}

		if p.config.ClarifyMode == "on" {
			sb.WriteString(`
6. Clarify: Follow field names/descriptions from clarify_fields precisely
`)
		}
	} else {
		sb.WriteString(`Task: Generate SQL directly.
Output ONLY the SQL query (no explanations, no markdown).

Format:
SELECT ...`)
	}

	return sb.String()
}

// extractSQL extracts SQL from response
func (p *Pipeline) extractSQL(response string) string {
	// Try extracting Final Answer
	if idx := strings.Index(response, "Final Answer:"); idx >= 0 {
		response = response[idx+13:]
	}

	// Clean up
	response = strings.TrimSpace(response)

	// Remove markdown code blocks
	response = strings.TrimPrefix(response, "```sql")
	response = strings.TrimPrefix(response, "```")
	response = strings.TrimSuffix(response, "```")
	response = strings.TrimSpace(response)

	// Extract backtick-wrapped SQL
	if strings.Contains(response, "`SELECT") || strings.Contains(response, "`select") {
		start := strings.Index(response, "`")
		if start >= 0 {
			end := strings.Index(response[start+1:], "`")
			if end >= 0 {
				response = response[start+1 : start+1+end]
			}
		}
	}

	// If multi-line response，and first line is SELECT, take first line only
	lines := strings.Split(response, "\n")
	if len(lines) > 1 {
		firstLine := strings.TrimSpace(lines[0])
		if strings.HasPrefix(strings.ToUpper(firstLine), "SELECT") ||
			strings.HasPrefix(strings.ToUpper(firstLine), "WITH") ||
			strings.HasPrefix(strings.ToUpper(firstLine), "INSERT") ||
			strings.HasPrefix(strings.ToUpper(firstLine), "UPDATE") ||
			strings.HasPrefix(strings.ToUpper(firstLine), "DELETE") {
			// Find SQL statement end (non-SQL content)
			var sqlLines []string
			for _, line := range lines {
				trimmed := strings.TrimSpace(line)
				// If explanatory text encountered (e.g. "This query"), stop
				if strings.HasPrefix(trimmed, "This ") ||
					strings.HasPrefix(trimmed, "The ") ||
					strings.HasPrefix(trimmed, "Since ") ||
					strings.HasPrefix(trimmed, "Note:") {
					break
				}
				sqlLines = append(sqlLines, line)
			}
			response = strings.Join(sqlLines, "\n")
		}
	}

	result := strings.TrimSpace(response)

	// Sanitize give-up patterns: if LLM output a comment, placeholder, or empty string,
	// try to extract any SELECT statement from the full response as fallback
	if p.isGiveUpSQL(result) {
		// Try to find any SELECT statement in the original response
		if fallback := p.extractFallbackSQL(response); fallback != "" {
			p.Logger.Printf("⚠️  extractSQL: LLM gave up (%q), using fallback: %s\n", result[:min(len(result), 50)], fallback[:min(len(fallback), 100)])
			return fallback
		}
		// If truly nothing, return SELECT 1 (better than empty which crashes evaluation)
		p.Logger.Printf("⚠️  extractSQL: LLM gave up with no fallback, returning SELECT 1\n")
		return "SELECT 1"
	}

	return result
}

// isGiveUpSQL detects if the SQL is a give-up pattern (empty, comment, placeholder)
func (p *Pipeline) isGiveUpSQL(sql string) bool {
	if sql == "" {
		return true
	}
	upper := strings.ToUpper(strings.TrimSpace(sql))
	// Comment-only
	if strings.HasPrefix(sql, "--") || strings.HasPrefix(sql, "/*") {
		return true
	}
	// Hardcoded placeholder values
	if upper == "SELECT 0" || upper == "SELECT 0;" ||
		upper == "SELECT 1" || upper == "SELECT 1;" ||
		upper == "SELECT NULL" || upper == "SELECT NULL;" {
		return true
	}
	// Not a SQL statement at all
	if !strings.HasPrefix(upper, "SELECT") && !strings.HasPrefix(upper, "WITH") {
		return true
	}
	return false
}

// extractFallbackSQL tries to find a valid SELECT statement in the raw response text
func (p *Pipeline) extractFallbackSQL(response string) string {
	upper := strings.ToUpper(response)
	// Find the last SELECT statement (likely the most refined one)
	lastIdx := strings.LastIndex(upper, "SELECT ")
	if lastIdx < 0 {
		return ""
	}

	candidate := strings.TrimSpace(response[lastIdx:])
	// Take until end of SQL (semicolon, double newline, or explanatory text)
	lines := strings.Split(candidate, "\n")
	var sqlLines []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" && len(sqlLines) > 0 {
			break
		}
		if strings.HasPrefix(trimmed, "This ") || strings.HasPrefix(trimmed, "The ") ||
			strings.HasPrefix(trimmed, "Note:") || strings.HasPrefix(trimmed, "Thought:") {
			break
		}
		sqlLines = append(sqlLines, line)
	}

	sql := strings.TrimSpace(strings.Join(sqlLines, "\n"))
	sql = strings.TrimSuffix(sql, ";")
	sql = strings.TrimSpace(sql)

	if sql != "" && !p.isGiveUpSQL(sql) {
		return sql
	}
	return ""
}

// min returns the smaller of two ints
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// SQLTool SQL execution tool
type SQLTool struct {
	adapter        adapter.DBAdapter
	useDryRun      bool
	ExecutionCount int
	logger         *InferenceLogger
}

func (t *SQLTool) Name() string {
	return "execute_sql"
}

func (t *SQLTool) Description() string {
	if t.useDryRun {
		return `Execute SQL query with dry run validation first.
Input: SQL query string
Output: Query results or validation errors`
	}
	return `Execute SQL query and return results.
Input: SQL query string
Output: Query results`
}

func (t *SQLTool) Call(ctx context.Context, input string) (string, error) {
	t.ExecutionCount++

	logf := func(format string, a ...interface{}) {
		if t.logger != nil {
			t.logger.Printf(format, a...)
		} else {
			fmt.Printf(format, a...)
		}
	}

	logf("\n🔧 Tool Call [execute_sql] #%d:\n", t.ExecutionCount)
	logf("Input SQL: %s\n", input)

	sql := strings.TrimSpace(input)

	// Dry Run validation (if enabled)
	if t.useDryRun {
		if err := t.adapter.DryRunSQL(ctx, sql); err != nil {
			return fmt.Sprintf("SQL validation failed: %v", err), nil
		}
	}

	// Execute SQL
	result, err := t.adapter.ExecuteQuery(ctx, sql)
	if err != nil {
		return fmt.Sprintf("SQL execution failed: %v", err), nil
	}

	// Format results
	output := fmt.Sprintf("Query executed successfully!\nRows: %d\n", result.RowCount)

	// Decide display based on char length not row count
	// Serialize result and check length
	if result.RowCount > 0 {
		sampleStr := fmt.Sprintf("%v", result.Rows)
		const maxSampleLength = 1000 // max display 1000 chars

		if len(sampleStr) <= maxSampleLength {
			// Full display
			output += fmt.Sprintf("Sample results: %s\n", sampleStr)
		} else {
			// Truncate with ellipsis
			truncated := sampleStr[:maxSampleLength]
			output += fmt.Sprintf("Sample results: %s... (truncated, showing first %d chars of %d total)\n",
				truncated, maxSampleLength, len(sampleStr))
		}
	}

	logf("Output: %s\n", output)

	return output, nil
}

// ClarifyTool tool for asking which fields to return
type ClarifyTool struct {
	resultFields            []string
	resultFieldsDescription string
	ClarifyCount            int
	logger                  *InferenceLogger
}

func (t *ClarifyTool) Name() string {
	return "clarify_fields"
}

func (t *ClarifyTool) Description() string {
	return `Ask for clarification about which fields should be returned in the query result.
Use this when the question doesn't specify which columns to return.
Input: Your question about which fields to return (e.g., "Which fields should I return?")
Output: List of required fields or description of required fields`
}

func (t *ClarifyTool) Call(ctx context.Context, input string) (string, error) {
	t.ClarifyCount++

	logf := func(format string, a ...interface{}) {
		if t.logger != nil {
			t.logger.Printf(format, a...)
		} else {
			fmt.Printf(format, a...)
		}
	}

	logf("\n🔔 Clarification requested: %s\n", input)

	// Return field list + descriptions
	fieldsStr := strings.Join(t.resultFields, ", ")
	response := fmt.Sprintf("Required fields in EXACT ORDER: %s\n\nField descriptions: %s\n\nIMPORTANT: Use these field names WITHOUT table prefixes (e.g., 'Name' not 'singer.Name')",
		fieldsStr,
		t.resultFieldsDescription)

	logf("📋 Clarification response: %s\n\n", response)

	return response, nil
}

// buildSpiderBestPractices returns SQL best practices for Spider benchmark
func (p *Pipeline) buildSpiderBestPractices() string {
	return `SQL Rules & Best Practices:
1. Type Mismatch — ONLY when QualityIssues explicitly flags a column:
   - Only CAST when you KNOW the column stores pure numeric strings as TEXT
   - NEVER CAST time/duration/date strings
   - Prefer CAST(... AS REAL) over CAST(... AS INTEGER) to preserve decimals
2. Whitespace: ONLY use TRIM() when QualityIssues specifically mentions whitespace for that column
3. NULL handling — For WHERE-clause matching ONLY:
   - Use IS NOT NULL only when filtering JOIN keys or matching specific values
   - Do NOT add IS NOT NULL or != '' to filter result rows
4. String matching:
   - Use exact values from Rich Context when available
   - In ReAct mode: use execute_sql to find exact values when uncertain
5. Aggregation patterns:
   - "Highest/Lowest/Top N": ORDER BY col DESC/ASC LIMIT N (NOT MAX/MIN which returns 1 row)
   - "Count by X": SELECT X, COUNT(*) ... GROUP BY X (MUST include GROUP BY)
   - "Rate/Percentage": CAST(num AS REAL) / CAST(denom AS REAL) (avoid integer division)
   - "Average count of X per Y": MUST use subquery — first GROUP BY Y, then AVG
   - After JOIN, count entities with COUNT(DISTINCT entity.id) not COUNT(*)
6. Extreme values with ties:
   - Use subquery: WHERE col = (SELECT MAX/MIN(col) FROM table)
   - AVOID ORDER BY + LIMIT 1 (misses ties)
   - Exception: question says "one" or "any one" → LIMIT 1 is OK
7. DISTINCT — decide based on context:
   - USE when: "different", "unique", "distinct", listing attributes from JOINs
   - DO NOT USE when: "list all records", already using GROUP BY
   - After JOIN counting: COUNT(DISTINCT entity.id)
8. Orphan records: If quality issues mention orphans, use LEFT JOIN instead of INNER JOIN
9. Value verification: When using specific text values in WHERE, verify which column contains it first
10. ABSOLUTE RULES:
   - You MUST always output a valid executable SQL query
   - NEVER output empty strings, SQL comments, or placeholder values (SELECT 0)
   - Use EXACT table and column names as shown in schema

`
}

// buildBirdBestPractices returns SQL best practices tailored for BIRD benchmark
// BIRD-specific: evidence-driven, projection-focused, DISTINCT-aware
func (p *Pipeline) buildBirdBestPractices() string {
	return `SQL Rules & Best Practices (BIRD):

1. EVIDENCE IS CRITICAL: The "Evidence" section contains exact column mappings, value constraints, and formulas.
   - If evidence says "X refers to Y = 'Z'" → you MUST use column Y with value 'Z'
   - If evidence gives a formula → use that exact formula
   - If evidence defines a threshold → use those exact bounds
   - NEVER ignore or reinterpret evidence constraints

2. DO NOT ADD EXTRA CONDITIONS: Only add WHERE/HAVING conditions that are explicitly stated in the question or evidence.
   - Do NOT infer filters from domain knowledge
   - Do NOT add "IS NOT NULL", "!= ''", or TRIM() to clean data unless explicitly asked
   - "list all X of Y" → only filter by Y, no extra constraints on X

3. Projection (SELECT columns):
   - Return ONLY the columns the question asks for — no extra columns
   - Keep the SAME ORDER as the question asks (column order matters)
   - When question asks for a name/description, JOIN to get the text — do NOT return IDs
   - Do NOT concatenate columns with || or CONCAT unless evidence explicitly requires a single string
   - Prefer separate SELECT columns over concat (BIRD often grades split columns)

4. DISTINCT — THIS IS CRITICAL, follow these rules precisely:
   ★ DEFAULT: Do NOT add DISTINCT unless you have a specific reason below.
   ★ Use schema Relationships / [N:1] / [1:N] / avg children hints in Rich Context before deciding.
   USE DISTINCT when:
   - Question explicitly says "different", "unique", "distinct", "how many types/kinds"
   - JOIN crosses a 1:N edge (parent→many children) and question asks for unique parents/entities:
     e.g., "list patient diagnoses" after JOIN Patient→Laboratory (1:many) → SELECT DISTINCT Diagnosis
     e.g., COUNT patients → COUNT(DISTINCT Patient.ID) after JOIN
   - Question asks "what are the X" (implying unique values): "what colors exist", "which cities"
   - verify_sql warns about duplicate rows or 1:N multiplication — fix with DISTINCT / COUNT(DISTINCT)
   DO NOT use DISTINCT when:
   - Question says "list all", "list the records", "list entries" (wants all rows including repeats)
   - Query on a single table with no JOIN (no duplicates possible) — especially avoid COUNT(DISTINCT)
   - Already using GROUP BY (GROUP BY implies uniqueness)
   - Question asks about occurrences/instances: "list badges obtained", "show all transactions"
   - Aggregation queries (SUM, AVG, MAX, MIN) — DISTINCT inside aggregation changes the result
   ★ WHEN IN DOUBT: Omit DISTINCT. It is safer to return extra rows than to lose valid rows.
   ★ VERIFY: After writing SQL, run verify_sql — if it flags 1:N multiplication and the question wants unique entities, add DISTINCT; otherwise remove it.

5. JOIN — use the minimum JOINs needed:
   - Before writing SQL, trace which tables are needed: question mentions X → column is in table A → filter needs table B → JOIN A to B
   - If question needs data from table A but filters on a concept in table B, you MUST JOIN both tables
   - Do NOT skip JOINs by querying a single table when the answer requires cross-table data
   - Do NOT add extra JOINs "just in case" — each unnecessary JOIN can multiply rows and change results
   - Prefer documented FK join paths; when Relationships mark 1:N, expect row multiplication
   - After JOIN, check: does the JOIN create row multiplication? If so, consider DISTINCT or aggregation

6. CAST/Type — be extremely conservative:
   - ONLY CAST when Rich Context or QualityIssues explicitly flags a type mismatch for that column
   - NEVER CAST date/time columns: compare dates as strings (birthday > '1990', date < '2021-01-01')
   - NEVER CAST time strings (like "1:23.456") or duration strings — compare them as-is
   - For numeric comparison on a TEXT column, prefer direct string comparison when possible
   - When doing division for percentages/rates: use CAST(numerator AS REAL) to avoid integer truncation
   - ★ If unsure whether CAST is needed, DON'T CAST — just use the column directly

7. Aggregation:
   - "Highest/Lowest/Top N/Bottom N": Always use ORDER BY col DESC/ASC LIMIT N
   - Do NOT use WHERE col = (SELECT MAX/MIN(...)) — this returns ties
   - "Rate/Percentage": CAST(numerator AS REAL) * 100 / denominator
   - "Average count of X per Y": subquery first — GROUP BY Y to get counts, then AVG
   - After JOIN, if counting entities, use COUNT(DISTINCT entity.id)
   - "between X and/to Y" → use SQL BETWEEN (includes BOTH endpoints)

8. NULL/Empty handling:
   - Use IS NOT NULL only when filtering JOIN keys or matching specific values
   - Do NOT add IS NOT NULL or != '' to filter result rows unless the question asks for it

9. Date handling:
   - Compare date columns as strings: column > '1990' or column < '2021-01-01' (SQLite stores dates as text)
   - Do NOT CAST date columns to INTEGER for comparison — this breaks date format
   - For year extraction: STRFTIME('%%Y', column) = 'YYYY'
   - "after date D" → column > 'D'; "before date D" → column < 'D'

10. Table and Column names:
   - Use EXACT names as shown in the schema — preserve capitalization and pluralization
   - If schema shows 'Patient', write 'Patient', NOT 'patients'

11. ABSOLUTE RULES:
   - You MUST always output a valid executable SQL query
   - NEVER output empty strings, SQL comments, or placeholder values (SELECT 0/1)
   - NEVER hardcode result values — let the database compute the answer

`
}


package inference

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
)

// VerifySQLTool SQL syntax verification tool
type VerifySQLTool struct {
	adapter  adapter.DBAdapter
	dbType   string
	logger   *InferenceLogger
	contract *OutputContract
	// question is the user question (+ optional evidence) for join/DISTINCT heuristics.
	question string
	// joinHints are 1:N FK edges from Rich Context for selected tables.
	joinHints []JoinCardHint
	// LastValidSQL is the most recent SQL that passed DB execution in this tool.
	// Used as a ReAct parse-failure fallback when the model dumps bare SQL.
	LastValidSQL string
}

// Name returns tool name
func (t *VerifySQLTool) Name() string {
	return "verify_sql"
}

// Description returns tool description
func (t *VerifySQLTool) Description() string {
	return `Verify SQL syntax AND result reasonableness before submitting final answer.
This tool checks for common syntax errors, validates via database execution, and reports result quality.

Input: SQL query string to verify
Output: Verification report with syntax check, row count, sample results, and warnings

Use this tool BEFORE giving your final answer to ensure SQL correctness.`
}

// Call executes verification
func (t *VerifySQLTool) Call(ctx context.Context, input string) (string, error) {
	raw := strings.TrimSpace(input)
	qOnly, evOnly := splitQuestionEvidence(t.question)
	sql := SanitizeGeneratedSQLWithQuery(raw, qOnly, evOnly)

	logf := func(format string, a ...interface{}) {
		if t.logger != nil {
			t.logger.Printf(format, a...)
		} else {
			fmt.Printf(format, a...)
		}
	}

	logf("\n🔍 Tool Call [verify_sql]:\n")
	logf("Input SQL: %s\n", raw)
	if sql != raw {
		logf("Sanitized SQL: %s\n", sql)
	}

	// 1. Quick static check (avoid obvious errors)
	if err := t.quickCheck(sql); err != nil {
		result := fmt.Sprintf("❌ SQL validation failed (static check):\n%v\n\nPlease fix the error and try again.", err)
		logf("Output: %s\n", result)
		return result, nil
	}

	// 2. Execute SQL for validation and result analysis
	data, err := t.adapter.ExecuteQuery(ctx, sql)
	if err != nil {
		hint := ""
		low := strings.ToLower(err.Error())
		if strings.Contains(low, "iif") {
			hint = "\nHint: use CASE WHEN … THEN … ELSE … END instead of IIF (older SQLite)."
		}
		if strings.Contains(low, "right") || strings.Contains(low, "full outer") {
			hint += "\nHint: SQLite has no RIGHT/FULL JOIN — rewrite as LEFT JOIN."
		}
		result := fmt.Sprintf("❌ SQL validation failed (database check):\n%v%s\n\nPlease fix the error and try again.", err, hint)
		logf("Output: %s\n", result)
		return result, nil
	}
	t.LastValidSQL = sql

	var report strings.Builder
	report.WriteString("✓ SQL is valid!\n")
	if sql != raw {
		report.WriteString("Note: auto-rewrote IIF→CASE and/or RIGHT|FULL JOIN→LEFT JOIN for SQLite; also projection (name split / ranking metric).\n")
	}

	// 3. Row count analysis
	report.WriteString(fmt.Sprintf("Row count: %d\n", data.RowCount))

	var warnings []string

	if data.RowCount == 0 {
		warnings = append(warnings, t.emptyResultWarning(sql))
	}

	// 4. Sample results (first 3 rows)
	if data.RowCount > 0 && len(data.Rows) > 0 {
		report.WriteString("Sample results:\n")
		maxShow := 3
		if data.RowCount < 3 {
			maxShow = data.RowCount
		}
		for i := 0; i < maxShow && i < len(data.Rows); i++ {
			report.WriteString(fmt.Sprintf("  Row %d: %v\n", i+1, data.Rows[i]))
		}

		// 5. Check for NULL values in results — only warn if majority are NULL
		nullCount := 0
		totalValues := 0
		for _, row := range data.Rows {
			for _, val := range row {
				totalValues++
				if val == nil {
					nullCount++
				}
			}
		}
		if totalValues > 0 {
			nullRatio := float64(nullCount) / float64(totalValues)
			if nullRatio > 0.5 {
				warnings = append(warnings, fmt.Sprintf("⚠️  %.0f%% of result values are NULL. This may indicate a wrong JOIN or missing table. Double-check JOIN conditions.", nullRatio*100))
			}
		}
	}

	// 6. Check duplicate rows
	rows := convertQueryResultFormat(data.Rows)
	hasDupRows := false
	if duplicateWarning := t.checkDuplicateRows(rows); duplicateWarning != "" {
		hasDupRows = true
		warnings = append(warnings, duplicateWarning)
	}

	// 6b. JOIN / DISTINCT / 1:N cardinality heuristics (gold-free)
	if joinWarns := AnalyzeJoinDistinctIssues(sql, t.question, t.joinHints, hasDupRows, data.RowCount); len(joinWarns) > 0 {
		warnings = append(warnings, joinWarns...)
	}

	// 7. Projection / output-contract checks (gold-free)
	if t.contract != nil && len(data.Columns) > 0 {
		if w := t.checkProjectionAgainstContract(data.Columns); w != "" {
			warnings = append(warnings, w)
		}
	}
	if w := t.checkNameVsID(data); w != "" {
		warnings = append(warnings, w)
	}
	if w := t.checkCountDistinctDivergence(ctx, sql, data); w != "" {
		warnings = append(warnings, w)
	}
	if len(data.Columns) > 8 {
		warnings = append(warnings, fmt.Sprintf("⚠️  Result has %d columns — question may ask for fewer. Drop unrelated SELECT columns.", len(data.Columns)))
	}
	if HasProjectionConcat(sql) {
		warnings = append(warnings, "⚠️  SELECT uses || or CONCAT — BIRD often wants separate columns. Prefer comma-separated SELECT fields unless evidence requires one string.")
	}
	if w := t.checkRankingLimit(sql); w != "" {
		warnings = append(warnings, w)
	}

	// 8. Build final result
	if len(warnings) > 0 {
		report.WriteString(strings.Join(warnings, "\n"))
		report.WriteString("\n")
	}

	report.WriteString("If results look correct, proceed to Final Answer.")

	result := report.String()
	logf("Output: %s\n", result)
	return result, nil
}

func (t *VerifySQLTool) checkProjectionAgainstContract(columns []string) string {
	if t.contract == nil {
		return ""
	}
	var parts []string
	if t.contract.MaxCols > 0 && len(columns) > t.contract.MaxCols {
		parts = append(parts, fmt.Sprintf(
			"⚠️  Projection too wide: got %d columns %v but contract expects ≤%d. Drop extra SELECT columns (keep only what the question asks).",
			len(columns), columns, t.contract.MaxCols))
	}
	if t.contract.MinCols > 0 && len(columns) < t.contract.MinCols {
		parts = append(parts, fmt.Sprintf(
			"⚠️  Projection too narrow: got %d columns %v but the question asks for ≥%d metrics/attributes. Return each asked metric as its own column in ONE row — do not collapse into a single number or two rows.",
			len(columns), columns, t.contract.MinCols))
	}
	if len(t.contract.Keywords) == 0 {
		return strings.Join(parts, "\n")
	}
	joined := strings.ToLower(strings.Join(columns, " "))
	var hit []string
	for _, kw := range t.contract.Keywords {
		k := strings.ToLower(kw)
		if len(k) < 3 {
			continue
		}
		if strings.Contains(joined, k) {
			hit = append(hit, kw)
		}
	}
	// Soft signal only — missing keywords are common with aliases
	if len(hit) == 0 && len(t.contract.Keywords) >= 2 {
		parts = append(parts, fmt.Sprintf("⚠️  Output columns %v do not obviously match contract keywords %v. Re-check SELECT vs question/evidence.", columns, t.contract.Keywords))
	}
	return strings.Join(parts, "\n")
}

func (t *VerifySQLTool) checkCountDistinctDivergence(ctx context.Context, sql string, data *adapter.QueryResult) string {
	if t.adapter == nil || data == nil {
		return ""
	}
	q, ev := splitQuestionEvidence(t.question)
	if asksTwoOutputMetrics(q, ev) {
		return ""
	}
	if !reHowMany.MatchString(q) && !reAskUniqueKW.MatchString(q) && !reDistinct.MatchString(q) {
		return ""
	}
	alt, ok := flipCountDistinct(sql)
	if !ok || alt == sql {
		return ""
	}
	altData, err := t.adapter.ExecuteQuery(ctx, alt)
	if err != nil || altData == nil {
		return ""
	}
	cur, altV, same := compareVerifyResults(data, altData)
	if same {
		return ""
	}
	return fmt.Sprintf(
		"⚠️  COUNT vs COUNT(DISTINCT) diverge: current %s vs flipped %s. If counting unique entities use COUNT(DISTINCT …); if counting rows/mentions drop DISTINCT. Do not Final Answer until you pick.",
		cur, altV)
}

func compareVerifyResults(a, b *adapter.QueryResult) (sa, sb string, same bool) {
	if a.RowCount != 1 || b.RowCount != 1 || len(a.Columns) != 1 || len(b.Columns) != 1 {
		sa = fmt.Sprintf("%d rows", a.RowCount)
		sb = fmt.Sprintf("%d rows", b.RowCount)
		return sa, sb, a.RowCount == b.RowCount
	}
	sa = stringifyFirstCell(a)
	sb = stringifyFirstCell(b)
	return sa, sb, sa == sb
}

func stringifyFirstCell(data *adapter.QueryResult) string {
	if data == nil || len(data.Rows) == 0 || len(data.Columns) == 0 {
		return ""
	}
	v := data.Rows[0][data.Columns[0]]
	if v == nil {
		return "NULL"
	}
	return fmt.Sprintf("%v", v)
}

func (t *VerifySQLTool) checkNameVsID(data *adapter.QueryResult) string {
	if data == nil || len(data.Rows) == 0 || len(data.Columns) == 0 {
		return ""
	}
	q, _ := splitQuestionEvidence(t.question)
	asksName := reName.MatchString(q) && !reID.MatchString(strings.ToLower(q))
	asksID := reID.MatchString(strings.ToLower(q)) && !reName.MatchString(q)
	if !asksName && !asksID {
		return ""
	}
	kind := firstColKind(data)
	if asksName && kind == "id" {
		return "⚠️  Result looks like opaque IDs but the question asks for names/titles. SELECT the name/title column instead of the identifier."
	}
	if asksID && kind == "name" {
		return "⚠️  Result looks like names but the question asks for IDs. SELECT the identifier column instead of the display name."
	}
	return ""
}

func firstColKind(data *adapter.QueryResult) string {
	if data == nil || len(data.Rows) == 0 || len(data.Columns) == 0 {
		return "empty"
	}
	col := data.Columns[0]
	n := len(data.Rows)
	if n > 20 {
		n = 20
	}
	ids, names := 0, 0
	for i := 0; i < n; i++ {
		v := data.Rows[i][col]
		if looksIDCell(v) {
			ids++
		}
		if looksNameCell(v) {
			names++
		}
	}
	if ids >= maxInt(2, n*7/10) && names == 0 {
		return "id"
	}
	if names >= maxInt(1, n/2) {
		return "name"
	}
	return "other"
}

func looksIDCell(v interface{}) bool {
	if v == nil {
		return false
	}
	switch x := v.(type) {
	case int, int32, int64:
		return true
	case float64:
		return x == float64(int64(x))
	case string:
		s := strings.TrimSpace(x)
		if s == "" || len(s) > 12 {
			return false
		}
		for _, ch := range s {
			if ch < '0' || ch > '9' {
				return false
			}
		}
		return true
	}
	return false
}

func looksNameCell(v interface{}) bool {
	if v == nil {
		return false
	}
	s, ok := v.(string)
	if !ok {
		return false
	}
	s = strings.TrimSpace(s)
	if s == "" {
		return false
	}
	letters := 0
	for _, ch := range s {
		if (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') {
			letters++
		}
	}
	if letters < 2 {
		return false
	}
	return !looksIDCell(s)
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func (t *VerifySQLTool) checkRankingLimit(sql string) string {
	needs := t.contract != nil && t.contract.NeedsLimit
	if !needs {
		q, _ := splitQuestionEvidence(t.question)
		needs = reTopN.MatchString(q) || reNth.MatchString(q) || reMostLeast.MatchString(q)
	}
	if !needs {
		return ""
	}
	up := strings.ToUpper(sql)
	hasLimit := strings.Contains(up, " LIMIT ")
	hasOrder := strings.Contains(up, " ORDER BY ")
	switch {
	case !hasLimit && !hasOrder:
		return "⚠️  Ranking/top-N/Nth question but SQL has neither ORDER BY nor LIMIT. Add ORDER BY … LIMIT N (avoid WHERE col = (SELECT MAX…))."
	case !hasLimit:
		return "⚠️  Ranking question has ORDER BY but no LIMIT — add LIMIT to return only the requested top/Nth rows."
	}
	return ""
}

func (t *VerifySQLTool) emptyResultWarning(sql string) string {
	var b strings.Builder
	b.WriteString("⚠️  Query returned 0 rows — do NOT Final Answer yet. Retry checklist:\n")
	b.WriteString("  1) JOIN keys / table choice wrong?\n")
	b.WriteString("  2) WHERE too strict (case/spelling/extra filters)?\n")
	b.WriteString("  3) Call probe_column_values on filter columns to confirm stored literals.\n")
	q, ev := splitQuestionEvidence(t.question)
	lits := ExtractEvidenceLiterals(q, ev)
	if len(lits) > 0 {
		show := lits
		if len(show) > 6 {
			show = show[:6]
		}
		b.WriteString(fmt.Sprintf("  4) Evidence/question literals to probe or soften: %v\n", show))
		// Soft hint when literal appears in SQL but still 0 rows — likely dirty string mismatch.
		upSQL := strings.ToLower(sql)
		var missing []string
		for _, lit := range show {
			if !strings.Contains(upSQL, strings.ToLower(lit)) {
				missing = append(missing, lit)
			}
		}
		if len(missing) > 0 {
			b.WriteString(fmt.Sprintf("  5) These literals are NOT in the SQL yet — consider adding them (or their DB spelling): %v\n", missing))
		} else {
			b.WriteString("  5) Literals are present but matched 0 rows — probe for alternate spellings / case / punctuation.\n")
		}
	}
	return b.String()
}

// quickCheck quick static check
func (t *VerifySQLTool) quickCheck(sql string) error {
	// 1. Check illegal aliases (most common)
	if err := t.checkIllegalAliases(sql); err != nil {
		return err
	}

	// 2. Check parentheses matching
	if err := t.checkParentheses(sql); err != nil {
		return err
	}

	return nil
}

// checkIllegalAliases checks illegal aliases
func (t *VerifySQLTool) checkIllegalAliases(sql string) error {
	// Match AS followed by function-call aliases
	// e.g.: AS count(*), AS sum(*), AS max(*) etc.
	illegalAliasPattern := regexp.MustCompile(`(?i)\s+AS\s+([a-z_]+\s*\([^)]*\))`)

	matches := illegalAliasPattern.FindAllStringSubmatch(sql, -1)
	if len(matches) > 0 {
		aliases := make([]string, 0, len(matches))
		for _, match := range matches {
			if len(match) > 1 {
				aliases = append(aliases, match[1])
			}
		}
		return fmt.Errorf("illegal alias syntax: %v\nAliases cannot contain parentheses.\nUse simple names like 'total_count' instead of 'count(*)'", aliases)
	}

	return nil
}

// checkParentheses checks parentheses matching
func (t *VerifySQLTool) checkParentheses(sql string) error {
	stack := 0
	for i, char := range sql {
		if char == '(' {
			stack++
		} else if char == ')' {
			stack--
			if stack < 0 {
				return fmt.Errorf("unmatched closing parenthesis at position %d", i)
			}
		}
	}

	if stack > 0 {
		return fmt.Errorf("unmatched opening parenthesis: %d unclosed", stack)
	}

	return nil
}

// NewVerifySQLTool creates verification tool
func NewVerifySQLTool(adapter adapter.DBAdapter, dbType string) *VerifySQLTool {
	return &VerifySQLTool{
		adapter: adapter,
		dbType:  dbType,
	}
}

// checkDuplicateRows checks for duplicate rows
func (t *VerifySQLTool) checkDuplicateRows(rows [][]string) string {
	if len(rows) <= 2 { // no data rows or only one row
		return ""
	}

	seen := make(map[string]bool)
	dataRows := rows[1:] // Exclude header row

	for _, row := range dataRows {
		// Create unique key for row
		rowKey := strings.Join(row, "||<SEP>||")
		if seen[rowKey] {
			// Duplicate found
			return fmt.Sprintf("⚠️  The query returned duplicate rows (e.g., %v). If the question wants unique entities after a 1:N JOIN, add SELECT DISTINCT; if it wants all instances, keep duplicates.", row)
		}
		seen[rowKey] = true
	}

	return ""
}

// convertQueryResultFormat converts query result from map to 2D string array
func convertQueryResultFormat(data []map[string]interface{}) [][]string {
	if len(data) == 0 {
		return nil
	}

	var headers []string
	for key := range data[0] {
		headers = append(headers, key)
	}

	result := make([][]string, len(data)+1)
	result[0] = headers

	for i, row := range data {
		rowValues := make([]string, len(headers))
		for j, header := range headers {
			if val, ok := row[header]; ok {
				rowValues[j] = fmt.Sprintf("%v", val)
			} else {
				rowValues[j] = ""
			}
		}
		result[i+1] = rowValues
	}

	return result
}

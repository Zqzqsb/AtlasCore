package inference

import (
	"context"
	"fmt"
	"regexp"
	"strings"
)

var (
	quotedLiteralRe = regexp.MustCompile(`'([^']{1,80})'|"([^"]{1,80})"`)
	percentTokenRe  = regexp.MustCompile(`\b\d+(?:\.\d+)?\s*%`)
)

// ExpandTablesWithFK adds 1-hop FK neighbor tables (DeepEye recall bias: prefer over-include).
func ExpandTablesWithFK(selected []string, allTables map[string]*TableInfo) []string {
	if len(selected) == 0 || len(allTables) == 0 {
		return selected
	}
	set := map[string]struct{}{}
	var out []string
	add := func(name string) {
		if name == "" {
			return
		}
		if _, ok := allTables[name]; !ok {
			// case-insensitive fallback
			for k := range allTables {
				if strings.EqualFold(k, name) {
					name = k
					break
				}
			}
		}
		if _, ok := allTables[name]; !ok {
			return
		}
		if _, seen := set[name]; seen {
			return
		}
		set[name] = struct{}{}
		out = append(out, name)
	}
	for _, t := range selected {
		add(t)
	}
	// snapshot originals
	base := append([]string{}, out...)
	for _, t := range base {
		info, ok := allTables[t]
		if !ok {
			continue
		}
		for _, fk := range info.ForeignKeys {
			add(fk.ReferencedTable)
		}
	}
	// reverse: tables that reference selected tables
	for name, info := range allTables {
		if _, already := set[name]; already {
			continue
		}
		for _, fk := range info.ForeignKeys {
			if _, hit := set[fk.ReferencedTable]; hit {
				add(name)
				break
			}
		}
	}
	return out
}

// ExtractEvidenceLiterals pulls quoted strings and percent tokens for probe hints.
func ExtractEvidenceLiterals(question, evidence string) []string {
	text := question + "\n" + evidence
	seen := map[string]struct{}{}
	var out []string
	add := func(s string) {
		s = strings.TrimSpace(s)
		if s == "" || len(s) > 80 {
			return
		}
		// skip pure numbers / tiny tokens
		if len(s) < 2 {
			return
		}
		key := strings.ToLower(s)
		if _, ok := seen[key]; ok {
			return
		}
		seen[key] = struct{}{}
		out = append(out, s)
	}
	for _, m := range quotedLiteralRe.FindAllStringSubmatch(text, -1) {
		if m[1] != "" {
			add(m[1])
		} else if m[2] != "" {
			add(m[2])
		}
	}
	for _, m := range percentTokenRe.FindAllString(text, -1) {
		add(m)
	}
	if len(out) > 12 {
		out = out[:12]
	}
	return out
}

// FormatEvidenceLiteralHints builds a prompt block listing literals to verify via probe.
func FormatEvidenceLiteralHints(literals []string) string {
	if len(literals) == 0 {
		return ""
	}
	var b strings.Builder
	b.WriteString("## Value Probe Hints (from question/evidence)\n")
	b.WriteString("Before using these as WHERE literals, call probe_column_values on the likely column to confirm exact stored form (case, punctuation, dirty values):\n")
	for _, lit := range literals {
		b.WriteString(fmt.Sprintf("- %q\n", lit))
	}
	b.WriteString("\n")
	return b.String()
}

// RefineRelevantColumns asks the LLM for question-relevant columns + short hints
// (WiseCat RelevantColumns lite — no vector store).
func (p *Pipeline) RefineRelevantColumns(ctx context.Context, query string, tables []string, allTables map[string]*TableInfo) (string, error) {
	if len(tables) == 0 {
		return "", nil
	}
	var schema strings.Builder
	for _, name := range tables {
		info, ok := allTables[name]
		if !ok {
			continue
		}
		schema.WriteString(fmt.Sprintf("- %s: %s\n", name, strings.Join(info.Columns, ", ")))
		if info.Description != "" {
			schema.WriteString(fmt.Sprintf("  desc: %s\n", info.Description))
		}
	}

	prompt := fmt.Sprintf(`You are a schema linker. Given a question and candidate tables/columns, list ONLY columns needed to answer (filters, joins, projections, evidence formulas).

Tables:
%s
Question: %s

Output STRICTLY one column per line as:
table.column | short hint why needed

Rules:
- Prefer over-including join keys / evidence-mapped columns
- No SQL, no markdown, no extra commentary
- Max 20 lines

Output:`, schema.String(), query)

	resp, err := p.llm.Call(ctx, prompt)
	if err != nil {
		return "", err
	}
	p.promptTexts = append(p.promptTexts, prompt)
	p.responseTexts = append(p.responseTexts, resp)

	lines := parseRelevantColumnLines(resp, tables, allTables)
	if len(lines) == 0 {
		return "", nil
	}
	var b strings.Builder
	b.WriteString("## Relevant Columns (linker refine)\n")
	b.WriteString("Prefer these columns for filters/joins/projection; still verify values with probe when literals are uncertain:\n")
	for _, ln := range lines {
		b.WriteString(ln)
		b.WriteString("\n")
	}
	b.WriteString("\n")
	return b.String(), nil
}

func parseRelevantColumnLines(resp string, tables []string, allTables map[string]*TableInfo) []string {
	tableSet := map[string]struct{}{}
	for _, t := range tables {
		tableSet[strings.ToLower(t)] = struct{}{}
	}
	colOK := func(table, col string) bool {
		info, ok := allTables[table]
		if !ok {
			for k, v := range allTables {
				if strings.EqualFold(k, table) {
					info, ok = v, true
					table = k
					break
				}
			}
		}
		if !ok {
			return false
		}
		for _, c := range info.Columns {
			if strings.EqualFold(c, col) {
				return true
			}
		}
		return false
	}

	var out []string
	seen := map[string]struct{}{}
	for _, line := range strings.Split(resp, "\n") {
		line = strings.TrimSpace(line)
		line = strings.TrimPrefix(line, "- ")
		line = strings.TrimPrefix(line, "* ")
		if line == "" || strings.HasPrefix(strings.ToLower(line), "output") {
			continue
		}
		parts := strings.SplitN(line, "|", 2)
		left := strings.TrimSpace(parts[0])
		hint := ""
		if len(parts) == 2 {
			hint = strings.TrimSpace(parts[1])
		}
		left = strings.ReplaceAll(left, "`", "")
		segs := strings.Split(left, ".")
		if len(segs) != 2 {
			continue
		}
		table, col := strings.TrimSpace(segs[0]), strings.TrimSpace(segs[1])
		if _, ok := tableSet[strings.ToLower(table)]; !ok {
			continue
		}
		if !colOK(table, col) {
			continue
		}
		key := strings.ToLower(table + "." + col)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		if hint != "" {
			out = append(out, fmt.Sprintf("- %s.%s | %s", table, col, hint))
		} else {
			out = append(out, fmt.Sprintf("- %s.%s", table, col))
		}
		if len(out) >= 20 {
			break
		}
	}
	return out
}

// ApplyLinkEnhance expands FK neighbors, refines columns, injects evidence literal hints.
// Returns possibly expanded tables and an extra context block to append.
func (p *Pipeline) ApplyLinkEnhance(ctx context.Context, query string, tables []string, allTables map[string]*TableInfo) (expanded []string, inject string, err error) {
	expanded = ExpandTablesWithFK(tables, allTables)
	if len(expanded) > len(tables) {
		p.Logger.Printf("🔗 FK expand: %v → %v\n", tables, expanded)
	}

	qOnly, evOnly := splitQuestionEvidence(query)
	literals := ExtractEvidenceLiterals(qOnly, evOnly)
	var parts []string
	if block := FormatEvidenceLiteralHints(literals); block != "" {
		parts = append(parts, block)
	}

	colBlock, refineErr := p.RefineRelevantColumns(ctx, query, expanded, allTables)
	if refineErr != nil {
		p.Logger.Printf("⚠️  column refine failed: %v\n", refineErr)
	} else if colBlock != "" {
		parts = append(parts, colBlock)
		p.Logger.Printf("📌 Relevant columns refine injected (%d chars)\n", len(colBlock))
	}

	if p.config.DraftMineN > 0 {
		draftBlock, draftErr := p.MineColumnsFromDraftSQL(ctx, query, expanded, allTables, p.config.DraftMineN)
		if draftErr != nil {
			p.Logger.Printf("⚠️  draft column mine failed: %v\n", draftErr)
		} else if draftBlock != "" {
			parts = append(parts, draftBlock)
			p.Logger.Printf("⛏️  Draft-SQL column mine injected (%d chars)\n", len(draftBlock))
		}
	}

	return expanded, strings.Join(parts, ""), nil
}

var sqlIdentRe = regexp.MustCompile(`(?i)(?:\b([A-Za-z_][\w]*)\.)?([A-Za-z_][\w]*)\b`)

var sqlKeywords = map[string]struct{}{
	"select": {}, "from": {}, "where": {}, "join": {}, "inner": {}, "left": {}, "right": {},
	"outer": {}, "on": {}, "and": {}, "or": {}, "not": {}, "in": {}, "as": {},
	"group": {}, "by": {}, "order": {}, "limit": {}, "offset": {}, "having": {}, "distinct": {},
	"count": {}, "sum": {}, "avg": {}, "min": {}, "max": {}, "cast": {}, "case": {}, "when": {},
	"then": {}, "else": {}, "end": {}, "null": {}, "is": {}, "between": {}, "like": {},
	"union": {}, "all": {}, "exists": {}, "with": {}, "asc": {}, "desc": {}, "real": {},
	"integer": {}, "text": {}, "coalesce": {}, "substr": {}, "length": {}, "trim": {},
	"upper": {}, "lower": {}, "round": {}, "abs": {}, "ifnull": {}, "true": {}, "false": {},
}

// MineColumnsFromDraftSQL asks the model for draft SQL (not used as answer) and
// collects referenced columns for high-recall linking (AskData task alignment).
func (p *Pipeline) MineColumnsFromDraftSQL(
	ctx context.Context,
	query string,
	tables []string,
	allTables map[string]*TableInfo,
	n int,
) (string, error) {
	if n <= 0 || len(tables) == 0 {
		return "", nil
	}
	if n > 2 {
		n = 2
	}

	var schema strings.Builder
	for _, name := range tables {
		info, ok := allTables[name]
		if !ok {
			continue
		}
		schema.WriteString(fmt.Sprintf("- %s(%s)\n", name, strings.Join(info.Columns, ", ")))
	}

	prompt := fmt.Sprintf(`Write %d draft SQLite SELECT queries that could answer the question.
They may be imperfect — purpose is only to reveal which columns you would touch.
Use ONLY these tables/columns:

%s
Question: %s

Rules:
- Output ONLY SQL, one statement per draft, separated by a line with --- 
- No markdown fences, no commentary
- Prefer including join keys and evidence-mapped columns

Drafts:`, n, schema.String(), query)

	resp, err := p.llm.Call(ctx, prompt)
	if err != nil {
		return "", err
	}
	p.promptTexts = append(p.promptTexts, prompt)
	p.responseTexts = append(p.responseTexts, resp)

	cols := parseColumnsFromDraftSQL(resp, tables, allTables)
	if len(cols) == 0 {
		return "", nil
	}
	var b strings.Builder
	b.WriteString("## Relevant Columns (draft-SQL mine)\n")
	b.WriteString("Recovered from draft SQL (drafts discarded — do NOT copy them). Prefer these for filters/joins/projection:\n")
	for _, c := range cols {
		b.WriteString(fmt.Sprintf("- %s\n", c))
	}
	b.WriteString("\n")
	return b.String(), nil
}

func parseColumnsFromDraftSQL(resp string, tables []string, allTables map[string]*TableInfo) []string {
	// Resolve table names case-insensitively
	canonTable := map[string]string{}
	colToTables := map[string][]string{} // lower col -> possible tables
	for _, t := range tables {
		info, ok := allTables[t]
		if !ok {
			for k, v := range allTables {
				if strings.EqualFold(k, t) {
					info, ok = v, true
					t = k
					break
				}
			}
		}
		if !ok {
			continue
		}
		canonTable[strings.ToLower(t)] = t
		for _, c := range info.Columns {
			cl := strings.ToLower(c)
			colToTables[cl] = append(colToTables[cl], t)
		}
	}

	seen := map[string]struct{}{}
	var out []string
	add := func(table, col string) {
		key := strings.ToLower(table + "." + col)
		if _, ok := seen[key]; ok {
			return
		}
		seen[key] = struct{}{}
		out = append(out, table+"."+col)
	}

	cleaned := strings.ReplaceAll(resp, "`", "")
	cleaned = strings.ReplaceAll(cleaned, "\"", "")
	cleaned = strings.ReplaceAll(cleaned, "[", "")
	cleaned = strings.ReplaceAll(cleaned, "]", "")

	for _, m := range sqlIdentRe.FindAllStringSubmatch(cleaned, -1) {
		qual, ident := m[1], m[2]
		il := strings.ToLower(ident)
		if _, kw := sqlKeywords[il]; kw {
			continue
		}
		resolvedTable := ""
		if qual != "" {
			tl := strings.ToLower(qual)
			if _, kw := sqlKeywords[tl]; kw {
				continue
			}
			if t, ok := canonTable[tl]; ok {
				resolvedTable = t
			}
			// else: table alias — resolve by column name below
		}
		if resolvedTable != "" {
			info := allTables[resolvedTable]
			for _, c := range info.Columns {
				if strings.EqualFold(c, ident) {
					add(resolvedTable, c)
					break
				}
			}
			continue
		}
		// bare column or alias.column: unique → take it; ambiguous → take all (recall bias)
		cands := colToTables[il]
		if len(cands) == 1 {
			info := allTables[cands[0]]
			for _, c := range info.Columns {
				if strings.EqualFold(c, ident) {
					add(cands[0], c)
					break
				}
			}
		} else if len(cands) > 1 && qual != "" {
			// alias.col with ambiguous name — include all tables that have it
			for _, t := range cands {
				info := allTables[t]
				for _, c := range info.Columns {
					if strings.EqualFold(c, ident) {
						add(t, c)
						break
					}
				}
			}
		}
	}
	if len(out) > 30 {
		out = out[:30]
	}
	return out
}

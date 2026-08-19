package inference

import (
	"context"
	"fmt"
	"regexp"
	"sort"
	"strings"
	"unicode"

	"github.com/Zqzqsb/AtlasCore/internal/valueindex"
)

var (
	quotedLiteralRe = regexp.MustCompile(`'([^']{1,80})'|"([^"]{1,80})"`)
	percentTokenRe  = regexp.MustCompile(`\b\d+(?:\.\d+)?\s*%`)
)

func resolveTableName(name string, allTables map[string]*TableInfo) string {
	if name == "" || len(allTables) == 0 {
		return ""
	}
	if _, ok := allTables[name]; ok {
		return name
	}
	for k := range allTables {
		if strings.EqualFold(k, name) {
			return k
		}
	}
	return ""
}

// ExpandTablesWithFK adds 1-hop parent tables (child → referenced parent).
// Does not reverse-expand children of a selected table (that floods SQL-gen).
func ExpandTablesWithFK(selected []string, allTables map[string]*TableInfo) []string {
	if len(selected) == 0 || len(allTables) == 0 {
		return selected
	}
	set := map[string]struct{}{}
	var out []string
	add := func(name string) {
		name = resolveTableName(name, allTables)
		if name == "" {
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
	return out
}

const maxHomonymHistoryAdd = 4

func isHistoryTableName(name string) bool {
	return strings.Contains(strings.ToLower(name), "history")
}

func skipHomonymColumn(name string) bool {
	n := strings.ToLower(strings.TrimSpace(name))
	if n == "" {
		return true
	}
	compact := strings.Map(func(r rune) rune {
		if r == '_' || r == ' ' || r == '-' {
			return -1
		}
		return unicode.ToLower(r)
	}, n)
	switch compact {
	case "id", "name", "title", "type", "status", "description", "comment", "notes",
		"date", "time", "datetime", "timestamp", "created", "createdat", "updated",
		"updatedat", "modifieddate", "lastupdate", "createdate":
		return true
	}
	if n == "id" || strings.HasSuffix(n, "_id") || strings.HasSuffix(compact, "id") {
		return true
	}
	alnum := 0
	for _, r := range compact {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			alnum++
		}
	}
	return alnum < 5
}

func distinctiveColumns(info *TableInfo) map[string]string {
	out := map[string]string{}
	if info == nil {
		return out
	}
	fkCols := map[string]struct{}{}
	for _, fk := range info.ForeignKeys {
		fkCols[strings.ToLower(strings.TrimSpace(fk.ColumnName))] = struct{}{}
	}
	for _, col := range info.Columns {
		lc := strings.ToLower(strings.TrimSpace(col))
		if lc == "" {
			continue
		}
		if _, isFK := fkCols[lc]; isFK {
			continue
		}
		if skipHomonymColumn(col) {
			continue
		}
		out[lc] = col
	}
	return out
}

// ExpandHomonymHistoryTables adds *History children that share a distinctive
// non-key column with a selected parent (e.g. Product.StandardCost vs
// ProductCostHistory.StandardCost). Does not reverse-expand all children.
func ExpandHomonymHistoryTables(selected []string, allTables map[string]*TableInfo) []string {
	if len(selected) == 0 || len(allTables) == 0 {
		return selected
	}
	set := map[string]struct{}{}
	out := make([]string, 0, len(selected)+maxHomonymHistoryAdd)
	parentCols := map[string]string{}
	for _, t := range selected {
		name := resolveTableName(t, allTables)
		if name == "" {
			continue
		}
		if _, seen := set[name]; seen {
			continue
		}
		set[name] = struct{}{}
		out = append(out, name)
		for lc, orig := range distinctiveColumns(allTables[name]) {
			if _, ok := parentCols[lc]; !ok {
				parentCols[lc] = orig
			}
		}
	}
	if len(parentCols) == 0 {
		return out
	}

	type cand struct{ name string }
	var cands []cand
	for childName, child := range allTables {
		if _, seen := set[childName]; seen {
			continue
		}
		if !isHistoryTableName(childName) {
			continue
		}
		parentHit := false
		for _, fk := range child.ForeignKeys {
			ref := resolveTableName(fk.ReferencedTable, allTables)
			if _, ok := set[ref]; ok {
				parentHit = true
				break
			}
		}
		if !parentHit {
			continue
		}
		shared := false
		for lc := range distinctiveColumns(child) {
			if _, ok := parentCols[lc]; ok {
				shared = true
				break
			}
		}
		if !shared {
			continue
		}
		cands = append(cands, cand{name: childName})
	}
	sort.Slice(cands, func(i, j int) bool { return cands[i].name < cands[j].name })
	added := 0
	for _, c := range cands {
		if added >= maxHomonymHistoryAdd {
			break
		}
		if _, seen := set[c.name]; seen {
			continue
		}
		set[c.name] = struct{}{}
		out = append(out, c.name)
		added++
	}
	return out
}

// FormatHomonymColumnHints lists distinctive column names that appear on more
// than one table in the (expanded) set. Neutral: snapshot vs row history.
func FormatHomonymColumnHints(tables []string, allTables map[string]*TableInfo) string {
	if len(tables) < 2 || len(allTables) == 0 {
		return ""
	}
	owners := map[string][]string{}
	origCol := map[string]string{}
	seenTable := map[string]struct{}{}
	for _, t := range tables {
		name := resolveTableName(t, allTables)
		if name == "" {
			continue
		}
		if _, dup := seenTable[name]; dup {
			continue
		}
		seenTable[name] = struct{}{}
		for lc, orig := range distinctiveColumns(allTables[name]) {
			origCol[lc] = orig
			owners[lc] = append(owners[lc], name)
		}
	}
	var cols []string
	for lc, ts := range owners {
		if len(ts) >= 2 {
			cols = append(cols, lc)
		}
	}
	if len(cols) == 0 {
		return ""
	}
	sort.Strings(cols)
	if len(cols) > 8 {
		cols = cols[:8]
	}
	var b strings.Builder
	b.WriteString("## Homonym columns\n")
	b.WriteString("These names exist on more than one related table (often a current snapshot vs row-level *History). They are not interchangeable:\n")
	for _, lc := range cols {
		ts := append([]string{}, owners[lc]...)
		sort.Strings(ts)
		b.WriteString(fmt.Sprintf("- %s: %s\n", origCol[lc], strings.Join(ts, ", ")))
	}
	b.WriteString("\n")
	return b.String()
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
func (p *Pipeline) RefineRelevantColumns(ctx context.Context, query string, tables []string, allTables map[string]*TableInfo) (string, map[string]struct{}, error) {
	if len(tables) == 0 {
		return "", nil, nil
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
		return "", nil, err
	}
	p.promptTexts = append(p.promptTexts, prompt)
	p.responseTexts = append(p.responseTexts, resp)

	lines := parseRelevantColumnLines(resp, tables, allTables)
	if len(lines) == 0 {
		return "", nil, nil
	}
	relevant := relevantColumnSet(lines)
	var b strings.Builder
	b.WriteString("## Relevant Columns (linker refine)\n")
	b.WriteString("Prefer these columns for filters/joins/projection; still verify values with probe when literals are uncertain:\n")
	for _, ln := range lines {
		b.WriteString(ln)
		b.WriteString("\n")
	}
	b.WriteString("\n")
	return b.String(), relevant, nil
}

func relevantColumnSet(lines []string) map[string]struct{} {
	out := make(map[string]struct{})
	for _, line := range lines {
		line = strings.TrimSpace(strings.TrimPrefix(line, "- "))
		left := strings.TrimSpace(strings.SplitN(line, "|", 2)[0])
		left = strings.ReplaceAll(left, "`", "")
		parts := strings.Split(left, ".")
		if len(parts) != 2 {
			continue
		}
		key := strings.ToLower(strings.TrimSpace(parts[0]) + "." + strings.TrimSpace(parts[1]))
		if key != "." {
			out[key] = struct{}{}
		}
	}
	return out
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

// ApplyLinkEnhance expands FK neighbors, refines columns, injects evidence literal hints
// and (when present) business-value inverted-index matches.
// Returns expanded tables, an extra context block, and validated relevant columns.
func (p *Pipeline) ApplyLinkEnhance(ctx context.Context, query string, tables []string, allTables map[string]*TableInfo) (expanded []string, inject string, relevant map[string]struct{}, err error) {
	expanded = ExpandTablesWithFK(tables, allTables)
	if len(expanded) > len(tables) {
		p.Logger.Printf("🔗 FK expand (parents): %v → %v\n", tables, expanded)
	}
	if hist := ExpandHomonymHistoryTables(expanded, allTables); len(hist) > len(expanded) {
		p.Logger.Printf("🔗 Homonym *History expand: %v → %v\n", expanded, hist)
		expanded = hist
	}

	qOnly, evOnly := splitQuestionEvidence(query)
	literals := ExtractEvidenceLiterals(qOnly, evOnly)
	eavQueries := append([]string{}, literals...)
	var parts []string
	if block := FormatHomonymColumnHints(expanded, allTables); block != "" {
		parts = append(parts, block)
	}

	// Value index: high-precision positive evidence only.
	// Hits are restricted to linker-selected + FK-expanded tables — never expand
	// the table set from noisy index matches.
	if hits, lerr := p.LookupValueIndexHits(ctx, qOnly, evOnly); lerr != nil {
		p.Logger.Printf("⚠️  value index lookup failed: %v\n", lerr)
	} else if len(hits) > 0 {
		rawN := len(hits)
		hits = filterHitsByAllowedTables(hits, expanded)
		if len(hits) > 0 {
			if block := valueindex.FormatHitsCompact(hits); block != "" {
				parts = append(parts, block+"\n")
			}
			p.Logger.Printf("🔎 Value index exact/strong hits=%d (raw=%d, in-schema only; no table expand)\n",
				len(hits), rawN)
			literals = filterLiteralsWithoutExactHit(literals, hits)
			for _, h := range hits {
				eavQueries = append(eavQueries, h.DisplayValue, h.MatchedText)
			}
		} else if rawN > 0 {
			p.Logger.Printf("🔎 Value index raw hits=%d dropped (outside selected/FK tables)\n", rawN)
		}
	}

	if p.context != nil {
		if block := p.context.FormatMatchedEAV(expanded, eavQueries); block != "" {
			parts = append(parts, block+"\n")
			p.Logger.Printf("🔑 EAV matched keys injected (%d chars)\n", len(block))
		}
	}

	if block := FormatEvidenceLiteralHints(literals); block != "" {
		parts = append(parts, block)
	}

	colBlock, relevant, refineErr := p.RefineRelevantColumns(ctx, query, expanded, allTables)
	if refineErr != nil {
		p.Logger.Printf("⚠️  column refine failed: %v\n", refineErr)
	} else if colBlock != "" {
		parts = append(parts, colBlock)
		p.Logger.Printf("📌 Relevant columns refine injected (%d chars)\n", len(colBlock))
	}

	return expanded, strings.Join(parts, ""), relevant, nil
}

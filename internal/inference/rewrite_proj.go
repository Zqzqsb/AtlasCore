package inference

import (
	"regexp"
	"strings"
)

var (
	reSelectHead = regexp.MustCompile(`(?is)^\s*(SELECT(?:\s+DISTINCT)?)\s+`)
	reOrderBy    = regexp.MustCompile(`(?i)\bORDER\s+BY\s+`)
	reLimitKW    = regexp.MustCompile(`(?i)\bLIMIT\b`)
	reAsAlias    = regexp.MustCompile(`(?i)\s+AS\s+("?[A-Za-z_][\w]*"?)?\s*$`)
	reAggFn      = regexp.MustCompile(`(?i)\b(COUNT|SUM|AVG|AVERAGE|MIN|MAX)\s*\(`)
	reFirstTok   = regexp.MustCompile(`(?i)(^|[.\s"\[])(first(?:_?name)?|fname|f_name)($|[.\s"\]])`)
	reLastTok    = regexp.MustCompile(`(?i)(^|[.\s"\[])(last(?:_?name)?|lname|l_name)($|[.\s"\]])`)
	reMetricOnly = regexp.MustCompile(`(?i)^\s*(what is|what's|whats)\s+(the\s+)?(average|avg|max|min|maximum|minimum|highest|lowest|percentage|percent|total|sum)\b`)
)

// SanitizeGeneratedSQLWithQuery applies dialect rewrites plus gold-free projection fixes:
// split first||last full-name concat, and drop ORDER BY metric leaked into SELECT.
func SanitizeGeneratedSQLWithQuery(sql, question, evidence string) string {
	sql = SanitizeGeneratedSQL(sql)
	sql = splitConcatenatedPersonName(sql)
	sql = dropRankingMetricFromSelect(sql, question, evidence)
	return strings.TrimSpace(sql)
}

func splitConcatenatedPersonName(sql string) string {
	head, list, rest, ok := splitSelectList(sql)
	if !ok || len(list) == 0 {
		return sql
	}
	var out []string
	changed := false
	for _, item := range list {
		parts, did := expandNameConcatItem(item)
		if did {
			changed = true
			out = append(out, parts...)
		} else {
			out = append(out, item)
		}
	}
	if !changed {
		return sql
	}
	return head + " " + strings.Join(out, ", ") + " " + rest
}

func expandNameConcatItem(item string) ([]string, bool) {
	raw := strings.TrimSpace(item)
	expr := stripSelectAlias(raw)
	if !strings.Contains(expr, "||") && !regexp.MustCompile(`(?i)\bconcat\s*\(`).MatchString(expr) {
		return nil, false
	}
	if !reFirstTok.MatchString(expr) || !reLastTok.MatchString(expr) {
		return nil, false
	}
	idents := extractConcatPieces(expr)
	var first, last string
	for _, p := range idents {
		lp := strings.ToLower(p)
		if first == "" && reFirstTok.MatchString(lp) {
			first = strings.TrimSpace(p)
		}
		if reLastTok.MatchString(lp) {
			last = strings.TrimSpace(p)
		}
	}
	if first == "" || last == "" || first == last {
		return nil, false
	}
	return []string{first, last}, true
}

func extractConcatPieces(expr string) []string {
	expr = strings.TrimSpace(expr)
	if m := regexp.MustCompile(`(?i)^concat\s*\(`).FindStringIndex(expr); m != nil {
		args, _, ok := splitCallArgs(expr, m[1])
		if ok {
			var out []string
			for _, a := range args {
				a = strings.TrimSpace(a)
				if isSQLStringLiteral(a) {
					continue
				}
				out = append(out, a)
			}
			return out
		}
	}
	var out []string
	for _, p := range strings.Split(expr, "||") {
		p = strings.TrimSpace(p)
		if p == "" || isSQLStringLiteral(p) {
			continue
		}
		out = append(out, p)
	}
	return out
}

func isSQLStringLiteral(s string) bool {
	s = strings.TrimSpace(s)
	return len(s) >= 2 && s[0] == '\'' && s[len(s)-1] == '\''
}

func dropRankingMetricFromSelect(sql, question, evidence string) string {
	if !wantsEntityNotMetric(question, evidence) {
		return sql
	}
	head, list, rest, ok := splitSelectList(sql)
	if !ok || len(list) != 2 {
		return sql
	}
	ob := reOrderBy.FindStringIndex(rest)
	lim := reLimitKW.FindStringIndex(rest)
	if ob == nil || lim == nil || lim[0] < ob[0] {
		return sql
	}
	orderExpr := strings.TrimSpace(rest[ob[1]:lim[0]])
	orderExpr = stripOrderDirection(orderExpr)
	// ORDER BY 2 → second select item
	ent, metric := strings.TrimSpace(list[0]), strings.TrimSpace(list[1])
	if reAggFn.MatchString(ent) && !reAggFn.MatchString(metric) {
		return sql // entity should be first
	}
	if !isRankingMetricItem(metric, orderExpr) {
		return sql
	}
	return head + " " + ent + " " + rest
}

func wantsEntityNotMetric(question, evidence string) bool {
	q := question
	if strings.TrimSpace(q) == "" {
		return false
	}
	if asksMultipleOutputAttrs(q, evidence) {
		return false
	}
	if reHowMany.MatchString(q) && !reWhichWho.MatchString(q) && !reTopN.MatchString(q) {
		return false
	}
	if reMetricOnly.MatchString(q) && !reWhichWho.MatchString(q) {
		return false
	}
	return reWhichWho.MatchString(q) || reTopN.MatchString(q) || reMostLeast.MatchString(q)
}

func isRankingMetricItem(item, orderExpr string) bool {
	expr := stripSelectAlias(item)
	alias := selectAlias(item)
	ord := normalizeSQLIdent(orderExpr)
	if ord == "2" {
		return true
	}
	if alias != "" && normalizeSQLIdent(alias) == ord {
		return true
	}
	if normalizeSQLIdent(expr) == ord {
		return true
	}
	// COUNT(*) / SUM(...) in SELECT and ORDER BY COUNT(*) / same fn
	if reAggFn.MatchString(expr) && (reAggFn.MatchString(orderExpr) || ord == normalizeSQLIdent(expr)) {
		return true
	}
	return false
}

func stripOrderDirection(s string) string {
	s = strings.TrimSpace(s)
	// first ordering term only
	s = splitTopLevel(s, ",")[0]
	s = strings.TrimSpace(s)
	s = regexp.MustCompile(`(?i)\s+(ASC|DESC)\s*$`).ReplaceAllString(s, "")
	return strings.TrimSpace(s)
}

func stripSelectAlias(item string) string {
	item = strings.TrimSpace(item)
	loc := reAsAlias.FindStringIndex(item)
	if loc != nil {
		return strings.TrimSpace(item[:loc[0]])
	}
	return item
}

func selectAlias(item string) string {
	m := reAsAlias.FindStringSubmatch(item)
	if len(m) > 1 {
		return strings.Trim(m[1], `"`)
	}
	return ""
}

func splitSelectList(sql string) (head string, items []string, rest string, ok bool) {
	hm := reSelectHead.FindStringIndex(sql)
	if hm == nil {
		return "", nil, "", false
	}
	from := findKeywordFrom(sql[hm[1]:])
	if from < 0 {
		return "", nil, "", false
	}
	from += hm[1]
	head = strings.TrimSpace(sql[:hm[1]])
	list := strings.TrimSpace(sql[hm[1]:from])
	rest = strings.TrimSpace(sql[from:])
	items = splitTopLevel(list, ",")
	for i := range items {
		items[i] = strings.TrimSpace(items[i])
	}
	return head, items, rest, len(items) > 0
}

func findKeywordFrom(s string) int {
	depth := 0
	inS, inD := false, false
	for i := 0; i < len(s); i++ {
		ch := s[i]
		switch {
		case ch == '\'' && !inD:
			if inS && i+1 < len(s) && s[i+1] == '\'' {
				i++
				continue
			}
			inS = !inS
		case ch == '"' && !inS:
			inD = !inD
		case inS || inD:
			continue
		case ch == '(':
			depth++
		case ch == ')':
			if depth > 0 {
				depth--
			}
		case depth == 0 && i+4 <= len(s) && strings.EqualFold(s[i:i+4], "FROM") &&
			(i == 0 || isIdentBreak(s[i-1])) && (i+4 == len(s) || isIdentBreak(s[i+4])):
			return i
		}
	}
	return -1
}

func isIdentBreak(b byte) bool {
	return b == ' ' || b == '\n' || b == '\t' || b == '\r' || b == '(' || b == ')'
}

func splitTopLevel(s, sep string) []string {
	var out []string
	depth := 0
	inS, inD := false, false
	start := 0
	for i := 0; i < len(s); i++ {
		ch := s[i]
		switch {
		case ch == '\'' && !inD:
			if inS && i+1 < len(s) && s[i+1] == '\'' {
				i++
				continue
			}
			inS = !inS
		case ch == '"' && !inS:
			inD = !inD
		case inS || inD:
			continue
		case ch == '(':
			depth++
		case ch == ')':
			if depth > 0 {
				depth--
			}
		case depth == 0 && strings.HasPrefix(s[i:], sep):
			out = append(out, s[start:i])
			i += len(sep) - 1
			start = i + 1
		}
	}
	out = append(out, s[start:])
	return out
}

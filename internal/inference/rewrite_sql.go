package inference

import (
	"fmt"
	"regexp"
	"strings"
	"unicode"
)

var (
	reRightJoin = regexp.MustCompile(`(?i)\bRIGHT\s+(OUTER\s+)?JOIN\b`)
	reFullJoin  = regexp.MustCompile(`(?i)\bFULL\s+(OUTER\s+)?JOIN\b`)
)

// SanitizeGeneratedSQL applies deterministic SQLite-safe rewrites before execute/score.
// - IIF(cond,a,b) → CASE WHEN cond THEN a ELSE b END (SQLite <3.32)
// - RIGHT/FULL JOIN → LEFT JOIN (unsupported in SQLite)
func SanitizeGeneratedSQL(sql string) string {
	sql = strings.TrimSpace(sql)
	if sql == "" {
		return sql
	}
	sql = rewriteIIFCalls(sql)
	sql = rewriteJoinsOutsideQuotes(sql)
	return strings.TrimSpace(sql)
}

func rewriteJoinsOutsideQuotes(sql string) string {
	// Cheap path: BIRD preds rarely put JOIN keywords inside literals.
	sql = reRightJoin.ReplaceAllString(sql, "LEFT JOIN")
	sql = reFullJoin.ReplaceAllString(sql, "LEFT JOIN")
	return sql
}

func rewriteIIFCalls(sql string) string {
	var b strings.Builder
	inS, inD := false, false
	i := 0
	for i < len(sql) {
		ch := sql[i]
		switch {
		case ch == '\'' && !inD:
			if inS && i+1 < len(sql) && sql[i+1] == '\'' {
				b.WriteByte(ch)
				b.WriteByte(sql[i+1])
				i += 2
				continue
			}
			inS = !inS
			b.WriteByte(ch)
			i++
		case ch == '"' && !inS:
			inD = !inD
			b.WriteByte(ch)
			i++
		case inS || inD:
			b.WriteByte(ch)
			i++
		default:
			if i+4 <= len(sql) && strings.EqualFold(sql[i:i+4], "iif(") {
				if i > 0 {
					r := rune(sql[i-1])
					if unicode.IsLetter(r) || unicode.IsDigit(r) || r == '_' {
						b.WriteByte(ch)
						i++
						continue
					}
				}
				args, end, ok := splitCallArgs(sql, i+4)
				if ok && len(args) == 3 {
					fmt.Fprintf(&b, "CASE WHEN %s THEN %s ELSE %s END",
						strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]))
					i = end
					continue
				}
			}
			b.WriteByte(ch)
			i++
		}
	}
	return b.String()
}

// splitCallArgs parses comma-separated args starting just after '('.
// Returns args, index after closing ')', and ok.
func splitCallArgs(sql string, start int) ([]string, int, bool) {
	var args []string
	depth := 1
	inS, inD := false, false
	argStart := start
	for i := start; i < len(sql); i++ {
		ch := sql[i]
		switch {
		case ch == '\'' && !inD:
			if inS && i+1 < len(sql) && sql[i+1] == '\'' {
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
			depth--
			if depth == 0 {
				args = append(args, sql[argStart:i])
				return args, i + 1, true
			}
		case ch == ',' && depth == 1:
			args = append(args, sql[argStart:i])
			argStart = i + 1
		}
	}
	return nil, start, false
}

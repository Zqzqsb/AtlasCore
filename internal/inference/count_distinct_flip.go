package inference

import (
	"regexp"
	"strings"
)

var (
	reCountOpen    = regexp.MustCompile(`(?i)\bCOUNT\s*\(`)
	reDistinctLead = regexp.MustCompile(`(?i)^\s*DISTINCT\s+`)
	reStarArg      = regexp.MustCompile(`(?i)^\s*\*\s*$`)
)

// flipCountDistinct toggles DISTINCT inside the single COUNT(...) of sql.
// COUNT(*) and SQL with multiple COUNT calls are left unchanged.
func flipCountDistinct(sql string) (string, bool) {
	locs := reCountOpen.FindAllStringIndex(sql, -1)
	if len(locs) != 1 {
		return "", false
	}
	startArgs := locs[0][1]
	args, end, ok := splitCallArgs(sql, startArgs)
	if !ok || len(args) != 1 {
		return "", false
	}
	arg := args[0]
	if reStarArg.MatchString(arg) {
		return "", false
	}
	var newArg string
	if reDistinctLead.MatchString(arg) {
		newArg = strings.TrimLeft(reDistinctLead.ReplaceAllString(arg, ""), " \t\n\r")
	} else {
		newArg = "DISTINCT " + strings.TrimLeft(arg, " \t\n\r")
	}
	return sql[:startArgs] + newArg + sql[end-1:], true
}

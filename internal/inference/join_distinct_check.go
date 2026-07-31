package inference

import (
	"fmt"
	"regexp"
	"strings"

	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
)

// JoinCardHint is a compact 1:N / N:1 edge used by verify_sql.
type JoinCardHint struct {
	ChildTable    string
	ParentTable   string
	ChildColumn   string
	ParentToChild string  // "1:N" etc.
	AvgChildren   float64
}

var (
	reSQLJoin      = regexp.MustCompile(`(?i)\bjoin\b`)
	reSQLDistinct  = regexp.MustCompile(`(?i)\bselect\s+distinct\b`)
	reSQLCountDist = regexp.MustCompile(`(?i)\bcount\s*\(\s*distinct\b`)
	reSQLGroupBy   = regexp.MustCompile(`(?i)\bgroup\s+by\b`)
	reSQLAggOnly   = regexp.MustCompile(`(?i)\b(count|sum|avg|min|max)\s*\(`)
	reAskUnique    = regexp.MustCompile(`(?i)\b(list|show|display|what are|which|names?|titles?|unique|distinct|different|codes?|ids?\b)`)
	reAskCount     = regexp.MustCompile(`(?i)\b(how many|number of|count of|total number)\b`)
	reAskUniqueKW  = regexp.MustCompile(`(?i)\b(unique|distinct|different)\b`)
)

// CollectJoinCardHints pulls 1:N-ish FK edges from Rich Context for selected tables.
func CollectJoinCardHints(shared *contextpkg.SharedContext, tables []string) []JoinCardHint {
	if shared == nil {
		return nil
	}
	allow := map[string]struct{}{}
	for _, t := range tables {
		allow[strings.ToLower(t)] = struct{}{}
	}
	restrict := len(allow) > 0

	var out []JoinCardHint
	for tname, table := range shared.Tables {
		if table == nil {
			continue
		}
		if restrict {
			if _, ok := allow[strings.ToLower(tname)]; !ok {
				continue
			}
		}
		for _, fk := range table.ForeignKeys {
			ptc := fk.ParentToChild
			if ptc == "" && fk.Cardinality == "N:1" {
				ptc = "1:N"
			}
			if ptc != "1:N" && fk.AvgChildren <= 1.05 {
				continue
			}
			out = append(out, JoinCardHint{
				ChildTable:    tname,
				ParentTable:   fk.ReferencedTable,
				ChildColumn:   fk.ColumnName,
				ParentToChild: ptc,
				AvgChildren:   fk.AvgChildren,
			})
		}
	}
	return out
}

// AnalyzeJoinDistinctIssues returns soft warnings for DISTINCT / 1:N misuse.
func AnalyzeJoinDistinctIssues(sql, question string, hints []JoinCardHint, hasDupRows bool, rowCount int) []string {
	sqlU := strings.TrimSpace(sql)
	if sqlU == "" {
		return nil
	}
	q := question
	hasJoin := reSQLJoin.MatchString(sqlU)
	hasSelectDistinct := reSQLDistinct.MatchString(sqlU)
	hasCountDistinct := reSQLCountDist.MatchString(sqlU)
	hasGroupBy := reSQLGroupBy.MatchString(sqlU)
	hasAgg := reSQLAggOnly.MatchString(sqlU)
	wantsUnique := reAskUnique.MatchString(q) || reAskUniqueKW.MatchString(q)
	wantsCount := reAskCount.MatchString(q)

	var warns []string

	var hit1N []JoinCardHint
	sqlLower := strings.ToLower(sqlU)
	for _, h := range hints {
		if strings.Contains(sqlLower, strings.ToLower(h.ChildTable)) &&
			strings.Contains(sqlLower, strings.ToLower(h.ParentTable)) {
			hit1N = append(hit1N, h)
		}
	}

	if hasJoin && len(hit1N) > 0 && !hasSelectDistinct && !hasGroupBy {
		aggOnly := hasAgg && !wantsUnique
		if !aggOnly || hasDupRows {
			ex := hit1N[0]
			msg := fmt.Sprintf(
				"⚠️  JOIN crosses 1:N edge %s → %s via %s.%s (parent 1:N). Rows may multiply. "+
					"If the question wants unique parents/entities, add SELECT DISTINCT (or DISTINCT inside COUNT). "+
					"If it wants a raw row count after join, keep as-is.",
				ex.ParentTable, ex.ChildTable, ex.ChildTable, ex.ChildColumn)
			if ex.AvgChildren > 1.05 {
				msg += fmt.Sprintf(" (avg ~%.1f child rows/parent)", ex.AvgChildren)
			}
			warns = append(warns, msg)
		}
	}

	if hasJoin && hasDupRows && !hasSelectDistinct && !hasCountDistinct && wantsUnique && !wantsCount {
		warns = append(warns,
			"⚠️  Result has duplicate rows after JOIN and the question asks to list/show entities. Prefer SELECT DISTINCT (or GROUP BY) to return unique values.")
	}

	if !hasJoin && (hasCountDistinct || hasSelectDistinct) && !reAskUniqueKW.MatchString(q) {
		if wantsCount && hasCountDistinct {
			warns = append(warns,
				"⚠️  Single-table COUNT(DISTINCT …) without the question asking for unique/distinct values — "+
					"BIRD gold often uses COUNT(col) or COUNT(*) here. Drop DISTINCT unless duplicates are real.")
		} else if hasSelectDistinct && !wantsCount {
			warns = append(warns,
				"⚠️  Single-table SELECT DISTINCT without unique/distinct wording — confirm DISTINCT is necessary; unnecessary DISTINCT can change EX.")
		}
	}

	if hasJoin && wantsCount && !hasCountDistinct && !hasSelectDistinct && len(hit1N) > 0 && rowCount > 0 {
		warns = append(warns,
			"⚠️  Counting across a 1:N JOIN without COUNT(DISTINCT entity). "+
				"If counting parents/entities (not child rows), use COUNT(DISTINCT parent_key).")
	}

	return uniqueWarns(warns)
}

func uniqueWarns(in []string) []string {
	seen := map[string]struct{}{}
	var out []string
	for _, w := range in {
		if _, ok := seen[w]; ok {
			continue
		}
		seen[w] = struct{}{}
		out = append(out, w)
	}
	return out
}

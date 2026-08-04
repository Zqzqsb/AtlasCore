package context

import (
	"fmt"
	"regexp"
	"strings"
	"unicode"
)

var (
	reDigitsOnly = regexp.MustCompile(`^[0-9]+$`)
	reAlphaOnly  = regexp.MustCompile(`^[A-Za-z]+$`)
	reAlnum      = regexp.MustCompile(`^[A-Za-z0-9_\-]+$`)
	reDateish    = regexp.MustCompile(`(?i)^\d{4}[-/]\d{1,2}[-/]\d{1,2}|^\d{1,2}[-/]\d{1,2}[-/]\d{2,4}`)
	reEmailish   = regexp.MustCompile(`@`)
)

// known placeholder / pollution values (AskData-style default-value noise)
var suspiciousValueSet = map[string]struct{}{
	"123-456-7890": {}, "1234567890": {}, "0000000000": {}, "n/a": {}, "na": {},
	"null": {}, "none": {}, "test": {}, "asdf": {}, "xxx": {}, "unknown": {},
	"tbd": {}, "placeholder": {}, "email@email.com": {}, "foo": {}, "bar": {},
}

// ClassifyValueShape returns a coarse shape label for one string value.
func ClassifyValueShape(s string) string {
	s = strings.TrimSpace(s)
	if s == "" {
		return "empty"
	}
	if reDateish.MatchString(s) {
		return "dateish"
	}
	if reEmailish.MatchString(s) {
		return "emailish"
	}
	if reDigitsOnly.MatchString(s) {
		return "digits"
	}
	if reAlphaOnly.MatchString(s) {
		return "alpha"
	}
	if reAlnum.MatchString(s) {
		return "alnum"
	}
	// unicode letters/digits mix without weird symbols → mixed alnum-ish
	hasLetter, hasDigit, hasOther := false, false, false
	for _, r := range s {
		switch {
		case unicode.IsLetter(r):
			hasLetter = true
		case unicode.IsDigit(r):
			hasDigit = true
		case unicode.IsSpace(r) || r == '-' || r == '_' || r == '.' || r == ',':
			// soft punctuation
		default:
			hasOther = true
		}
	}
	if hasOther {
		return "mixed"
	}
	if hasLetter && hasDigit {
		return "alnum"
	}
	if hasLetter {
		return "alpha"
	}
	if hasDigit {
		return "digits"
	}
	return "mixed"
}

func isSuspiciousValue(s string) bool {
	key := strings.ToLower(strings.TrimSpace(s))
	_, ok := suspiciousValueSet[key]
	return ok
}

// AnnotateTextProfile fills DominantShape / AvgLen / SuspiciousDefaults from
// TopValues + SampleValues. No-op for nil stats.
func AnnotateTextProfile(stats *ValueStats) {
	if stats == nil {
		return
	}
	type pair struct {
		v string
		w int // weight
	}
	var vals []pair
	for _, tv := range stats.TopValues {
		if strings.TrimSpace(tv.Value) == "" {
			continue
		}
		w := tv.Count
		if w <= 0 {
			w = 1
		}
		vals = append(vals, pair{tv.Value, w})
	}
	if len(vals) == 0 {
		for _, s := range stats.SampleValues {
			if strings.TrimSpace(s) == "" {
				continue
			}
			vals = append(vals, pair{s, 1})
		}
	}
	if len(vals) == 0 {
		return
	}

	shapeW := map[string]int{}
	var lenSum float64
	var lenN int
	susp := map[string]struct{}{}
	for _, p := range vals {
		sh := ClassifyValueShape(p.v)
		shapeW[sh] += p.w
		lenSum += float64(len([]rune(p.v))) * float64(p.w)
		lenN += p.w
		if isSuspiciousValue(p.v) {
			susp[p.v] = struct{}{}
		}
		// high-frequency identical value that looks polluted
		if p.w >= 10 && (sh == "digits" && len(p.v) >= 7 && strings.Trim(p.v, "0") == "") {
			susp[p.v] = struct{}{}
		}
	}
	dom, domN := "", 0
	for sh, w := range shapeW {
		if w > domN {
			dom, domN = sh, w
		}
	}
	stats.DominantShape = dom
	if lenN > 0 {
		stats.AvgLen = lenSum / float64(lenN)
	}
	if len(susp) > 0 {
		stats.SuspiciousDefaults = stats.SuspiciousDefaults[:0]
		for v := range susp {
			stats.SuspiciousDefaults = append(stats.SuspiciousDefaults, v)
			if len(stats.SuspiciousDefaults) >= 5 {
				break
			}
		}
	}
}

// BuildProfileNL writes a short deterministic English note from stats.
// Empty if there is nothing useful to say.
func BuildProfileNL(colName, colType string, stats *ValueStats) string {
	if stats == nil {
		return ""
	}
	var parts []string
	if stats.NullPercent >= 5 {
		parts = append(parts, fmt.Sprintf("%.0f%% NULL", stats.NullPercent))
	}
	if stats.EmptyCount > 0 {
		parts = append(parts, fmt.Sprintf("%d empty-string", stats.EmptyCount))
	}
	if stats.DistinctCount > 0 {
		parts = append(parts, fmt.Sprintf("distinct=%d", stats.DistinctCount))
	}
	if stats.DominantShape != "" && stats.DominantShape != "mixed" {
		if stats.AvgLen > 0 {
			parts = append(parts, fmt.Sprintf("shape=%s(~%.0f chars)", stats.DominantShape, stats.AvgLen))
		} else {
			parts = append(parts, "shape="+stats.DominantShape)
		}
	} else if stats.AvgLen > 0 && isTextTypeLocal(colType) {
		parts = append(parts, fmt.Sprintf("avgLen=%.0f", stats.AvgLen))
	}
	if stats.Range != nil {
		parts = append(parts, fmt.Sprintf("range=[%.0f..%.0f]", stats.Range.Min, stats.Range.Max))
	}
	if len(stats.SuspiciousDefaults) > 0 {
		parts = append(parts, "suspicious_defaults=["+strings.Join(stats.SuspiciousDefaults, ",")+"]")
	}
	if len(parts) == 0 {
		return ""
	}
	s := strings.Join(parts, "; ")
	if len(s) > 140 {
		s = s[:137] + "..."
	}
	return s
}

func isTextTypeLocal(colType string) bool {
	u := strings.ToUpper(colType)
	return strings.Contains(u, "CHAR") || strings.Contains(u, "TEXT") || strings.Contains(u, "CLOB") || u == "VARCHAR"
}

// RefreshColumnGrounding annotates shape profiles and fills ProfileNL for all columns.
// Does not touch OfficialMeaning.
func (c *SharedContext) RefreshColumnGrounding() {
	if c == nil {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	for _, table := range c.Tables {
		if table == nil {
			continue
		}
		for i := range table.Columns {
			col := &table.Columns[i]
			if col.ValueStats != nil {
				AnnotateTextProfile(col.ValueStats)
				col.ProfileNL = BuildProfileNL(col.Name, col.Type, col.ValueStats)
			}
		}
	}
}

// OfficialMeaningLookup maps "table|column" (lowercase) → description.
type OfficialMeaningLookup map[string]string

// ApplyOfficialMeanings sets ColumnMetadata.OfficialMeaning from a lookup.
// Keys must be "table|column" lowercase. Only fills/overwrites meaning fields;
// does not change stats. dbID unused but reserved for multi-db keys.
func (c *SharedContext) ApplyOfficialMeanings(lookup OfficialMeaningLookup) int {
	if c == nil || len(lookup) == 0 {
		return 0
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	n := 0
	for tname, table := range c.Tables {
		if table == nil {
			continue
		}
		tl := strings.ToLower(tname)
		for i := range table.Columns {
			col := &table.Columns[i]
			key := tl + "|" + strings.ToLower(col.Name)
			if m, ok := lookup[key]; ok && strings.TrimSpace(m) != "" {
				col.OfficialMeaning = sanitizeMeaningLocal(m, 200)
				n++
			}
		}
	}
	return n
}

func sanitizeMeaningLocal(v string, max int) string {
	desc := strings.TrimSpace(v)
	desc = strings.ReplaceAll(desc, "#", "")
	desc = strings.ReplaceAll(desc, "\n", " ")
	desc = strings.Join(strings.Fields(desc), " ")
	if max > 0 && len(desc) > max {
		desc = desc[:max-3] + "..."
	}
	return desc
}

// ParseColumnMeaningFile adapts BIRD column_meaning.json ("db|table|col" → text)
// into OfficialMeaningLookup for one database.
func ParseColumnMeaningForDB(raw map[string]string, dbID string) OfficialMeaningLookup {
	if len(raw) == 0 || dbID == "" {
		return nil
	}
	prefix := strings.ToLower(strings.TrimSpace(dbID)) + "|"
	out := OfficialMeaningLookup{}
	for k, v := range raw {
		lk := strings.ToLower(strings.TrimSpace(k))
		if !strings.HasPrefix(lk, prefix) {
			continue
		}
		rest := strings.TrimPrefix(lk, prefix) // table|col
		parts := strings.SplitN(rest, "|", 2)
		if len(parts) != 2 {
			continue
		}
		out[parts[0]+"|"+parts[1]] = strings.TrimSpace(v)
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

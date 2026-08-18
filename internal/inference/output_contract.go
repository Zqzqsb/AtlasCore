package inference

import (
	"fmt"
	"regexp"
	"strings"
)

// OutputContract is a gold-free projection hint derived from question + evidence.
// It approximates force-clarify without reading gold SQL.
type OutputContract struct {
	Summary    string   // short natural-language contract for the prompt
	Keywords   []string // tokens useful for verify_sql column checks
	Hints      []string // structured hints (count / name / list / …)
	RawBullets []string // bullet lines injected into the prompt
	MaxCols    int      // >0 → verify warns when SELECT returns more columns
	NeedsLimit bool     // ranking / top-N / Nth → expect ORDER BY + LIMIT
}

var (
	reHowMany   = regexp.MustCompile(`(?i)\b(how many|number of|count of|total number)\b`)
	reList      = regexp.MustCompile(`(?i)\b(list|show|display|what are|find all|give me)\b`)
	reWhichWho  = regexp.MustCompile(`(?i)\b(which|who|whom)\b`)
	reName      = regexp.MustCompile(`(?i)\b(name|names|title|titles)\b`)
	reID        = regexp.MustCompile(`(?i)\b(id|ids|identifier)\b`)
	reAvg       = regexp.MustCompile(`(?i)\b(average|avg|mean)\b`)
	reMaxMin    = regexp.MustCompile(`(?i)\b(maximum|minimum|max|min|highest|lowest|largest|smallest)\b`)
	rePercent   = regexp.MustCompile(`(?i)\b(percent|percentage|ratio|proportion)\b`)
	reDistinct  = regexp.MustCompile(`(?i)\b(distinct|unique|different)\b`)
	reTopN      = regexp.MustCompile(`(?i)\b(top\s+\d+|first\s+\d+|bottom\s+\d+)\b`)
	reNth       = regexp.MustCompile(`(?i)\b\d+(st|nd|rd|th)\b`)
	reMostLeast = regexp.MustCompile(`(?i)\b(the\s+)?(most|least|fewest)\b`)
	reQuoted    = regexp.MustCompile(`'([^']{2,80})'|"([^"]{2,80})"`)
	reEvidenceK = regexp.MustCompile(`(?i)(?:refers to|means|stands for|equals|=)\s*([A-Za-z_][A-Za-z0-9_\.]*)`)
	reMultiAttr = regexp.MustCompile(`(?i)\b(and|,)\b.*\b(name|id|title|score|date|city|country)\b`)
)

// BuildOutputContract derives an output contract from question and evidence only.
func BuildOutputContract(question, evidence string) *OutputContract {
	text := strings.TrimSpace(question)
	if evidence != "" {
		text = text + "\n" + evidence
	}
	c := &OutputContract{}

	multi := asksMultipleOutputAttrs(question, evidence)
	if reHowMany.MatchString(text) {
		c.Hints = append(c.Hints, "return a single aggregate COUNT (or equivalent numeric total), not raw row dumps")
		c.Keywords = append(c.Keywords, "count", "total", "number")
		if !multi {
			c.MaxCols = 1
		}
	}
	if reAvg.MatchString(text) {
		c.Hints = append(c.Hints, "return an AVERAGE / mean metric as requested")
		c.Keywords = append(c.Keywords, "average", "avg", "mean")
		if c.MaxCols == 0 && !multi && !reWhichWho.MatchString(question) {
			c.MaxCols = 1
		}
	}
	if reMaxMin.MatchString(text) {
		c.Hints = append(c.Hints, "return the MAX/MIN (or highest/lowest) value asked for")
		c.Keywords = append(c.Keywords, "max", "min", "highest", "lowest")
	}
	if rePercent.MatchString(text) {
		c.Hints = append(c.Hints, "return a percentage/ratio; keep the computation faithful to evidence formulas")
		c.Keywords = append(c.Keywords, "percent", "ratio", "proportion")
		if c.MaxCols == 0 && !multi && !reWhichWho.MatchString(question) {
			c.MaxCols = 1
		}
	}
	if reList.MatchString(text) {
		c.Hints = append(c.Hints, "return the entities/attributes asked for as result columns (not only IDs unless the question asks for IDs)")
	}
	// who/which: do NOT force MaxCols=1 (full name is first+last; "A and B" is two cols).
	// Ranking: return the entity, not the ORDER BY metric.
	if reWhichWho.MatchString(question) || reTopN.MatchString(text) {
		c.Hints = append(c.Hints, "for who/which/top-N, SELECT only the asked entity — do not also SELECT the ranking metric (count/sum/gdp/…) used in ORDER BY")
	}
	if reName.MatchString(text) && !reID.MatchString(strings.ToLower(question)) {
		c.Hints = append(c.Hints, "prefer human-readable names over opaque IDs when the question asks for names")
		c.Keywords = append(c.Keywords, "name", "title")
	}
	if reDistinct.MatchString(text) {
		c.Hints = append(c.Hints, "use DISTINCT when the question asks for unique/distinct values")
		c.Keywords = append(c.Keywords, "distinct")
	}
	if reTopN.MatchString(text) || reNth.MatchString(text) || reMostLeast.MatchString(question) {
		c.NeedsLimit = true
		c.Hints = append(c.Hints, "apply ORDER BY + LIMIT when ranking / top-N / Nth is requested (do not rely on MAX alone when asking who/which)")
	}

	// Pull evidence formula / column hints
	for _, m := range reEvidenceK.FindAllStringSubmatch(evidence, -1) {
		tok := m[1]
		if tok != "" {
			c.Keywords = append(c.Keywords, strings.ToLower(tok))
			c.Hints = append(c.Hints, fmt.Sprintf("evidence maps a phrase to `%s` — use that expression when relevant", tok))
		}
	}
	for _, m := range reQuoted.FindAllStringSubmatch(evidence+" "+question, -1) {
		val := m[1]
		if val == "" {
			val = m[2]
		}
		if len(val) >= 2 {
			c.Keywords = append(c.Keywords, strings.ToLower(val))
		}
	}

	c.Keywords = uniqueFold(c.Keywords)
	c.Hints = uniqueFold(c.Hints)

	if len(c.Hints) == 0 {
		c.Hints = append(c.Hints, "SELECT only columns needed to answer the question; avoid extra columns")
	}

	for _, h := range c.Hints {
		c.RawBullets = append(c.RawBullets, "- "+h)
	}
	c.Summary = strings.Join(c.RawBullets, "\n")
	return c
}

// FormatForPrompt returns the prompt block for gold-free projection guidance.
func (c *OutputContract) FormatForPrompt() string {
	if c == nil || c.Summary == "" {
		return ""
	}
	var sb strings.Builder
	sb.WriteString("⚠️ OUTPUT CONTRACT (derived from question/evidence only — no gold fields):\n")
	sb.WriteString("Your SQL result projection MUST satisfy:\n")
	sb.WriteString(c.Summary)
	if c.MaxCols > 0 {
		sb.WriteString(fmt.Sprintf("\n★ SELECT at most %d column(s) unless evidence requires more.", c.MaxCols))
	}
	if c.NeedsLimit {
		sb.WriteString("\n★ Ranking answers need ORDER BY + LIMIT.")
	}
	sb.WriteString("\nDo NOT invent extra unrelated columns. Match the question's asked attributes.\n\n")
	return sb.String()
}

func uniqueFold(in []string) []string {
	seen := map[string]struct{}{}
	out := make([]string, 0, len(in))
	for _, s := range in {
		k := strings.ToLower(strings.TrimSpace(s))
		if k == "" {
			continue
		}
		if _, ok := seen[k]; ok {
			continue
		}
		seen[k] = struct{}{}
		out = append(out, s)
	}
	return out
}

// splitQuestionEvidence unwraps eval's "Question + Evidence (...)" packing.
func splitQuestionEvidence(query string) (question, evidence string) {
	const marker = "\n\nEvidence (MUST follow these constraints):\n"
	if i := strings.Index(query, marker); i >= 0 {
		return strings.TrimSpace(query[:i]), strings.TrimSpace(query[i+len(marker):])
	}
	const marker2 = "\n\nEvidence:\n"
	if i := strings.Index(query, marker2); i >= 0 {
		return strings.TrimSpace(query[:i]), strings.TrimSpace(query[i+len(marker2):])
	}
	return strings.TrimSpace(query), ""
}

var (
	reFullNameAsk = regexp.MustCompile(`(?i)\bfull\s*names?\b`)
	reFirstLast   = regexp.MustCompile(`(?i)\b(first\s*name|lastname|last\s*name|firstname)\b`)
	reBothAnd     = regexp.MustCompile(`(?i)\b(both|as well as)\b`)
)

func asksMultipleOutputAttrs(question, evidence string) bool {
	q := question
	if reMultiAttr.MatchString(q) || reBothAnd.MatchString(q) || reFullNameAsk.MatchString(q) || reFirstLast.MatchString(q+" "+evidence) {
		return true
	}
	// "how many albums and singles" / "highest and lowest"
	if strings.Contains(strings.ToLower(q), " and ") {
		return true
	}
	return false
}

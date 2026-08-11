package inference

import (
	"context"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"unicode"

	"github.com/Zqzqsb/AtlasCore/internal/valueindex"
)

var (
	cjkLiteralRe    = regexp.MustCompile(`[\p{Han}]{2,24}`)
	properNounRe    = regexp.MustCompile(`\b[A-Z][a-zA-Z0-9]+(?:\s+[A-Z][a-zA-Z0-9]+){0,3}\b`)
	pureNumberRe    = regexp.MustCompile(`^\d+(\.\d+)?%?$`)
	valueIndexMu    sync.Mutex
	valueIndexCache = map[string]*valueindex.Store{}

	// English interrogatives / verbs that were matching random token postings
	// ("What"→Powhatan, "Tell"→Blood Will Tell, …).
	valueIndexQueryStop = map[string]struct{}{
		"what": {}, "who": {}, "whom": {}, "which": {}, "where": {}, "when": {},
		"why": {}, "how": {}, "whose": {},
		"tell": {}, "give": {}, "find": {}, "provide": {}, "show": {}, "list": {},
		"state": {}, "name": {}, "please": {}, "count": {}, "number": {},
		"does": {}, "did": {}, "is": {}, "are": {}, "was": {}, "were": {},
		"do": {}, "can": {}, "could": {}, "would": {}, "should": {},
		"the": {}, "a": {}, "an": {}, "for": {}, "from": {}, "with": {},
		"that": {}, "this": {}, "these": {}, "those": {}, "and": {}, "or": {},
		"of": {}, "in": {}, "on": {}, "to": {}, "by": {}, "as": {}, "at": {},
		"avg": {}, "average": {}, "sum": {}, "total": {}, "max": {}, "min": {},
		"select": {}, "limit": {}, "order": {}, "group": {}, "having": {},
	}
)

// ExtractValueIndexQueries pulls high-precision literals for entity-index lookup.
// Prefers quoted evidence strings and CJK spans; proper nouns are kept only when
// they are multi-word or long enough and not stop-words.
func ExtractValueIndexQueries(question, evidence string) []string {
	seen := map[string]struct{}{}
	var out []string
	add := func(s string, relaxStop bool) {
		s = strings.TrimSpace(s)
		if s == "" || len(s) < 2 || len(s) > 80 {
			return
		}
		if pureNumberRe.MatchString(s) {
			return
		}
		key := strings.ToLower(s)
		if !relaxStop {
			if _, stop := valueIndexQueryStop[key]; stop {
				return
			}
			// multi-word: drop if every token is a stop word
			parts := strings.Fields(key)
			if len(parts) > 1 {
				allStop := true
				for _, p := range parts {
					if _, stop := valueIndexQueryStop[p]; !stop {
						allStop = false
						break
					}
				}
				if allStop {
					return
				}
			}
		}
		if _, ok := seen[key]; ok {
			return
		}
		seen[key] = struct{}{}
		out = append(out, s)
	}

	// Quoted / percent literals from evidence are highest precision — still ban pure stops.
	for _, lit := range ExtractEvidenceLiterals(question, evidence) {
		add(lit, false)
	}
	text := question + "\n" + evidence
	for _, m := range cjkLiteralRe.FindAllString(text, -1) {
		add(m, true) // CJK never uses English stop list
	}
	for _, m := range properNounRe.FindAllString(text, -1) {
		fields := strings.Fields(m)
		if len(fields) == 1 {
			// Single Capitalized token: require length >= 4 (keeps Bundesliga, drops What/TV ok via quotes)
			if len([]rune(fields[0])) < 4 {
				continue
			}
			if isMostlyDigits(fields[0]) {
				continue
			}
		}
		add(m, false)
	}
	if len(out) > 12 {
		out = out[:12]
	}
	return out
}

func isMostlyDigits(s string) bool {
	digits := 0
	for _, r := range s {
		if unicode.IsDigit(r) {
			digits++
		}
	}
	return digits > 0 && digits*2 >= len([]rune(s))
}

func (p *Pipeline) valueIndexPath() string {
	if p == nil || p.context == nil || p.config == nil {
		return ""
	}
	vi := p.context.ValueIndex
	if vi == nil || strings.TrimSpace(vi.Path) == "" || vi.Documents == 0 {
		return ""
	}
	if p.config.ContextFile == "" {
		return ""
	}
	base := filepath.Dir(p.config.ContextFile)
	return filepath.Join(base, filepath.FromSlash(vi.Path))
}

func (p *Pipeline) openValueIndex() (*valueindex.Store, error) {
	path := p.valueIndexPath()
	if path == "" {
		return nil, nil
	}
	if _, err := os.Stat(path); err != nil {
		return nil, nil
	}
	valueIndexMu.Lock()
	defer valueIndexMu.Unlock()
	if s, ok := valueIndexCache[path]; ok {
		return s, nil
	}
	s, err := valueindex.OpenStore(path)
	if err != nil {
		return nil, err
	}
	valueIndexCache[path] = s
	return s, nil
}

// keepValueIndexHit: inject only exact matches by default. Strong token hits are
// kept only when the query is a long contiguous substring of the stored value
// (e.g. "Wahlberg" ⊂ "Daryl Wahlberg") — never weak n-gram collisions.
func keepValueIndexHit(h valueindex.Hit) bool {
	if strings.EqualFold(h.MatchType, "exact") {
		return true
	}
	q := strings.TrimSpace(strings.ToLower(h.MatchedText))
	d := strings.TrimSpace(strings.ToLower(h.DisplayValue))
	if len([]rune(q)) < 5 || d == "" {
		return false
	}
	if _, stop := valueIndexQueryStop[q]; stop {
		return false
	}
	return strings.Contains(d, q)
}

// LookupValueIndexHits runs high-precision value→column recall.
func (p *Pipeline) LookupValueIndexHits(ctx context.Context, question, evidence string) ([]valueindex.Hit, error) {
	store, err := p.openValueIndex()
	if err != nil || store == nil {
		return nil, err
	}
	queries := ExtractValueIndexQueries(question, evidence)
	var all []valueindex.Hit
	seen := map[string]struct{}{}
	for _, q := range queries {
		hits, err := store.Lookup(ctx, q, 8)
		if err != nil {
			continue
		}
		for _, h := range hits {
			if !keepValueIndexHit(h) {
				continue
			}
			key := strings.ToLower(h.Table + "." + h.Column + "=" + h.DisplayValue + "|" + h.MatchedText)
			if _, ok := seen[key]; ok {
				continue
			}
			seen[key] = struct{}{}
			all = append(all, h)
			if len(all) >= 12 {
				return all, nil
			}
		}
	}
	return all, nil
}

// filterHitsByAllowedTables keeps hits whose table is already in the linker
// allow-list (selected + FK expand). Case-insensitive.
func filterHitsByAllowedTables(hits []valueindex.Hit, allowed []string) []valueindex.Hit {
	if len(hits) == 0 || len(allowed) == 0 {
		return nil
	}
	allow := map[string]string{} // lower -> canonical
	for _, t := range allowed {
		allow[strings.ToLower(t)] = t
	}
	var out []valueindex.Hit
	for _, h := range hits {
		if canon, ok := allow[strings.ToLower(h.Table)]; ok {
			h.Table = canon
			out = append(out, h)
		}
	}
	return out
}

func filterLiteralsWithoutExactHit(literals []string, hits []valueindex.Hit) []string {
	exact := map[string]struct{}{}
	for _, h := range hits {
		if strings.EqualFold(h.MatchType, "exact") || keepValueIndexHit(h) {
			exact[strings.ToLower(h.MatchedText)] = struct{}{}
			exact[strings.ToLower(h.DisplayValue)] = struct{}{}
		}
	}
	if len(exact) == 0 {
		return literals
	}
	var out []string
	for _, lit := range literals {
		if _, ok := exact[strings.ToLower(lit)]; ok {
			continue
		}
		out = append(out, lit)
	}
	return out
}

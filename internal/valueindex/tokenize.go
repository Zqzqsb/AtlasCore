package valueindex

import (
	"strings"
	"unicode"
	"unicode/utf8"
)

// Token is one deterministic lexical posting.
type Token struct {
	Type  string
	Token string
}

// Normalize is deterministic and dependency-free: lowercase, fold full-width
// ASCII, collapse punctuation/space boundaries (WiseCat-compatible).
func Normalize(text string) string {
	var b strings.Builder
	b.Grow(len(text))
	separator := false
	for _, r := range strings.TrimSpace(strings.ToLower(text)) {
		switch {
		case r == '\u3000':
			separator = true
		case r >= '\uff01' && r <= '\uff5e':
			r -= 0xfee0
			if unicode.IsLetter(r) || unicode.IsDigit(r) {
				if separator && b.Len() > 0 {
					b.WriteByte(' ')
				}
				b.WriteRune(r)
				separator = false
			} else {
				separator = true
			}
		case unicode.IsLetter(r) || unicode.IsDigit(r):
			if separator && b.Len() > 0 {
				b.WriteByte(' ')
			}
			b.WriteRune(r)
			separator = false
		default:
			separator = true
		}
	}
	return collapseCJKSpaces(strings.TrimSpace(b.String()))
}

func collapseCJKSpaces(text string) string {
	runes := []rune(text)
	out := make([]rune, 0, len(runes))
	for i, r := range runes {
		if !unicode.IsSpace(r) {
			out = append(out, r)
			continue
		}
		var prev, next rune
		if len(out) > 0 {
			prev = out[len(out)-1]
		}
		for j := i + 1; j < len(runes); j++ {
			if !unicode.IsSpace(runes[j]) {
				next = runes[j]
				break
			}
		}
		if unicode.Is(unicode.Han, prev) && unicode.Is(unicode.Han, next) {
			continue
		}
		if len(out) > 0 && !unicode.IsSpace(out[len(out)-1]) {
			out = append(out, ' ')
		}
	}
	return strings.TrimSpace(string(out))
}

// Tokens emits CJK 2/3-gram and Latin word/3-gram postings.
func Tokens(normalized string) []Token {
	seen := make(map[string]bool)
	var out []Token
	add := func(kind, token string) {
		token = strings.TrimSpace(token)
		if token == "" || len(token) > 64 || !utf8.ValidString(token) {
			return
		}
		key := kind + "\x00" + token
		if seen[key] {
			return
		}
		seen[key] = true
		out = append(out, Token{Type: kind, Token: token})
	}
	for _, run := range tokenRuns(normalized) {
		runes := []rune(run.text)
		if run.cjk {
			for _, spec := range []struct {
				n    int
				kind string
			}{{3, "cjk3"}, {2, "cjk2"}} {
				n, kind := spec.n, spec.kind
				for i := 0; i+n <= len(runes); i++ {
					add(kind, string(runes[i:i+n]))
				}
			}
			continue
		}
		add("word", run.text)
		for i := 0; i+3 <= len(runes); i++ {
			add("latin3", string(runes[i:i+3]))
		}
	}
	return out
}

type tokenRun struct {
	text string
	cjk  bool
}

func tokenRuns(normalized string) []tokenRun {
	var out []tokenRun
	var current []rune
	currentCJK := false
	flush := func() {
		if len(current) > 0 {
			out = append(out, tokenRun{text: string(current), cjk: currentCJK})
			current = nil
		}
	}
	for _, r := range normalized {
		if unicode.IsSpace(r) {
			flush()
			continue
		}
		isCJK := unicode.Is(unicode.Han, r)
		if len(current) > 0 && isCJK != currentCJK {
			flush()
		}
		currentCJK = isCJK
		current = append(current, r)
	}
	flush()
	return out
}

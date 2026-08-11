package valueindex

import "testing"

func TestNormalizeAndTokensLatin(t *testing.T) {
	n := Normalize("  Hello, World! ")
	if n != "hello world" {
		t.Fatalf("normalize=%q", n)
	}
	toks := Tokens(n)
	hasWord := false
	for _, tok := range toks {
		if tok.Type == "word" && tok.Token == "hello" {
			hasWord = true
		}
	}
	if !hasWord {
		t.Fatalf("missing word token: %+v", toks)
	}
}

func TestNormalizeCJK(t *testing.T) {
	n := Normalize("拼多多")
	if n != "拼多多" {
		t.Fatalf("normalize=%q", n)
	}
	toks := Tokens(n)
	if len(toks) == 0 {
		t.Fatal("expected cjk tokens")
	}
}

func TestClassifyAndSelect(t *testing.T) {
	cols := []ColumnSpec{
		{Table: "t", Column: "customer_name", DeclType: "TEXT", NRows: 100, NDV: 80},
		{Table: "t", Column: "created_at", DeclType: "TEXT", NRows: 100, NDV: 90},
		{Table: "t", Column: "id", DeclType: "TEXT", IsPK: true, NRows: 100, NDV: 100},
		{Table: "t", Column: "status", DeclType: "TEXT", NRows: 100, NDV: 5},
	}
	ds := SelectColumns(cols, DefaultOptions())
	var indexed, gated int
	for _, d := range ds {
		switch d.Status {
		case "indexed":
			indexed++
		case "hard_gate":
			gated++
		}
	}
	if indexed < 2 {
		t.Fatalf("expected >=2 indexed, got %d (%+v)", indexed, ds)
	}
	if gated < 2 {
		t.Fatalf("expected pk+created_at gated, got gated=%d", gated)
	}
}

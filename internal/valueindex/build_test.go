package valueindex

import (
	"context"
	"database/sql"
	"path/filepath"
	"testing"

	_ "modernc.org/sqlite"
)

func TestBuildAndLookup(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src.sqlite")
	db, err := sql.Open("sqlite", src)
	if err != nil {
		t.Fatal(err)
	}
	_, err = db.Exec(`
CREATE TABLE customers (id INTEGER PRIMARY KEY, customer_name TEXT, status TEXT, created_at TEXT);
INSERT INTO customers VALUES
 (1,'Acme Corp','active','2020-01-01'),
 (2,'拼多多','active','2020-01-02'),
 (3,'Beta Inc','closed','2020-01-03');
`)
	if err != nil {
		t.Fatal(err)
	}
	_ = db.Close()

	out := filepath.Join(dir, "value_index", "demo.sqlite")
	rep, err := Build(context.Background(), src, out, "demo", nil, DefaultOptions())
	if err != nil {
		t.Fatal(err)
	}
	if rep.Documents == 0 {
		t.Fatalf("expected documents, report=%+v", rep)
	}
	if rep.ColumnsIndexed == 0 {
		t.Fatalf("expected indexed columns, report=%+v", rep)
	}

	store, err := OpenStore(out)
	if err != nil {
		t.Fatal(err)
	}
	defer store.Close()

	hits, err := store.Lookup(context.Background(), "拼多多", 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(hits) == 0 {
		t.Fatal("expected hit for 拼多多")
	}
	found := false
	for _, h := range hits {
		if h.Table == "customers" && h.Column == "customer_name" && h.DisplayValue == "拼多多" {
			found = true
			if h.MatchType != "exact" {
				t.Fatalf("want exact, got %s", h.MatchType)
			}
		}
	}
	if !found {
		t.Fatalf("hits=%+v", hits)
	}

	hits2, err := store.Lookup(context.Background(), "Acme", 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(hits2) == 0 {
		t.Fatal("expected token/exact hit for Acme")
	}
}

func TestBuildValueAliases(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src.sqlite")
	db, err := sql.Open("sqlite", src)
	if err != nil {
		t.Fatal(err)
	}
	_, err = db.Exec(`
CREATE TABLE sets (id INTEGER PRIMARY KEY, is_foil_only INTEGER);
INSERT INTO sets VALUES (1, 0), (2, 1), (3, 1);
`)
	if err != nil {
		t.Fatal(err)
	}
	_ = db.Close()

	out := filepath.Join(dir, "idx.sqlite")
	opt := DefaultOptions()
	opt.Aliases = map[string][]string{
		"sets|is_foil_only|1": {"Y", "foil only"},
		"sets|is_foil_only|0": {"N"},
	}
	cols := []ColumnSpec{{
		Table: "sets", Column: "is_foil_only", DeclType: "INTEGER",
		ForceIndex: true, Policy: PolicyInclude, NDV: 2, NRows: 3,
	}}
	if _, err := Build(context.Background(), src, out, "demo", cols, opt); err != nil {
		t.Fatal(err)
	}
	store, err := OpenStore(out)
	if err != nil {
		t.Fatal(err)
	}
	defer store.Close()
	hits, err := store.Lookup(context.Background(), "Y", 8)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, h := range hits {
		if h.Table == "sets" && h.Column == "is_foil_only" && h.DisplayValue == "1" {
			found = true
		}
	}
	if !found {
		t.Fatalf("expected alias Y → is_foil_only=1, hits=%+v", hits)
	}
}

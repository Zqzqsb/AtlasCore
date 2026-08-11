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

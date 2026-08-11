package inference

import (
	"context"
	"database/sql"
	"path/filepath"
	"strings"
	"testing"

	_ "modernc.org/sqlite"

	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
	"github.com/Zqzqsb/AtlasCore/internal/valueindex"
)

func TestExtractValueIndexQueriesKeepsEntitiesDropsStops(t *testing.T) {
	q := ExtractValueIndexQueries(`How many orders for 拼多多?`, `customer is 'Acme Corp'`)
	joined := strings.Join(q, ";")
	if !strings.Contains(joined, "拼多多") || !strings.Contains(joined, "Acme Corp") {
		t.Fatalf("queries=%v", q)
	}
	for _, bad := range []string{"How", "What", "Tell", "Give", "Provide", "Find"} {
		if containsFold(q, bad) {
			t.Fatalf("stop query %q leaked in %v", bad, q)
		}
	}
}

func TestExtractValueIndexQueriesDropsSentenceStarters(t *testing.T) {
	q := ExtractValueIndexQueries(`What is the average number of terms?`, `famous refers to wikipedia_id`)
	for _, bad := range []string{"What", "Give", "Tell"} {
		if containsFold(q, bad) {
			t.Fatalf("got %v, contains stop %q", q, bad)
		}
	}
}

func TestKeepValueIndexHitExactOnlyByDefault(t *testing.T) {
	if !keepValueIndexHit(valueindex.Hit{MatchType: "exact", MatchedText: "x", DisplayValue: "x"}) {
		t.Fatal("exact should keep")
	}
	if keepValueIndexHit(valueindex.Hit{MatchType: "token", MatchedText: "What", DisplayValue: "Powhatan", Score: 0.9}) {
		t.Fatal("stop token must drop")
	}
	if keepValueIndexHit(valueindex.Hit{MatchType: "token", MatchedText: "Tell", DisplayValue: "Blood Will Tell", Score: 0.8}) {
		t.Fatal("short/stop token must drop")
	}
	if !keepValueIndexHit(valueindex.Hit{MatchType: "token", MatchedText: "Wahlberg", DisplayValue: "Daryl Wahlberg", Score: 0.5}) {
		t.Fatal("long substring token should keep")
	}
}

func TestFilterHitsByAllowedTables(t *testing.T) {
	hits := []valueindex.Hit{
		{Table: "Award", Column: "award", DisplayValue: "Best Television Episode", MatchType: "exact"},
		{Table: "noise", Column: "x", DisplayValue: "Best Television Episode", MatchType: "exact"},
	}
	kept := filterHitsByAllowedTables(hits, []string{"Person", "Award"})
	if len(kept) != 1 || kept[0].Table != "Award" {
		t.Fatalf("kept=%+v", kept)
	}
}

func TestPipelineValueIndexLookup(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src.sqlite")
	db, err := sql.Open("sqlite", src)
	if err != nil {
		t.Fatal(err)
	}
	_, err = db.Exec(`
CREATE TABLE customers (id INTEGER PRIMARY KEY, customer_name TEXT);
INSERT INTO customers VALUES (1,'拼多多'),(2,'Acme Corp');
`)
	if err != nil {
		t.Fatal(err)
	}
	_ = db.Close()

	out := filepath.Join(dir, "value_index", "demo.sqlite")
	if _, err := valueindex.Build(context.Background(), src, out, "demo", nil, valueindex.DefaultOptions()); err != nil {
		t.Fatal(err)
	}

	rcPath := filepath.Join(dir, "demo.json")
	shared := contextpkg.NewSharedContext("demo", "sqlite")
	shared.ValueIndex = &contextpkg.ValueIndexInfo{
		Path: "value_index/demo.sqlite", Documents: 2,
	}
	if err := shared.SaveToFile(rcPath); err != nil {
		t.Fatal(err)
	}

	p := &Pipeline{
		config:  &Config{ContextFile: rcPath},
		context: shared,
		Logger:  NewInferenceLogger(),
	}
	hits, err := p.LookupValueIndexHits(context.Background(), "客户 拼多多 订单数", "")
	if err != nil {
		t.Fatal(err)
	}
	if len(hits) == 0 {
		t.Fatal("expected hits")
	}
	found := false
	for _, h := range hits {
		if h.DisplayValue == "拼多多" && h.MatchType == "exact" {
			found = true
		}
	}
	if !found {
		t.Fatalf("hits=%+v", hits)
	}
}

func containsFold(xs []string, want string) bool {
	for _, x := range xs {
		if strings.EqualFold(x, want) {
			return true
		}
	}
	return false
}

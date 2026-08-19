package context

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGetStringDropsNilPRAGMATo(t *testing.T) {
	got := getString(map[string]interface{}{"to": nil}, "to")
	if got != "" {
		t.Fatalf("nil to should be empty, got %q", got)
	}
	got = getString(map[string]interface{}{"to": "<nil>"}, "to")
	if got != "" {
		t.Fatalf("literal <nil> should be empty, got %q", got)
	}
}

func TestParseForeignKeyMetadataSQLiteNullTo(t *testing.T) {
	fk := parseForeignKeyMetadata(map[string]interface{}{
		"from": "work_id", "table": "works", "to": nil,
	}, "sqlite")
	if fk.ColumnName != "work_id" || fk.ReferencedTable != "works" || fk.ReferencedColumn != "" {
		t.Fatalf("got %+v", fk)
	}
}

func TestResolveImpliedFKColumnsFillsParentPK(t *testing.T) {
	shared := NewSharedContext("shakespeare", "sqlite")
	shared.Tables["chapters"] = &TableMetadata{
		Name: "chapters",
		Columns: []ColumnMetadata{{Name: "work_id", Type: "INTEGER"}},
		ForeignKeys: []ForeignKeyMetadata{{
			ColumnName: "work_id", ReferencedTable: "works", ReferencedColumn: "<nil>",
		}},
	}
	shared.Tables["works"] = &TableMetadata{
		Name:       "works",
		PrimaryKey: []string{"id"},
		Columns:    []ColumnMetadata{{Name: "id", IsPrimaryKey: true}, {Name: "title"}},
	}

	if n := shared.ResolveImpliedFKColumns(); n != 1 {
		t.Fatalf("resolved %d, want 1", n)
	}
	got := shared.Tables["chapters"].ForeignKeys[0].ReferencedColumn
	if got != "id" {
		t.Fatalf("want works.id, got %q", got)
	}

	out := shared.ExportToCompactPrompt(DefaultExportOptions())
	if strings.Contains(out, "<nil>") {
		t.Fatalf("prompt still has <nil>:\n%s", out)
	}
	if !strings.Contains(out, "→ works.id") {
		t.Fatalf("prompt missing resolved FK:\n%s", out)
	}
}

func TestLoadContextFromFileResolvesNilFK(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "yelp.json")
	raw := `{
	  "database_name": "public_review_platform",
	  "tables": {
	    "Attributes": {
	      "name": "Attributes",
	      "columns": [{"name": "attribute_id", "type": "INTEGER", "is_primary_key": true}]
	    },
	    "Business_Attributes": {
	      "name": "Business_Attributes",
	      "columns": [{"name": "attribute_id", "type": "INTEGER"}],
	      "foreign_keys": [{
	        "column_name": "attribute_id",
	        "referenced_table": "Attributes",
	        "referenced_column": "<nil>"
	      }]
	    }
	  }
	}`
	if err := os.WriteFile(path, []byte(raw), 0644); err != nil {
		t.Fatal(err)
	}
	ctx, err := LoadContextFromFile(path)
	if err != nil {
		t.Fatal(err)
	}
	got := ctx.Tables["Business_Attributes"].ForeignKeys[0].ReferencedColumn
	if got != "attribute_id" {
		t.Fatalf("load should fill parent PK, got %q", got)
	}
}

func TestAnalyzeJoinPathsUsesResolvedFK(t *testing.T) {
	shared := NewSharedContext("t", "sqlite")
	shared.Tables["beers"] = &TableMetadata{
		Name: "beers",
		ForeignKeys: []ForeignKeyMetadata{{
			ColumnName: "brewery_id", ReferencedTable: "breweries", ReferencedColumn: "",
			Cardinality: "N:1", ParentToChild: "1:N",
		}},
	}
	shared.Tables["breweries"] = &TableMetadata{
		Name:    "breweries",
		Columns: []ColumnMetadata{{Name: "id", IsPrimaryKey: true}},
	}
	shared.AnalyzeJoinPaths()
	if shared.JoinPaths["beers.brewery_id→breweries.id"] == nil {
		t.Fatalf("missing resolved edge, have %#v", shared.JoinPaths)
	}
}

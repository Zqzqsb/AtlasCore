package context

import (
	"strings"
	"testing"
)

func TestApplyCardinalityHeuristic(t *testing.T) {
	shared := NewSharedContext("t", "sqlite")
	shared.Tables["orders"] = &TableMetadata{
		Name:       "orders",
		PrimaryKey: []string{"id"},
		Columns:    []ColumnMetadata{{Name: "id", IsPrimaryKey: true}, {Name: "customer_id"}},
	}
	fk := ForeignKeyMetadata{ColumnName: "customer_id", ReferencedTable: "customers", ReferencedColumn: "id"}
	got := applyCardinalityHeuristic(fk, shared, "orders")
	if got.Cardinality != "N:1" || got.ParentToChild != "1:N" {
		t.Fatalf("got %+v", got)
	}

	shared.Tables["orders"].PrimaryKey = []string{"customer_id"}
	fk2 := ForeignKeyMetadata{ColumnName: "customer_id", ReferencedTable: "customers", ReferencedColumn: "id"}
	got2 := applyCardinalityHeuristic(fk2, shared, "orders")
	if got2.Cardinality != "1:1" {
		t.Fatalf("PK fk should be 1:1, got %+v", got2)
	}
}

func TestAnalyzeJoinPathsDirectEdges(t *testing.T) {
	shared := NewSharedContext("t", "sqlite")
	shared.Tables["orders"] = &TableMetadata{
		Name: "orders",
		ForeignKeys: []ForeignKeyMetadata{{
			ColumnName: "customer_id", ReferencedTable: "customers", ReferencedColumn: "id",
			Cardinality: "N:1", ParentToChild: "1:N", AvgChildren: 3.2,
		}},
	}
	shared.Tables["customers"] = &TableMetadata{Name: "customers"}

	shared.AnalyzeJoinPaths()
	if len(shared.JoinPaths) < 2 {
		t.Fatalf("expected forward+reverse paths, got %d", len(shared.JoinPaths))
	}
	fwd := shared.JoinPaths["orders→customers"]
	if fwd == nil || fwd.Cardinality != "N:1" {
		t.Fatalf("forward: %+v", fwd)
	}
	rev := shared.JoinPaths["customers→orders"]
	if rev == nil || rev.Cardinality != "1:N" {
		t.Fatalf("reverse: %+v", rev)
	}
	prompt := shared.FormatJoinPathsForPrompt()
	if prompt == "" || !strings.Contains(prompt, "1:N") || !strings.Contains(prompt, "N:1") {
		t.Fatalf("prompt missing cardinality:\n%s", prompt)
	}
}

func TestExportCompactIncludesSamplesAndCardinality(t *testing.T) {
	shared := NewSharedContext("demo", "sqlite")
	shared.Tables["child"] = &TableMetadata{
		Name:        "child",
		RowCount:    100,
		Description: "child entities",
		ForeignKeys: []ForeignKeyMetadata{{
			ColumnName: "parent_id", ReferencedTable: "parent", ReferencedColumn: "id",
			Cardinality: "N:1", ParentToChild: "1:N", AvgChildren: 4,
		}},
		Columns: []ColumnMetadata{
			{Name: "parent_id", Type: "INTEGER"},
			{Name: "status", Type: "TEXT", ValueStats: &ValueStats{
				DistinctCount: 2,
				TopValues:     []ValueFrequency{{Value: "a", Count: 60}, {Value: "b", Count: 40}},
			}},
			{Name: "note", Type: "TEXT", ValueStats: &ValueStats{
				DistinctCount: 200,
				SampleValues:  []string{"hello", "world"},
			}},
		},
	}
	out := shared.ExportToCompactPrompt(DefaultExportOptions())
	for _, want := range []string{"child entities", "[N:1]", "samples=[hello, world]", "values=[", "Relationships:", "1:N"} {
		if !strings.Contains(out, want) {
			t.Fatalf("missing %q in:\n%s", want, out)
		}
	}
}

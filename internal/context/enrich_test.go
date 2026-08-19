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
	fwd := shared.JoinPaths["orders.customer_id→customers.id"]
	if fwd == nil || fwd.Cardinality != "N:1" {
		t.Fatalf("forward: %+v", fwd)
	}
	rev := shared.JoinPaths["customers.id→orders.customer_id"]
	if rev == nil || rev.Cardinality != "1:N" {
		t.Fatalf("reverse: %+v", rev)
	}
	prompt := shared.FormatJoinPathsForPrompt()
	if prompt == "" || !strings.Contains(prompt, "1:N") || !strings.Contains(prompt, "N:1") {
		t.Fatalf("prompt missing cardinality:\n%s", prompt)
	}
}

func TestAnalyzeJoinPathsPreservesMultipleEdgesBetweenSameTables(t *testing.T) {
	shared := NewSharedContext("t", "sqlite")
	shared.Tables["events"] = &TableMetadata{
		Name: "events",
		ForeignKeys: []ForeignKeyMetadata{
			{ColumnName: "created_by", ReferencedTable: "users", ReferencedColumn: "id"},
			{ColumnName: "updated_by", ReferencedTable: "users", ReferencedColumn: "id"},
		},
	}
	shared.Tables["users"] = &TableMetadata{Name: "users"}

	shared.AnalyzeJoinPaths()
	for _, key := range []string{
		"events.created_by→users.id",
		"events.updated_by→users.id",
		"users.id→events.created_by",
		"users.id→events.updated_by",
	} {
		if shared.JoinPaths[key] == nil {
			t.Fatalf("missing edge %q in %#v", key, shared.JoinPaths)
		}
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
	for _, want := range []string{"child entities", "[N:1]", "samples=[hello, world]", "values=[", "1:N JOINs", "~4.0x"} {
		if !strings.Contains(out, want) {
			t.Fatalf("missing %q in:\n%s", want, out)
		}
	}
	if strings.Contains(out, "Relationships:") {
		t.Fatalf("full FK dump should be gone:\n%s", out)
	}
}

func TestExportCompactDropsDuplicateColumnNotes(t *testing.T) {
	shared := NewSharedContext("demo", "sqlite")
	shared.Tables["biz"] = &TableMetadata{
		Name: "biz",
		Columns: []ColumnMetadata{{
			Name:            "active",
			Type:            "TEXT",
			OfficialMeaning: "whether the business is open",
			ValueStats: &ValueStats{
				DistinctCount: 2,
				TopValues:     []ValueFrequency{{Value: "true", Count: 9}, {Value: "false", Count: 1}},
			},
		}},
		RichContext: map[string]RichContextValue{
			"active_values":  {BusinessNote: BusinessNote{Content: "true=open(90%), false=closed(10%)"}},
			"active_meaning": {BusinessNote: BusinessNote{Content: "Boolean flag indicating whether the business is currently active"}},
			"business_rules": {BusinessNote: BusinessNote{Content: "Yelp-style listings in Phoenix"}},
			"attr_13_values": {BusinessNote: BusinessNote{Content: "13=Has bike parking"}},
		},
	}
	out := shared.ExportToCompactPrompt(DefaultExportOptions())
	if !strings.Contains(out, "whether the business is open") {
		t.Fatalf("official meaning missing:\n%s", out)
	}
	if !strings.Contains(out, "values=[true(9)") {
		t.Fatalf("inline values missing:\n%s", out)
	}
	if !strings.Contains(out, "Yelp-style listings") || !strings.Contains(out, "Has bike parking") {
		t.Fatalf("non-duplicate notes should remain:\n%s", out)
	}
	for _, dup := range []string{"true=open(90%)", "Boolean flag indicating whether the business is currently active"} {
		if strings.Contains(out, dup) {
			t.Fatalf("duplicate note %q still present:\n%s", dup, out)
		}
	}
}

func TestCrossTableQualitySkipsSelectedTableIssues(t *testing.T) {
	shared := NewSharedContext("demo", "sqlite")
	shared.Tables["biz"] = &TableMetadata{
		Name: "biz",
		QualityIssues: []QualityIssue{{
			Table: "biz", Column: "city", Type: "whitespace",
			Description: "Contains leading/trailing whitespace",
			SQLFix:      `TRIM("city")`,
			AffectedOps: []string{"JOIN"},
		}},
	}
	shared.Tables["other"] = &TableMetadata{
		Name: "other",
		QualityIssues: []QualityIssue{{
			Table: "other", Column: "biz_id", Type: "orphan",
			Description: "orphan FK",
			SQLFix:      "check parent",
		}},
	}
	got := shared.BuildCrossTableQualitySummary([]string{"biz"})
	if strings.Contains(got, "whitespace") {
		t.Fatalf("selected-table issue duplicated:\n%s", got)
	}
	if !strings.Contains(got, "orphan FK") {
		t.Fatalf("unselected JOIN/orphan should remain:\n%s", got)
	}
}

func TestExportCompactFeatureSwitches(t *testing.T) {
	shared := NewSharedContext("demo", "sqlite")
	shared.Tables["child"] = &TableMetadata{
		Name: "child",
		Columns: []ColumnMetadata{{
			Name:            "code",
			Type:            "TEXT",
			OfficialMeaning: "business code",
			ValueStats: &ValueStats{
				DominantShape: "digits",
				SampleValues:  []string{"001", "002"},
			},
		}},
		ForeignKeys: []ForeignKeyMetadata{{
			ColumnName: "code", ReferencedTable: "parent", ReferencedColumn: "code",
		}},
	}
	opts := DefaultExportOptions()
	opts.IncludeValueStats = false
	opts.IncludeOfficialMeaning = false
	opts.IncludeProfileNL = false
	opts.IncludeRelationships = false
	out := shared.ExportToCompactPrompt(opts)
	for _, unwanted := range []string{"samples=[", "business code", "stored-as-text", "Relationships:", "1:N JOINs"} {
		if strings.Contains(out, unwanted) {
			t.Fatalf("switch should remove %q from:\n%s", unwanted, out)
		}
	}
}

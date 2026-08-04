package inference

import (
	"strings"
	"testing"

	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
)

func TestMeaningsForTables(t *testing.T) {
	s := ColumnMeaningStore{
		"legislator|current|bioguide_id": "unique legislator id",
		"otherdb|t|c":                    "skip",
	}
	m := s.MeaningsForTables("legislator", []string{"current"})
	if len(m) != 1 || !strings.Contains(m["current|bioguide_id"], "legislator id") {
		t.Fatalf("got %#v", m)
	}
}

func TestExportFusesMeaning(t *testing.T) {
	shared := &contextpkg.SharedContext{
		DatabaseName: "legislator",
		Tables: map[string]*contextpkg.TableMetadata{
			"current": {
				Name: "current",
				Columns: []contextpkg.ColumnMetadata{
					{Name: "bioguide_id", Type: "TEXT", IsPrimaryKey: true},
					{Name: "name", Type: "TEXT"},
				},
			},
		},
	}
	out := shared.ExportToCompactPrompt(&contextpkg.ExportOptions{
		Tables:         []string{"current"},
		IncludeColumns: true,
		ColumnMeanings: map[string]string{
			"current|bioguide_id": "unique legislator id",
		},
	})
	if !strings.Contains(out, "bioguide_id: TEXT [PK] // unique legislator id") {
		t.Fatalf("missing fused meaning:\n%s", out)
	}
	if !strings.Contains(out, "- name: TEXT") {
		t.Fatalf("missing plain column:\n%s", out)
	}
}

func TestParseColumnsFromDraftSQL(t *testing.T) {
	tables := []string{"Employee", "Person"}
	all := map[string]*TableInfo{
		"Employee": {Name: "Employee", Columns: []string{"BusinessEntityID", "JobTitle", "HireDate"}},
		"Person":   {Name: "Person", Columns: []string{"BusinessEntityID", "FirstName", "LastName"}},
	}
	sql := `SELECT e.JobTitle, p.FirstName FROM Employee e JOIN Person p ON e.BusinessEntityID = p.BusinessEntityID`
	got := parseColumnsFromDraftSQL(sql, tables, all)
	joined := strings.Join(got, ",")
	for _, want := range []string{"Employee.JobTitle", "Person.FirstName", "Employee.BusinessEntityID"} {
		if !strings.Contains(joined, want) {
			t.Errorf("missing %s in %v", want, got)
		}
	}
	for _, bad := range got {
		if strings.HasSuffix(strings.ToLower(bad), ".select") || strings.Contains(strings.ToLower(bad), "from") {
			t.Errorf("keyword leaked: %s", bad)
		}
	}
}

package inference

import (
	"strings"
	"testing"

	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
)

func TestAnalyzeJoinDistinctIssues_MissingDistinctOn1N(t *testing.T) {
	hints := []JoinCardHint{{
		ChildTable: "laboratory", ParentTable: "patient", ChildColumn: "ID",
		ParentToChild: "1:N", AvgChildren: 4.2,
	}}
	sql := `SELECT p.Diagnosis FROM patient p JOIN laboratory l ON p.ID = l.ID WHERE l.Date > '1990'`
	q := "What are the diagnoses of patients with lab tests after 1990?"
	warns := AnalyzeJoinDistinctIssues(sql, q, hints, true, 12)
	if len(warns) == 0 {
		t.Fatal("expected 1:N / DISTINCT warnings")
	}
	joined := strings.Join(warns, "\n")
	if !strings.Contains(joined, "1:N") {
		t.Fatalf("expected 1:N mention, got %s", joined)
	}
}

func TestAnalyzeJoinDistinctIssues_UnnecessaryCountDistinct(t *testing.T) {
	sql := `SELECT COUNT(DISTINCT AppID) FROM apps WHERE Label = 7`
	q := "How many apps are labeled 7?"
	warns := AnalyzeJoinDistinctIssues(sql, q, nil, false, 1)
	if len(warns) == 0 {
		t.Fatal("expected unnecessary COUNT(DISTINCT) warning")
	}
	if !strings.Contains(warns[0], "COUNT(DISTINCT") {
		t.Fatalf("got %v", warns)
	}
}

func TestAnalyzeJoinDistinctIssues_CountNeedsDistinct(t *testing.T) {
	hints := []JoinCardHint{{
		ChildTable: "orders", ParentTable: "customers", ChildColumn: "customer_id",
		ParentToChild: "1:N", AvgChildren: 3,
	}}
	sql := `SELECT COUNT(*) FROM customers c JOIN orders o ON c.id = o.customer_id WHERE o.year = 2020`
	q := "How many customers placed orders in 2020?"
	warns := AnalyzeJoinDistinctIssues(sql, q, hints, false, 50)
	found := false
	for _, w := range warns {
		if strings.Contains(w, "COUNT(DISTINCT") {
			found = true
		}
	}
	if !found {
		t.Fatalf("expected COUNT(DISTINCT entity) warning, got %v", warns)
	}
}

func TestCollectJoinCardHints(t *testing.T) {
	shared := &contextpkg.SharedContext{
		Tables: map[string]*contextpkg.TableMetadata{
			"orders": {
				ForeignKeys: []contextpkg.ForeignKeyMetadata{{
					ColumnName: "customer_id", ReferencedTable: "customers", ReferencedColumn: "id",
					Cardinality: "N:1", ParentToChild: "1:N", AvgChildren: 2.5,
				}},
			},
			"customers": {},
		},
	}
	hints := CollectJoinCardHints(shared, []string{"orders", "customers"})
	if len(hints) != 1 {
		t.Fatalf("expected 1 hint, got %d", len(hints))
	}
	if hints[0].ParentTable != "customers" {
		t.Fatalf("got %+v", hints[0])
	}
}

package inference

import (
	"strings"
	"testing"

	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
)

func TestExpandTablesWithFK(t *testing.T) {
	all := map[string]*TableInfo{
		"orders": {
			Name:    "orders",
			Columns: []string{"id", "customer_id"},
			ForeignKeys: []contextpkg.ForeignKeyMetadata{
				{ColumnName: "customer_id", ReferencedTable: "customers", ReferencedColumn: "id"},
			},
		},
		"customers": {Name: "customers", Columns: []string{"id", "name"}},
		"items": {
			Name:    "items",
			Columns: []string{"id", "order_id"},
			ForeignKeys: []contextpkg.ForeignKeyMetadata{
				{ColumnName: "order_id", ReferencedTable: "orders", ReferencedColumn: "id"},
			},
		},
	}
	got := ExpandTablesWithFK([]string{"orders"}, all)
	has := map[string]bool{}
	for _, g := range got {
		has[g] = true
	}
	if !has["orders"] || !has["customers"] || !has["items"] {
		t.Fatalf("expected orders+customers+items, got %v", got)
	}
}

func TestExtractEvidenceLiterals(t *testing.T) {
	lits := ExtractEvidenceLiterals(
		`How many with status 'Owner'?`,
		`percentage = completed / total * 100%; type = 'OWNER'`,
	)
	joined := strings.ToLower(strings.Join(lits, "\n"))
	if !strings.Contains(joined, "owner") {
		t.Fatalf("expected Owner/OWNER literal, got %v", lits)
	}
	if !strings.Contains(joined, "%") {
		t.Fatalf("expected percent token, got %v", lits)
	}
}

func TestRelevantColumnSet(t *testing.T) {
	got := relevantColumnSet([]string{
		"- orders.customer_id | join key",
		"- `customers`.`name` | projection",
		"invalid",
	})
	for _, key := range []string{"orders.customer_id", "customers.name"} {
		if _, ok := got[key]; !ok {
			t.Fatalf("missing %s in %v", key, got)
		}
	}
	if len(got) != 2 {
		t.Fatalf("unexpected parsed columns: %v", got)
	}
}

func TestCompactExportOptionsSparseGrounding(t *testing.T) {
	p := &Pipeline{config: &Config{GroundingMode: "sparse"}}
	relevant := map[string]struct{}{"orders.status": {}}
	opts := p.compactExportOptions([]string{"orders"}, relevant, false)
	if !opts.IncludeOfficialMeaning || !opts.IncludeProfileNL {
		t.Fatalf("sparse mode should enable selected grounding: %+v", opts)
	}
	if _, ok := opts.GroundingColumns["orders.status"]; !ok {
		t.Fatalf("missing relevant column: %+v", opts.GroundingColumns)
	}

	linkerOpts := p.compactExportOptions(nil, nil, true)
	if linkerOpts.IncludeOfficialMeaning || linkerOpts.IncludeProfileNL || linkerOpts.IncludeRelationships {
		t.Fatalf("schema linker should not receive duplicate grounding: %+v", linkerOpts)
	}

	fallback := p.compactExportOptions([]string{"orders"}, nil, false)
	if !fallback.IncludeOfficialMeaning || fallback.IncludeProfileNL || fallback.GroundingColumns != nil {
		t.Fatalf("missing refine should fall back to meanings only: %+v", fallback)
	}

	off := (&Pipeline{config: &Config{GroundingMode: "off"}}).compactExportOptions([]string{"orders"}, relevant, false)
	if off.IncludeOfficialMeaning || off.IncludeProfileNL {
		t.Fatalf("off mode must emit no grounding: %+v", off)
	}
}

func TestFingerprintPreservesColumnOrder(t *testing.T) {
	rows := []map[string]interface{}{{"b": 1, "a": 2}}
	k1 := FingerprintQueryResult([]string{"a", "b"}, rows, 10)
	k2 := FingerprintQueryResult([]string{"b", "a"}, rows, 10)
	if k1 == k2 {
		t.Fatal("column order should change fingerprint")
	}
}

func TestSelectByExecutionVotePrefersNonEmpty(t *testing.T) {
	cands := []ScaleCandidate{
		{SQL: "empty", ExecOK: true, ResultKey: "e", RowCount: 0, NumCols: 2},
		{SQL: "full", ExecOK: true, ResultKey: "f", RowCount: 3, NumCols: 2},
	}
	got, _ := SelectByExecutionVote(cands)
	if got != "full" {
		t.Fatalf("tie on count should prefer non-empty, got %s", got)
	}
}

func TestSelectByExecutionVotePrefersFewerCols(t *testing.T) {
	cands := []ScaleCandidate{
		{SQL: "wide", ExecOK: true, ResultKey: "a", RowCount: 1, NumCols: 4},
		{SQL: "narrow", ExecOK: true, ResultKey: "b", RowCount: 1, NumCols: 1},
	}
	got, _ := SelectByExecutionVote(cands)
	if got != "narrow" {
		t.Fatalf("prefer fewer cols on tie, got %s", got)
	}
}

func TestHasProjectionConcat(t *testing.T) {
	if !HasProjectionConcat(`SELECT a || ' ' || b FROM t`) {
		t.Fatal("expected concat detect")
	}
	if HasProjectionConcat(`SELECT a, b FROM t`) {
		t.Fatal("plain select should be clean")
	}
}

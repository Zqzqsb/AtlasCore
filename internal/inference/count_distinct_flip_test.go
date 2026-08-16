package inference

import (
	"strings"
	"testing"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
)

func TestFlipCountDistinct(t *testing.T) {
	in := `SELECT COUNT(DISTINCT app_id) FROM app_labels WHERE label_id = 7`
	got, ok := flipCountDistinct(in)
	if !ok || !strings.Contains(got, "COUNT(app_id)") || strings.Contains(strings.ToUpper(got), "DISTINCT") {
		t.Fatalf("drop DISTINCT: ok=%v got=%s", ok, got)
	}
	in2 := `SELECT COUNT(app_id) FROM app_labels WHERE label_id = 7`
	got2, ok := flipCountDistinct(in2)
	if !ok || !strings.Contains(strings.ToUpper(got2), "COUNT(DISTINCT APP_ID)") {
		t.Fatalf("add DISTINCT: ok=%v got=%s", ok, got2)
	}
	if _, ok := flipCountDistinct(`SELECT COUNT(*) FROM t`); ok {
		t.Fatal("must not flip COUNT(*)")
	}
	if _, ok := flipCountDistinct(`SELECT COUNT(a), COUNT(b) FROM t`); ok {
		t.Fatal("must not flip two COUNTs")
	}
	having := `SELECT coachID FROM coaches GROUP BY coachID HAVING COUNT(tmID) > 2`
	got3, ok := flipCountDistinct(having)
	if !ok || !strings.Contains(strings.ToUpper(got3), "COUNT(DISTINCT TMID)") {
		t.Fatalf("HAVING COUNT: ok=%v got=%s", ok, got3)
	}
}

func TestBuildOutputContract_TwoMetrics(t *testing.T) {
	c := BuildOutputContract("How many Olympic events did he join in total? Find the percentage of gold medals.", "")
	if c.MinCols != 2 || c.MaxCols != 2 {
		t.Fatalf("count+percent Min/Max=%d/%d want 2/2", c.MinCols, c.MaxCols)
	}
	c2 := BuildOutputContract("How many albums and singles were released?", "")
	if c2.MinCols != 2 || c2.MaxCols != 2 {
		t.Fatalf("how many A and B Min/Max=%d/%d want 2/2", c2.MinCols, c2.MaxCols)
	}
	c3 := BuildOutputContract("Which summer Olympic have the highest and lowest number of participants?", "")
	if c3.MinCols != 2 {
		t.Fatalf("highest and lowest MinCols=%d want 2", c3.MinCols)
	}
	c4 := BuildOutputContract("How many female students joined a marines and air force organization?", "")
	if c4.MinCols == 2 {
		t.Fatal("filter 'and' must not force two output metrics")
	}
	c5 := BuildOutputContract("How many games were published?", "")
	if c5.MaxCols != 1 || c5.MinCols != 0 {
		t.Fatalf("plain how-many Max/Min=%d/%d", c5.MaxCols, c5.MinCols)
	}
}

func TestCheckProjectionMinCols(t *testing.T) {
	v := &VerifySQLTool{contract: &OutputContract{MinCols: 2, MaxCols: 2}}
	w := v.checkProjectionAgainstContract([]string{"gold_percentage"})
	if w == "" || !strings.Contains(w, "too narrow") {
		t.Fatalf("expected narrow warning, got %q", w)
	}
}

func TestFirstColKindAndNameVsID(t *testing.T) {
	idData := &adapter.QueryResult{
		Columns:  []string{"id"},
		RowCount: 3,
		Rows: []map[string]interface{}{
			{"id": int64(1)}, {"id": int64(2)}, {"id": int64(3)},
		},
	}
	if firstColKind(idData) != "id" {
		t.Fatalf("kind=%s", firstColKind(idData))
	}
	nameData := &adapter.QueryResult{
		Columns:  []string{"name"},
		RowCount: 2,
		Rows: []map[string]interface{}{
			{"name": "Road-550-W Yellow"}, {"name": "AWC Logo Cap"},
		},
	}
	if firstColKind(nameData) != "name" {
		t.Fatalf("kind=%s", firstColKind(nameData))
	}
	v := &VerifySQLTool{question: "List the names of all products with color yellow"}
	if w := v.checkNameVsID(idData); w == "" || !strings.Contains(w, "opaque IDs") {
		t.Fatalf("expected ID-for-name warning, got %q", w)
	}
	v2 := &VerifySQLTool{question: "List the product IDs with color yellow"}
	if w := v2.checkNameVsID(nameData); w == "" || !strings.Contains(w, "asks for IDs") {
		t.Fatalf("expected name-for-ID warning, got %q", w)
	}
	v3 := &VerifySQLTool{question: "List all products with the color yellow"}
	if w := v3.checkNameVsID(nameData); w != "" {
		t.Fatalf("ambiguous list must not pick a side: %q", w)
	}
}

func TestCompareVerifyResults(t *testing.T) {
	a := &adapter.QueryResult{
		Columns: []string{"n"}, RowCount: 1,
		Rows: []map[string]interface{}{{"n": int64(21)}},
	}
	b := &adapter.QueryResult{
		Columns: []string{"n"}, RowCount: 1,
		Rows: []map[string]interface{}{{"n": int64(20)}},
	}
	_, _, same := compareVerifyResults(a, b)
	if same {
		t.Fatal("21 vs 20 should diverge")
	}
	_, _, same = compareVerifyResults(a, a)
	if !same {
		t.Fatal("equal scalars")
	}
}

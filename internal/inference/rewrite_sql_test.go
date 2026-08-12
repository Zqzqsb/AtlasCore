package inference

import (
	"strings"
	"testing"
)

func TestSanitizeGeneratedSQL_IIF(t *testing.T) {
	in := `SELECT IIF(a > 0, 'yes', 'no') FROM t WHERE IIF(x, 1, 0) = 1`
	got := SanitizeGeneratedSQL(in)
	if strings.Contains(strings.ToUpper(got), "IIF(") {
		t.Fatalf("IIF remains: %s", got)
	}
	if !strings.Contains(got, "CASE WHEN a > 0 THEN 'yes' ELSE 'no' END") {
		t.Fatalf("missing CASE rewrite: %s", got)
	}
	if !strings.Contains(got, "CASE WHEN x THEN 1 ELSE 0 END") {
		t.Fatalf("missing nested-arg CASE: %s", got)
	}
}

func TestSanitizeGeneratedSQL_IIFInString(t *testing.T) {
	in := `SELECT 'IIF(1,2,3)' AS x FROM t`
	got := SanitizeGeneratedSQL(in)
	if got != in {
		t.Fatalf("string literal should be unchanged:\ngot  %s\nwant %s", got, in)
	}
}

func TestSanitizeGeneratedSQL_Joins(t *testing.T) {
	in := `SELECT * FROM a RIGHT OUTER JOIN b ON a.id=b.id FULL JOIN c ON b.id=c.id`
	got := SanitizeGeneratedSQL(in)
	up := strings.ToUpper(got)
	if strings.Contains(up, "RIGHT") || strings.Contains(up, "FULL") {
		t.Fatalf("join not rewritten: %s", got)
	}
	if strings.Count(up, "LEFT JOIN") < 2 {
		t.Fatalf("expected two LEFT JOIN: %s", got)
	}
}

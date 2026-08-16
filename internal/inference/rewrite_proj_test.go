package inference

import (
	"strings"
	"testing"
)

func TestSplitConcatenatedPersonName(t *testing.T) {
	in := `SELECT e.firstName || ' ' || e.lastName AS full_name FROM employees e WHERE e.city = 'Tokyo'`
	got := splitConcatenatedPersonName(in)
	if !strings.Contains(got, "e.firstName") || !strings.Contains(got, "e.lastName") {
		t.Fatalf("expected split columns: %s", got)
	}
	if strings.Contains(got, "||") {
		t.Fatalf("concat remains: %s", got)
	}
	in2 := `SELECT p.first || ' ' || p.last AS patient_name FROM patients p`
	got2 := splitConcatenatedPersonName(in2)
	if strings.Contains(got2, "||") || !strings.Contains(got2, "p.first") || !strings.Contains(got2, "p.last") {
		t.Fatalf("first/last split failed: %s", got2)
	}
	// not a person name
	keep := `SELECT name || ' ' || country FROM t`
	if splitConcatenatedPersonName(keep) != keep {
		t.Fatalf("should not split non-name concat")
	}
}

func TestDropRankingMetricFromSelect(t *testing.T) {
	in := `SELECT TRIM("App") AS App, CAST(x AS INTEGER) AS Installs FROM store ORDER BY Installs DESC LIMIT 5`
	got := dropRankingMetricFromSelect(in, "What are the top 5 installed free apps?", "")
	sel := got
	if i := strings.Index(strings.ToUpper(got), " FROM"); i > 0 {
		sel = got[:i]
	}
	if strings.Contains(sel, "Installs") {
		t.Fatalf("metric still in SELECT: %s", got)
	}
	if !strings.Contains(got, "App") || !strings.Contains(strings.ToUpper(got), "LIMIT 5") {
		t.Fatalf("entity/limit lost: %s", got)
	}

	in2 := `SELECT d.director, COUNT(*) AS n FROM movie d GROUP BY d.director ORDER BY n DESC LIMIT 1`
	got2 := dropRankingMetricFromSelect(in2, "Who directed the movie with the most voice actors?", "")
	sel = got2
	if i := strings.Index(strings.ToUpper(got2), " FROM"); i > 0 {
		sel = got2[:i]
	}
	if strings.Contains(strings.ToUpper(sel), "COUNT") {
		t.Fatalf("COUNT should be dropped from SELECT: %s", got2)
	}

	keep := `SELECT AVG(price) FROM cars WHERE origin = 'Europe'`
	if dropRankingMetricFromSelect(keep, "What is the average price of cars from Europe?", "") != keep {
		t.Fatalf("must not rewrite metric-only question")
	}
	keep2 := `SELECT name, score FROM t ORDER BY score DESC LIMIT 1`
	if dropRankingMetricFromSelect(keep2, "List the name and score of the university", "") != keep2 {
		t.Fatalf("must not drop when question asks two attrs")
	}
}

func TestSanitizeGeneratedSQLWithQuery(t *testing.T) {
	in := `SELECT IIF(a>0,1,0), e.firstName || ' ' || e.lastName AS n FROM emp e ORDER BY n`
	got := SanitizeGeneratedSQLWithQuery(in, "List out full name of employees who are working in Tokyo?", "")
	if strings.Contains(strings.ToUpper(got), "IIF(") {
		t.Fatalf("IIF remains: %s", got)
	}
	if strings.Contains(got, "||") {
		t.Fatalf("name concat remains: %s", got)
	}
	pct := `SELECT CAST(a AS REAL) / b AS p FROM t WHERE name = 'Blade'`
	got2 := SanitizeGeneratedSQLWithQuery(pct, "What is the percentage of Blade sales?", "")
	if strings.Contains(got2, "* 100") {
		t.Fatalf("must not auto-scale percent: %s", got2)
	}
	if strings.Contains(strings.ToUpper(got2), "COLLATE NOCASE") {
		t.Fatalf("must not inject NOCASE: %s", got2)
	}
}

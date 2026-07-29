package inference

import (
	"fmt"
	"strings"
	"testing"

	"github.com/tmc/langchaingo/agents"
)

func TestLooksLikeSQL(t *testing.T) {
	cases := []struct {
		in   string
		want bool
	}{
		{`SELECT 1`, true},
		{`"SELECT a FROM t"`, true},
		{`WITH x AS (SELECT 1) SELECT * FROM x`, true},
		{`Thought: I am done`, false},
		{``, false},
		{`Action: verify_sql`, false},
	}
	for _, c := range cases {
		if got := looksLikeSQL(c.in); got != c.want {
			t.Fatalf("looksLikeSQL(%q)=%v want %v", c.in, got, c.want)
		}
	}
}

func TestRecoverSQLAfterReactFailure_FromError(t *testing.T) {
	sql := `SELECT CAST(COUNT(ct.bioguide) AS REAL) / COUNT(DISTINCT c.bioguide_id) AS avg_terms FROM current c`
	err := fmt.Errorf("%w: %s", agents.ErrUnableToParseOutput, sql)
	got := recoverSQLAfterReactFailure(err, nil)
	if got != sql {
		t.Fatalf("got %q want %q", got, sql)
	}
}

func TestRecoverSQLAfterReactFailure_MarkdownFence(t *testing.T) {
	raw := "```sql\nSELECT COUNT(DISTINCT ProductID) FROM ProductVendor WHERE OnOrderQty = 0\n```"
	err := fmt.Errorf("%w: %s", agents.ErrUnableToParseOutput, raw)
	got := recoverSQLAfterReactFailure(err, nil)
	want := `SELECT COUNT(DISTINCT ProductID) FROM ProductVendor WHERE OnOrderQty = 0`
	if got != want {
		t.Fatalf("got %q want %q", got, want)
	}
}

func TestRecoverSQLAfterReactFailure_EmptyFallsBackToVerify(t *testing.T) {
	err := fmt.Errorf("%w: ", agents.ErrUnableToParseOutput)
	v := &VerifySQLTool{LastValidSQL: `SELECT name FROM actor`}
	got := recoverSQLAfterReactFailure(err, v)
	if got != `SELECT name FROM actor` {
		t.Fatalf("got %q", got)
	}
}

func TestRecoverSQLAfterReactFailure_FromVerify(t *testing.T) {
	err := fmt.Errorf("%w: Thought: done", agents.ErrUnableToParseOutput)
	v := &VerifySQLTool{LastValidSQL: `SELECT COUNT(*) FROM t`}
	got := recoverSQLAfterReactFailure(err, v)
	if got != `SELECT COUNT(*) FROM t` {
		t.Fatalf("got %q", got)
	}
}

func TestRecoverSQLAfterReactFailure_NonParse(t *testing.T) {
	err := fmt.Errorf("agent not finished before max iterations")
	v := &VerifySQLTool{LastValidSQL: `SELECT 1`}
	if got := recoverSQLAfterReactFailure(err, v); got != "" {
		t.Fatalf("expected empty, got %q", got)
	}
}

func TestFormatReactParseError_BareSQL(t *testing.T) {
	msg := formatReactParseError("unable to parse agent output: SELECT a FROM t")
	if !strings.Contains(msg, "Final Answer: SELECT a FROM t") {
		t.Fatalf("missing Final Answer hint: %s", msg)
	}
}

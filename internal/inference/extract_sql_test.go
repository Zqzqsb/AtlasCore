package inference

import "testing"

func TestTrimToFirstSQLStatement(t *testing.T) {
	cases := []struct {
		name string
		in   string
		want string
	}{
		{
			name: "prose after semicolon",
			in:   `SELECT EXISTS (SELECT 1 FROM t WHERE x = 1) AS has_tv; But note: the schema uses table name "Business_Attributes". Action: verify_sql`,
			want: `SELECT EXISTS (SELECT 1 FROM t WHERE x = 1) AS has_tv`,
		},
		{
			name: "action after semicolon",
			in:   `SELECT ct.contact_form FROM "current-terms" ct; Otherwise use: Action: verify_sql Action Input: SELECT 1`,
			want: `SELECT ct.contact_form FROM "current-terms" ct`,
		},
		{
			name: "markdown fence after sql",
			in:   "SELECT COUNT(*) FROM registration WHERE course_id IN (SELECT course_id FROM course WHERE diff = 5); Thus final answer.```sql SELECT 1",
			want: `SELECT COUNT(*) FROM registration WHERE course_id IN (SELECT course_id FROM course WHERE diff = 5)`,
		},
		{
			name: "semicolon inside string literal",
			in:   `SELECT 'a;b' AS x FROM t WHERE y = 1; Action: execute_sql`,
			want: `SELECT 'a;b' AS x FROM t WHERE y = 1`,
		},
		{
			name: "escaped quote in literal",
			in:   `SELECT 'it''s;fine' FROM t; But note: junk`,
			want: `SELECT 'it''s;fine' FROM t`,
		},
		{
			name: "clean sql unchanged",
			in:   `SELECT a FROM t WHERE b = 1`,
			want: `SELECT a FROM t WHERE b = 1`,
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := trimToFirstSQLStatement(tc.in)
			if got != tc.want {
				t.Fatalf("got:\n%s\nwant:\n%s", got, tc.want)
			}
		})
	}
}

func TestExtractSQLStripsReactLeak(t *testing.T) {
	p := &Pipeline{}
	raw := `Thought: done
Final Answer: SELECT COUNT(DISTINCT student_id) FROM registration WHERE course_id IN (SELECT course_id FROM course WHERE diff = 5); But might also use a join. Action: verify_sql Action Input: SELECT 1`
	got := p.extractSQL(raw)
	want := `SELECT COUNT(DISTINCT student_id) FROM registration WHERE course_id IN (SELECT course_id FROM course WHERE diff = 5)`
	if got != want {
		t.Fatalf("got %q want %q", got, want)
	}
}

package inference

import "testing"

func TestBuildOutputContractCount(t *testing.T) {
	c := BuildOutputContract("How many players are there?", "how many refers to COUNT()")
	if c == nil || len(c.Hints) == 0 {
		t.Fatal("expected hints")
	}
	found := false
	for _, kw := range c.Keywords {
		if kw == "count" || kw == "total" || kw == "number" {
			found = true
		}
	}
	if !found {
		t.Fatalf("expected count-like keyword, got %v", c.Keywords)
	}
	if c.FormatForPrompt() == "" {
		t.Fatal("empty prompt block")
	}
}

func TestSplitQuestionEvidence(t *testing.T) {
	q, e := splitQuestionEvidence("Q1\n\nEvidence (MUST follow these constraints):\nE1")
	if q != "Q1" || e != "E1" {
		t.Fatalf("got q=%q e=%q", q, e)
	}
}

func TestSelectByExecutionVote(t *testing.T) {
	cands := []ScaleCandidate{
		{SQL: "A", ExecOK: true, ResultKey: "k1"},
		{SQL: "B", ExecOK: true, ResultKey: "k2"},
		{SQL: "C", ExecOK: true, ResultKey: "k1"},
	}
	got, _ := SelectByExecutionVote(cands)
	if got != "A" && got != "C" {
		t.Fatalf("expected A or C (majority k1), got %s", got)
	}
	// majority is k1 with first = A
	if got != "A" {
		t.Fatalf("tie-break should prefer first k1 sql A, got %s", got)
	}
}

package inference

import (
	"fmt"
	"strings"
	"testing"
)

func TestFormatRetryHint(t *testing.T) {
	hint := FormatRetryHint(fmt.Errorf("agent not finished before max iterations"), []ReActStep{
		{Thought: "need age of overdose patients", Action: "execute_sql", ActionInput: "SELECT p.first FROM patients p JOIN conditions c"},
		{Action: "verify_sql", ActionInput: "SELECT p.first, p.last FROM patients p WHERE 1=1"},
	})
	if !strings.Contains(hint, "this is a retry") {
		t.Fatalf("missing retry header:\n%s", hint)
	}
	if !strings.Contains(hint, "max iterations") {
		t.Fatalf("missing error:\n%s", hint)
	}
	if !strings.Contains(hint, "Last thought: need age") {
		t.Fatalf("missing last thought:\n%s", hint)
	}
	if !strings.Contains(hint, "execute_sql") || !strings.Contains(hint, "verify_sql") {
		t.Fatalf("missing steps:\n%s", hint)
	}
	if strings.Contains(strings.ToLower(hint), "use this sql as") {
		t.Fatal("must not instruct copying last SQL")
	}
}

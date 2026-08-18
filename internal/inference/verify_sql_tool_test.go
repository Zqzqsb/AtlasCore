package inference

import (
	"context"
	"strings"
	"testing"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
)

type timeoutAdapter struct {
	stubProbeAdapter
}

func (s *timeoutAdapter) ExecuteQuery(context.Context, string) (*adapter.QueryResult, error) {
	return &adapter.QueryResult{Error: context.DeadlineExceeded.Error()}, context.DeadlineExceeded
}

func TestVerifySQLTimeoutHint(t *testing.T) {
	tool := NewVerifySQLTool(&timeoutAdapter{}, "SQLite")
	out, err := tool.Call(context.Background(), "SELECT 1")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "SQL validation failed") {
		t.Fatalf("want validation failure, got %s", out)
	}
	if !strings.Contains(out, "nested scan") && !strings.Contains(out, "unmaterialized CTE") {
		t.Fatalf("missing timeout hint: %s", out)
	}
	if tool.LastValidSQL != "" {
		t.Fatalf("timeout must not stash LastValidSQL: %q", tool.LastValidSQL)
	}
}

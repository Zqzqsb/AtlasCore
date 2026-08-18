package inference

import (
	"context"
	"strings"
	"testing"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
)

type stubProbeAdapter struct {
	calls int
}

func (s *stubProbeAdapter) Connect(context.Context) error  { return nil }
func (s *stubProbeAdapter) Close() error                   { return nil }
func (s *stubProbeAdapter) GetDatabaseType() string        { return "SQLite" }
func (s *stubProbeAdapter) GetDatabaseVersion(context.Context) (string, error) {
	return "", nil
}
func (s *stubProbeAdapter) DryRunSQL(context.Context, string) error { return nil }
func (s *stubProbeAdapter) ExecuteQuery(context.Context, string) (*adapter.QueryResult, error) {
	s.calls++
	return &adapter.QueryResult{
		Columns:  []string{"award"},
		Rows:     []map[string]interface{}{{"award": "Best Television Episode"}},
		RowCount: 1,
	}, nil
}

func TestProbeColumnToolDedupsSameColumn(t *testing.T) {
	stub := &stubProbeAdapter{}
	tool := NewProbeColumnTool(stub, "SQLite")
	ctx := context.Background()

	first, err := tool.Call(ctx, "Award.award")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(first, "Best Television Episode") {
		t.Fatalf("first probe: %s", first)
	}

	second, err := tool.Call(ctx, "Award.award|40")
	if err != nil {
		t.Fatal(err)
	}
	if stub.calls != 1 {
		t.Fatalf("db calls=%d, want 1", stub.calls)
	}
	if !strings.Contains(second, "Already probed Award.award") {
		t.Fatalf("repeat should refuse: %s", second)
	}
	if !strings.Contains(second, "verify_sql") {
		t.Fatalf("repeat should push verify_sql: %s", second)
	}

	other, err := tool.Call(ctx, "Award.result")
	if err != nil {
		t.Fatal(err)
	}
	if stub.calls != 2 {
		t.Fatalf("new column should hit db, calls=%d", stub.calls)
	}
	if strings.Contains(other, "Already probed") {
		t.Fatalf("different column should probe: %s", other)
	}
}

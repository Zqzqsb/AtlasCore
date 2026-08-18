package adapter

import (
	"context"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestSQLiteAdapterInterruptsSlowQuery(t *testing.T) {
	a := NewSQLiteAdapter(&SQLiteConfig{FilePath: filepath.Join(t.TempDir(), "t.sqlite")})
	if err := a.Connect(context.Background()); err != nil {
		t.Fatal(err)
	}
	defer a.Close()

	slow := `WITH RECURSIVE t(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM t WHERE x < 50000000)
SELECT COUNT(*) FROM t`
	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
	defer cancel()
	start := time.Now()
	_, err := a.ExecuteQuery(ctx, slow)
	elapsed := time.Since(start)
	if err == nil {
		t.Fatal("expected interrupt/timeout, got nil")
	}
	if elapsed > 3*time.Second {
		t.Fatalf("interrupt too slow: %v err=%v", elapsed, err)
	}
	low := strings.ToLower(err.Error())
	if !strings.Contains(low, "interrupt") && !strings.Contains(low, "deadline") && !strings.Contains(low, "canceled") {
		t.Fatalf("unexpected error: %v", err)
	}

	got, err := a.ExecuteQuery(context.Background(), "SELECT 1 AS n")
	if err != nil {
		t.Fatalf("conn unusable after interrupt: %v", err)
	}
	if got.RowCount != 1 {
		t.Fatalf("rowcount=%d", got.RowCount)
	}
}

package inference

import (
	"context"
	"fmt"
	"regexp"
	"strings"
	"sync"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
)

var identRe = regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_]*$`)

// ProbeColumnTool returns DISTINCT values for a table.column (WiseCat-style).
// Use before putting string literals into WHERE — never guess enum/dirty values.
type ProbeColumnTool struct {
	adapter adapter.DBAdapter
	dbType  string
	logger  *InferenceLogger

	mu     sync.Mutex
	probed map[string]string // table.column (lower) → last DISTINCT dump
}

// NewProbeColumnTool builds the probe tool bound to the business DB adapter.
func NewProbeColumnTool(dbAdapter adapter.DBAdapter, dbType string) *ProbeColumnTool {
	return &ProbeColumnTool{adapter: dbAdapter, dbType: dbType}
}

func (t *ProbeColumnTool) Name() string { return "probe_column_values" }

func (t *ProbeColumnTool) Description() string {
	return `Probe DISTINCT values of one column before using string literals in WHERE.
Input format: table.column   OR   table.column|limit
Examples: status_type.status   OR   accounts.frequency|30
Use when evidence/question mentions enum-like values, dirty strings, or you are unsure of the exact stored literal.
Probe each table.column at most once, then write SQL and verify_sql. Do not repeat the same probe.
Do NOT invent literals from column names.`
}

func (t *ProbeColumnTool) Call(ctx context.Context, input string) (string, error) {
	raw := strings.TrimSpace(input)
	logf := func(format string, a ...interface{}) {
		if t.logger != nil {
			t.logger.Printf(format, a...)
		} else {
			fmt.Printf(format, a...)
		}
	}
	logf("\n🔎 Tool Call [probe_column_values]:\nInput: %s\n", raw)

	table, column, limit, err := parseProbeInput(raw)
	if err != nil {
		msg := fmt.Sprintf("❌ %v\nExpected: table.column or table.column|limit", err)
		logf("Output: %s\n", msg)
		return msg, nil
	}

	key := strings.ToLower(table) + "." + strings.ToLower(column)
	t.mu.Lock()
	if t.probed == nil {
		t.probed = map[string]string{}
	}
	if prev, ok := t.probed[key]; ok {
		t.mu.Unlock()
		msg := prev + "\n⚠️  Already probed " + table + "." + column + ". Do NOT probe it again. Write SQL now and call verify_sql."
		logf("Output: %s\n", msg)
		return msg, nil
	}
	t.mu.Unlock()

	out, err := ProbeColumn(ctx, t.adapter, t.dbType, table, column, limit)
	if err != nil {
		msg := fmt.Sprintf("❌ probe failed: %v", err)
		logf("Output: %s\n", msg)
		return msg, nil
	}
	t.mu.Lock()
	t.probed[key] = out
	t.mu.Unlock()
	logf("Output: %s\n", out)
	return out, nil
}

func parseProbeInput(raw string) (table, column string, limit int, err error) {
	limit = 40
	parts := strings.SplitN(raw, "|", 2)
	path := strings.TrimSpace(parts[0])
	if len(parts) == 2 {
		fmt.Sscanf(strings.TrimSpace(parts[1]), "%d", &limit)
	}
	path = strings.ReplaceAll(path, "`", "")
	path = strings.ReplaceAll(path, `"`, "")
	segs := strings.Split(path, ".")
	if len(segs) != 2 {
		return "", "", 0, fmt.Errorf("need table.column, got %q", raw)
	}
	table, column = strings.TrimSpace(segs[0]), strings.TrimSpace(segs[1])
	if !identRe.MatchString(table) || !identRe.MatchString(column) {
		return "", "", 0, fmt.Errorf("invalid identifier in %q", raw)
	}
	if limit <= 0 {
		limit = 40
	}
	if limit > 200 {
		limit = 200
	}
	return table, column, limit, nil
}

// ProbeColumn runs a guarded DISTINCT probe.
func ProbeColumn(ctx context.Context, dbAdapter adapter.DBAdapter, dbType, table, column string, limit int) (string, error) {
	if !identRe.MatchString(table) {
		return "", fmt.Errorf("invalid table name")
	}
	if !identRe.MatchString(column) {
		return "", fmt.Errorf("invalid column name")
	}
	if limit <= 0 {
		limit = 40
	}
	if limit > 200 {
		limit = 200
	}

	qt, qc := quoteIdent(table, dbType), quoteIdent(column, dbType)
	sql := fmt.Sprintf("SELECT DISTINCT %s FROM %s LIMIT %d", qc, qt, limit)
	data, err := dbAdapter.ExecuteQuery(ctx, sql)
	if err != nil {
		return "", err
	}

	var b strings.Builder
	b.WriteString(fmt.Sprintf("DISTINCT %s.%s (limit %d, got %d):\n", table, column, limit, data.RowCount))
	for i, row := range data.Rows {
		if i >= limit {
			break
		}
		val := row[column]
		if val == nil {
			// try case variants
			for k, v := range row {
				if strings.EqualFold(k, column) {
					val = v
					break
				}
			}
		}
		b.WriteString(fmt.Sprintf("  - %v\n", val))
	}
	if data.RowCount == 0 {
		b.WriteString("  (empty — column may be all NULL or table empty)\n")
	}
	return b.String(), nil
}

func quoteIdent(name, dbType string) string {
	switch strings.ToLower(dbType) {
	case "postgresql", "postgres":
		return `"` + name + `"`
	default:
		// MySQL + SQLite
		return "`" + name + "`"
	}
}

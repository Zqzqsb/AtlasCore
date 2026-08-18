package adapter

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "modernc.org/sqlite"
)

// DefaultQueryTimeout bounds a SQLite query when the caller ctx has no deadline.
// modernc honors ctx via sqlite3_interrupt; without this, an unmaterialized CTE
// can burn CPU for tens of minutes and stall a whole eval shard.
const DefaultQueryTimeout = 30 * time.Second

// SQLiteAdapter SQLite adapter
type SQLiteAdapter struct {
	db     *sql.DB
	config *SQLiteConfig
}

// SQLiteConfig SQLite connection config
type SQLiteConfig struct {
	FilePath string // DB file path, ":memory:" for in-memory
}

// NewSQLiteAdapter creates SQLite adapter
func NewSQLiteAdapter(config *SQLiteConfig) *SQLiteAdapter {
	return &SQLiteAdapter{
		config: config,
	}
}

// Connect connects to database
func (a *SQLiteAdapter) Connect(ctx context.Context) error {
	db, err := sql.Open("sqlite", a.config.FilePath)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}
	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)

	// Test connection
	if err := db.PingContext(ctx); err != nil {
		_ = db.Close()
		return fmt.Errorf("failed to ping database: %w", err)
	}

	a.db = db
	return nil
}

// Close closes connection
func (a *SQLiteAdapter) Close() error {
	if a.db != nil {
		return a.db.Close()
	}
	return nil
}

func withQueryTimeout(ctx context.Context) (context.Context, context.CancelFunc) {
	if ctx == nil {
		ctx = context.Background()
	}
	if _, ok := ctx.Deadline(); ok {
		return ctx, func() {}
	}
	return context.WithTimeout(ctx, DefaultQueryTimeout)
}

// ExecuteQuery executes query
func (a *SQLiteAdapter) ExecuteQuery(ctx context.Context, query string) (*QueryResult, error) {
	start := time.Now()
	ctx, cancel := withQueryTimeout(ctx)
	defer cancel()

	rows, err := a.db.QueryContext(ctx, query)
	if err != nil {
		return &QueryResult{
			Error:         err.Error(),
			ExecutionTime: time.Since(start).Milliseconds(),
		}, err // Return error, not nil
	}
	defer rows.Close()

	// Get column names
	columns, err := rows.Columns()
	if err != nil {
		return nil, err
	}

	// Read data
	var result []map[string]interface{}
	for rows.Next() {
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		if err := rows.Scan(valuePtrs...); err != nil {
			return nil, err
		}

		row := make(map[string]interface{})
		for i, col := range columns {
			val := values[i]
			if b, ok := val.([]byte); ok {
				row[col] = string(b)
			} else {
				row[col] = val
			}
		}
		result = append(result, row)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return &QueryResult{
		Columns:       columns,
		Rows:          result,
		RowCount:      len(result),
		ExecutionTime: time.Since(start).Milliseconds(),
	}, nil
}

// GetDatabaseType gets database type
func (a *SQLiteAdapter) GetDatabaseType() string {
	return "SQLite"
}

// GetDatabaseVersion gets database version
func (a *SQLiteAdapter) GetDatabaseVersion(ctx context.Context) (string, error) {
	result, err := a.ExecuteQuery(ctx, "SELECT sqlite_version() as version")
	if err != nil {
		return "", err
	}
	if result.Error != "" {
		return "", fmt.Errorf("%s", result.Error)
	}
	if len(result.Rows) > 0 {
		if version, ok := result.Rows[0]["version"].(string); ok {
			return version, nil
		}
	}
	return "unknown", nil
}

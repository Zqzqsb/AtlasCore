package valueindex

import (
	"context"
	"database/sql"
	"fmt"
	"path/filepath"
	"strings"
	"time"
	"unicode/utf8"

	_ "modernc.org/sqlite"
)

// DefaultSidecarPath returns <contextDir>/value_index/<dbID>.sqlite
func DefaultSidecarPath(contextDir, dbID string) string {
	return filepath.Join(contextDir, "value_index", dbID+".sqlite")
}

// Build reads distinct values from sourceDBPath for selected columns and writes
// an atomic sidecar index at outPath. columns may be empty to discover schema.
func Build(ctx context.Context, sourceDBPath, outPath, dbID string, columns []ColumnSpec, opt Options) (*Report, error) {
	opt = opt.withDefaults()
	start := time.Now()
	report := &Report{DBID: dbID}

	src, err := sql.Open("sqlite", sourceDBPath+"?mode=ro")
	if err != nil {
		return nil, err
	}
	defer src.Close()
	if err := src.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("valueindex open source: %w", err)
	}
	_, _ = src.ExecContext(ctx, "PRAGMA query_only=ON")

	if len(columns) == 0 {
		columns, err = discoverColumns(ctx, src)
		if err != nil {
			return nil, err
		}
	}
	// Fill missing nrows when possible.
	for i := range columns {
		if columns[i].NRows > 0 {
			continue
		}
		n, err := countRows(ctx, src, columns[i].Table)
		if err == nil {
			columns[i].NRows = n
		}
	}

	decisions := SelectColumns(columns, opt)
	for _, d := range decisions {
		switch d.Status {
		case "indexed":
			report.ColumnsIndexed++
			if d.Lane == LaneEntity {
				report.EntityIndexed++
			} else {
				report.CategoryIndexed++
			}
		case "hard_gate":
			report.HardGate++
			report.ColumnsSkipped++
		case "budget":
			report.BudgetRejected++
			report.ColumnsSkipped++
		case "ndv_cap":
			report.NDVCapRejected++
			report.ColumnsSkipped++
		default:
			report.ColumnsSkipped++
		}
	}

	var docs []Document
	for _, d := range IndexedColumns(decisions) {
		vals, err := loadDistinct(ctx, src, d.Spec, opt)
		if err != nil {
			report.QueryFailures++
			continue
		}
		kind := string(d.Lane)
		for _, v := range vals {
			if len(docs) >= opt.MaxDocuments {
				break
			}
			display := strings.TrimSpace(v)
			if display == "" {
				continue
			}
			if utf8.RuneCountInString(display) > opt.MaxValueRunes {
				continue
			}
			norm := Normalize(display)
			toks := Tokens(norm)
			if norm == "" || len(toks) == 0 {
				continue
			}
			docs = append(docs, Document{
				Table:           d.Spec.Table,
				Column:          d.Spec.Column,
				DisplayValue:    display,
				NormalizedValue: norm,
				ValueKind:       kind,
				SemanticRole:    kind,
				Tokens:          toks,
			})
		}
		if len(docs) >= opt.MaxDocuments {
			docs = docs[:opt.MaxDocuments]
			break
		}
	}

	if err := WriteStore(ctx, outPath, dbID, docs, report); err != nil {
		return report, err
	}
	report.ElapsedMS = time.Since(start).Milliseconds()
	return report, nil
}

func qident(name string) string {
	return `"` + strings.ReplaceAll(name, `"`, `""`) + `"`
}

func discoverColumns(ctx context.Context, db *sql.DB) ([]ColumnSpec, error) {
	rows, err := db.QueryContext(ctx,
		`SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var tables []string
	for rows.Next() {
		var t string
		if err := rows.Scan(&t); err != nil {
			return nil, err
		}
		tables = append(tables, t)
	}
	var out []ColumnSpec
	for _, t := range tables {
		nrows, _ := countRows(ctx, db, t)
		info, err := db.QueryContext(ctx, `PRAGMA table_info(`+qident(t)+`)`)
		if err != nil {
			continue
		}
		for info.Next() {
			var cid, notnull, pk int
			var name, ctype string
			var dflt sql.NullString
			if err := info.Scan(&cid, &name, &ctype, &notnull, &dflt, &pk); err != nil {
				continue
			}
			out = append(out, ColumnSpec{
				Table: t, Column: name, DeclType: ctype,
				IsPK: pk > 0, NRows: nrows,
			})
		}
		_ = info.Close()
	}
	return out, nil
}

func countRows(ctx context.Context, db *sql.DB, table string) (int64, error) {
	var n int64
	err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM `+qident(table)).Scan(&n)
	return n, err
}

func loadDistinct(ctx context.Context, db *sql.DB, col ColumnSpec, opt Options) ([]string, error) {
	qctx, cancel := context.WithTimeout(ctx, opt.ColumnQueryTimeout)
	defer cancel()

	colq := qident(col.Column)
	tq := qident(col.Table)
	limit := opt.EntityNDVCap
	if lane, _, _ := ClassifyLane(col); lane == LaneCategory {
		limit = opt.CategoryNDVCap
	}
	if limit <= 0 {
		limit = opt.SampleDistinctCap
	}

	var q string
	if col.NRows > 0 && col.NRows > opt.ExactDistinctMaxRows {
		// Bounded distinct for huge facts — still useful as positive evidence.
		cap := opt.SampleDistinctCap
		if cap > limit {
			cap = limit
		}
		q = fmt.Sprintf(
			`SELECT DISTINCT CAST(%s AS TEXT) AS v FROM %s WHERE %s IS NOT NULL AND CAST(%s AS TEXT) != '' LIMIT %d`,
			colq, tq, colq, colq, cap,
		)
	} else {
		q = fmt.Sprintf(
			`SELECT DISTINCT CAST(%s AS TEXT) AS v FROM %s WHERE %s IS NOT NULL AND CAST(%s AS TEXT) != '' LIMIT %d`,
			colq, tq, colq, colq, limit,
		)
	}

	rows, err := db.QueryContext(qctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var v sql.NullString
		if err := rows.Scan(&v); err != nil {
			return out, err
		}
		if v.Valid {
			out = append(out, v.String)
		}
	}
	return out, rows.Err()
}

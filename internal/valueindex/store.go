package valueindex

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"time"

	_ "modernc.org/sqlite"
)

// Document is one distinct business value tied to a physical column.
type Document struct {
	Table           string
	Column          string
	DisplayValue    string
	NormalizedValue string
	ValueKind       string // entity|category
	SemanticRole    string
	Tokens          []Token
}

// Report summarizes a build.
type Report struct {
	DBID                string    `json:"db_id"`
	Path                string    `json:"path"`
	Documents           int       `json:"documents"`
	Postings            int       `json:"postings"`
	ColumnsIndexed      int       `json:"columns_indexed"`
	ColumnsSelected     int       `json:"columns_selected,omitempty"`
	IndexedColumnKeys   []string  `json:"indexed_column_keys,omitempty"`
	TruncatedColumnKeys []string  `json:"truncated_column_keys,omitempty"`
	ColumnsSkipped      int       `json:"columns_skipped"`
	EntityIndexed       int       `json:"entity_indexed"`
	CategoryIndexed     int       `json:"category_indexed"`
	HardGate            int       `json:"hard_gate"`
	BudgetRejected      int       `json:"budget_rejected"`
	NDVCapRejected      int       `json:"ndv_cap_rejected"`
	QueryFailures       int       `json:"query_failures"`
	PostingCapReached   bool      `json:"posting_cap_reached,omitempty"`
	BuiltAt             time.Time `json:"built_at"`
	ElapsedMS           int64     `json:"elapsed_ms"`
}

const schemaSQL = `
CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
CREATE TABLE documents (
  doc_id INTEGER PRIMARY KEY,
  table_name TEXT NOT NULL,
  column_name TEXT NOT NULL,
  display_value TEXT NOT NULL,
  normalized_value TEXT NOT NULL,
  value_kind TEXT,
  semantic_role TEXT
);
CREATE TABLE postings (
  token_type TEXT NOT NULL,
  token TEXT NOT NULL,
  doc_id INTEGER NOT NULL,
  PRIMARY KEY (token_type, token, doc_id)
);
CREATE INDEX idx_postings_lookup ON postings(token, token_type);
CREATE INDEX idx_docs_col ON documents(table_name, column_name);
`

// WriteStore atomically replaces outPath with docs (temp + rename).
func WriteStore(ctx context.Context, outPath string, dbID string, docs []Document, report *Report) error {
	if outPath == "" {
		return fmt.Errorf("valueindex: empty out path")
	}
	if err := os.MkdirAll(filepath.Dir(outPath), 0o755); err != nil {
		return err
	}
	tmp := outPath + ".building"
	_ = os.Remove(tmp)

	db, err := sql.Open("sqlite", tmp)
	if err != nil {
		return err
	}
	defer func() {
		_ = db.Close()
		if ctx.Err() != nil {
			_ = os.Remove(tmp)
		}
	}()

	if _, err := db.ExecContext(ctx, schemaSQL); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("valueindex schema: %w", err)
	}

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		_ = os.Remove(tmp)
		return err
	}
	docStmt, err := tx.PrepareContext(ctx,
		`INSERT INTO documents(doc_id, table_name, column_name, display_value, normalized_value, value_kind, semantic_role)
		 VALUES(?,?,?,?,?,?,?)`)
	if err != nil {
		_ = tx.Rollback()
		_ = os.Remove(tmp)
		return err
	}
	defer docStmt.Close()
	postStmt, err := tx.PrepareContext(ctx,
		`INSERT OR IGNORE INTO postings(token_type, token, doc_id) VALUES(?,?,?)`)
	if err != nil {
		_ = tx.Rollback()
		_ = os.Remove(tmp)
		return err
	}
	defer postStmt.Close()

	postings := 0
	for i, d := range docs {
		docID := i + 1
		if _, err := docStmt.ExecContext(ctx, docID, d.Table, d.Column, d.DisplayValue, d.NormalizedValue, d.ValueKind, d.SemanticRole); err != nil {
			_ = tx.Rollback()
			_ = os.Remove(tmp)
			return err
		}
		for _, tok := range d.Tokens {
			if _, err := postStmt.ExecContext(ctx, tok.Type, tok.Token, docID); err != nil {
				_ = tx.Rollback()
				_ = os.Remove(tmp)
				return err
			}
			postings++
		}
	}
	now := time.Now().UTC().Format(time.RFC3339)
	metas := [][2]string{
		{"db_id", dbID},
		{"documents", fmt.Sprintf("%d", len(docs))},
		{"postings", fmt.Sprintf("%d", postings)},
		{"built_at", now},
		{"version", "1"},
	}
	for _, m := range metas {
		if _, err := tx.ExecContext(ctx, `INSERT INTO meta(key,value) VALUES(?,?)`, m[0], m[1]); err != nil {
			_ = tx.Rollback()
			_ = os.Remove(tmp)
			return err
		}
	}
	if err := tx.Commit(); err != nil {
		_ = os.Remove(tmp)
		return err
	}
	_ = db.Close()

	_ = os.Remove(outPath)
	if err := os.Rename(tmp, outPath); err != nil {
		_ = os.Remove(tmp)
		return err
	}
	if report != nil {
		report.Documents = len(docs)
		report.Postings = postings
		report.Path = outPath
		report.BuiltAt = time.Now().UTC()
	}
	return nil
}

// Store is a read-only handle over a sidecar index.
type Store struct {
	db   *sql.DB
	path string
}

// OpenStore opens an existing sidecar for lookup.
func OpenStore(path string) (*Store, error) {
	db, err := sql.Open("sqlite", path+"?mode=ro")
	if err != nil {
		return nil, err
	}
	if err := db.Ping(); err != nil {
		_ = db.Close()
		return nil, err
	}
	return &Store{db: db, path: path}, nil
}

func (s *Store) Close() error {
	if s == nil || s.db == nil {
		return nil
	}
	return s.db.Close()
}

func (s *Store) Path() string {
	if s == nil {
		return ""
	}
	return s.path
}

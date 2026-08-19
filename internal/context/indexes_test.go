package context

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
)

func TestIndexesFromTempDataSQLiteAndMySQL(t *testing.T) {
	sqliteRows := []map[string]interface{}{
		{"seq": 0, "name": "sqlite_autoindex_Business_Attributes_1", "unique": int64(1), "origin": "pk"},
		{"seq": 0, "name": "brewery_id", "unique": int64(0), "origin": "c", "columns": []string{"brewery_id"}},
	}
	got := indexesFromTempData(sqliteRows)
	if len(got) != 1 || got[0].Name != "brewery_id" || strings.Join(got[0].Columns, ",") != "brewery_id" {
		t.Fatalf("sqlite rows: %+v", got)
	}
	if got[0].IsUnique {
		t.Fatal("brewery_id is not unique")
	}

	mysqlRows := []map[string]interface{}{
		{"Key_name": "PRIMARY", "Column_name": "id", "Non_unique": float64(0)},
		{"Key_name": "idx_city", "Column_name": "city", "Non_unique": float64(1)},
		{"Key_name": "idx_city", "Column_name": "state", "Non_unique": float64(1)},
	}
	got = indexesFromTempData(mysqlRows)
	if len(got) != 1 || got[0].Name != "idx_city" {
		t.Fatalf("mysql rows: %+v", got)
	}
	if strings.Join(got[0].Columns, ",") != "city,state" {
		t.Fatalf("mysql columns: %+v", got[0].Columns)
	}
}

func TestCompactExportPrintsSecondaryIndex(t *testing.T) {
	shared := NewSharedContext("craftbeer", "sqlite")
	shared.Tables["beers"] = &TableMetadata{
		Name: "beers",
		Columns: []ColumnMetadata{
			{Name: "id", Type: "INTEGER", IsPrimaryKey: true},
			{Name: "brewery_id", Type: "INTEGER"},
		},
		Indexes: []IndexMetadata{
			{Name: "sqlite_autoindex_beers_1", Columns: []string{"id"}, IsPrimary: true},
			{Name: "brewery_id", Columns: []string{"brewery_id"}},
		},
	}
	out := shared.ExportToCompactPrompt(DefaultExportOptions())
	if !strings.Contains(out, "index brewery_id(brewery_id)") {
		t.Fatalf("missing secondary index:\n%s", out)
	}
	if strings.Contains(out, "sqlite_autoindex") {
		t.Fatalf("pk autoindex leaked:\n%s", out)
	}
}

func TestLoadSQLiteIndexesCraftbeer(t *testing.T) {
	dbPath := filepath.Join("..", "..", "benchmarks", "bird", "heldout_v1_smoke", "test_databases", "craftbeer", "craftbeer.sqlite")
	if _, err := os.Stat(dbPath); err != nil {
		t.Skip(err)
	}
	a := adapter.NewSQLiteAdapter(&adapter.SQLiteConfig{FilePath: dbPath})
	ctx := context.Background()
	if err := a.Connect(ctx); err != nil {
		t.Fatal(err)
	}
	defer a.Close()

	idxs, err := LoadTableIndexes(ctx, a, "beers")
	if err != nil {
		t.Fatal(err)
	}
	if len(idxs) != 1 || idxs[0].Name != "brewery_id" || strings.Join(idxs[0].Columns, ",") != "brewery_id" {
		t.Fatalf("got %+v", idxs)
	}

	shared := NewSharedContext("craftbeer", "sqlite")
	shared.Tables["beers"] = &TableMetadata{Name: "beers"}
	shared.RefreshIndexesFromDB(ctx, a)
	if len(shared.Tables["beers"].Indexes) != 1 {
		t.Fatalf("refresh: %+v", shared.Tables["beers"].Indexes)
	}
}

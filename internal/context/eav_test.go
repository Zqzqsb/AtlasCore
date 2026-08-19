package context

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
)

func TestSampledStatsNotClosedEnum(t *testing.T) {
	shared := NewSharedContext("yelp", "sqlite")
	shared.Tables["Business_Attributes"] = &TableMetadata{
		Name:     "Business_Attributes",
		RowCount: 206934,
		Columns: []ColumnMetadata{{
			Name: "attribute_value",
			Type: "TEXT",
			ValueStats: &ValueStats{
				DistinctCount: 3,
				TopValues: []ValueFrequency{
					{Value: "none", Count: 376},
					{Value: "full_bar", Count: 327},
					{Value: "beer_and_wine", Count: 97},
				},
			},
		}},
	}
	out := shared.ExportToCompactPrompt(DefaultExportOptions())
	if strings.Contains(out, "values=[none") {
		t.Fatalf("prefix sample must not look like a closed enum:\n%s", out)
	}
	if !strings.Contains(out, "prefix-sampled") {
		t.Fatalf("expected sampled marker:\n%s", out)
	}
}

func TestExactEnumStillValues(t *testing.T) {
	shared := NewSharedContext("demo", "sqlite")
	shared.Tables["t"] = &TableMetadata{
		Name:     "t",
		RowCount: 100,
		Columns: []ColumnMetadata{{
			Name: "status",
			Type: "TEXT",
			ValueStats: &ValueStats{
				DistinctCount: 2,
				DistinctMode:  "exact",
				SampleRows:    100,
				TopValues:     []ValueFrequency{{Value: "a", Count: 60}, {Value: "b", Count: 40}},
			},
		}},
	}
	out := shared.ExportToCompactPrompt(DefaultExportOptions())
	if !strings.Contains(out, "values=[a(60)") {
		t.Fatalf("exact enum should keep values=:\n%s", out)
	}
}

func TestDetectAndMatchEAVHasTV(t *testing.T) {
	dbPath := filepath.Join("..", "..", "benchmarks", "bird", "heldout_v1_smoke", "test_databases", "public_review_platform", "public_review_platform.sqlite")
	if _, err := os.Stat(dbPath); err != nil {
		t.Skip(err)
	}
	a := adapter.NewSQLiteAdapter(&adapter.SQLiteConfig{FilePath: dbPath})
	ctx := context.Background()
	if err := a.Connect(ctx); err != nil {
		t.Fatal(err)
	}
	defer a.Close()

	shared := NewSharedContext("public_review_platform", "sqlite")
	shared.Tables["Attributes"] = &TableMetadata{
		Name:       "Attributes",
		RowCount:   80,
		PrimaryKey: []string{"attribute_id"},
		Columns: []ColumnMetadata{
			{Name: "attribute_id", Type: "INTEGER", IsPrimaryKey: true},
			{Name: "attribute_name", Type: "TEXT"},
		},
	}
	shared.Tables["Business"] = &TableMetadata{
		Name:       "Business",
		RowCount:   15585,
		PrimaryKey: []string{"business_id"},
		Columns:    []ColumnMetadata{{Name: "business_id", IsPrimaryKey: true}},
	}
	shared.Tables["Business_Attributes"] = &TableMetadata{
		Name:     "Business_Attributes",
		RowCount: 206934,
		Columns: []ColumnMetadata{
			{Name: "attribute_id", Type: "INTEGER"},
			{Name: "business_id", Type: "INTEGER"},
			{Name: "attribute_value", Type: "TEXT"},
		},
		ForeignKeys: []ForeignKeyMetadata{
			{ColumnName: "business_id", ReferencedTable: "Business", ReferencedColumn: "business_id"},
			{ColumnName: "attribute_id", ReferencedTable: "Attributes", ReferencedColumn: "attribute_id"},
		},
		RichContext: map[string]RichContextValue{
			"attribute_id_1_values": {BusinessNote: BusinessNote{Content: "1=Alcohol"}},
		},
	}

	shared.RefreshEAVFromDB(ctx, a)
	cat := shared.Tables["Business_Attributes"].EAVCatalog
	if cat == nil || len(cat.Entries) < 10 {
		t.Fatalf("expected EAV catalog, got %+v", cat)
	}

	block := shared.FormatMatchedEAV([]string{"Business", "Attributes", "Business_Attributes"}, []string{"Has TV"})
	if !strings.Contains(block, `Has TV`) || !strings.Contains(block, "attribute_id=11") {
		t.Fatalf("Has TV miss:\n%s", block)
	}
	if !strings.Contains(block, "true") || !strings.Contains(block, "false") {
		t.Fatalf("expected true/false dist:\n%s", block)
	}
	if strings.Contains(block, "Alcohol") {
		t.Fatalf("unmatched keys should stay out:\n%s", block)
	}

	out := shared.ExportToCompactPrompt(DefaultExportOptions())
	if strings.Contains(out, "1=Alcohol") {
		t.Fatalf("per-id LLM notes should drop when catalog exists:\n%s", out)
	}
}

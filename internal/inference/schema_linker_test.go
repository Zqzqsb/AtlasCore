package inference

import (
	"strings"
	"testing"

	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
)

func TestExtractTableInfoDoesNotUseRandomNotesAsDescription(t *testing.T) {
	ctx := contextpkg.NewSharedContext("demo", "sqlite")
	note := contextpkg.RichContextValue{}
	note.Content = "Categorical bucket of useful votes"
	ctx.Tables["Users"] = &contextpkg.TableMetadata{
		Name: "Users",
		Columns: []contextpkg.ColumnMetadata{
			{Name: "user_id"},
			{Name: "user_votes_useful"},
		},
		RichContext: map[string]contextpkg.RichContextValue{
			"user_votes_useful_meaning": note,
		},
	}
	info := ExtractTableInfo(ctx)
	if got := info["Users"].Description; got != "" {
		t.Fatalf("column note leaked as table description: %q", got)
	}

	ctx.Tables["Users"].Description = "Yelp users"
	info = ExtractTableInfo(ctx)
	if got := info["Users"].Description; got != "Yelp users" {
		t.Fatalf("table description=%q", got)
	}
}

func TestLinkerSchemaSectionPrefersCompactRC(t *testing.T) {
	all := map[string]*TableInfo{
		"Attributes": {Name: "Attributes", Columns: []string{"attribute_id", "attribute_name"}},
	}
	compact := "Table Attributes (80 rows):\n  - attribute_name: TEXT samples=[Has TV, Alcohol]\n"
	got := linkerSchemaSection(all, compact)
	if got != compact {
		t.Fatalf("one-shot must use compact RC, got %q", got)
	}
	if strings.Contains(formatSkinnyTableList(all), "samples=") {
		t.Fatal("skinny fallback should not invent value stats")
	}
	skinny := linkerSchemaSection(all, "  ")
	if !strings.Contains(skinny, "attribute_name") || strings.Contains(skinny, "samples=") {
		t.Fatalf("empty compact should fall back to names, got %q", skinny)
	}
}

func TestFormatLinkerFKTargetDropsNil(t *testing.T) {
	got := formatLinkerFKTarget(contextpkg.ForeignKeyMetadata{
		ReferencedTable: "Attributes", ReferencedColumn: "<nil>",
	})
	if got != "Attributes" {
		t.Fatalf("got %q", got)
	}
	got = formatLinkerFKTarget(contextpkg.ForeignKeyMetadata{
		ReferencedTable: "Attributes", ReferencedColumn: "attribute_id",
	})
	if got != "Attributes.attribute_id" {
		t.Fatalf("got %q", got)
	}
}

func TestSchemaLinkingExportOmitsBusinessNotesKeepsValues(t *testing.T) {
	shared := contextpkg.NewSharedContext("demo", "sqlite")
	shared.Tables["Attributes"] = &contextpkg.TableMetadata{
		Name:        "Attributes",
		Description: "attribute dictionary",
		Columns: []contextpkg.ColumnMetadata{{
			Name:            "attribute_name",
			Type:            "TEXT",
			OfficialMeaning: "The attribute name column stores long official boilerplate.",
			ValueStats: &contextpkg.ValueStats{
				DistinctCount: 3,
				SampleValues:  []string{"Has TV", "Alcohol", "WiFi"},
			},
		}},
		RichContext: map[string]contextpkg.RichContextValue{
			"business_rules": {BusinessNote: contextpkg.BusinessNote{Content: "EAV table linking businesses to attributes"}},
		},
	}
	opts := (&Pipeline{config: &Config{GroundingMode: "all"}}).compactExportOptions(nil, nil, true)
	out := shared.ExportToCompactPrompt(opts)
	if !strings.Contains(out, "samples=[Has TV") {
		t.Fatalf("linker compact missing values:\n%s", out)
	}
	if !strings.Contains(out, "attribute dictionary") {
		t.Fatalf("linker compact missing table desc:\n%s", out)
	}
	if strings.Contains(out, "EAV table") || strings.Contains(out, "Business Notes") {
		t.Fatalf("linker compact leaked business notes:\n%s", out)
	}
	if strings.Contains(out, "long official boilerplate") {
		t.Fatalf("linker compact leaked official_meaning:\n%s", out)
	}
}

package inference

import (
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

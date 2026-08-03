package inference

import (
	"strings"
	"testing"

	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
)

func TestBuildAlignerSchemaText(t *testing.T) {
	shared := &contextpkg.SharedContext{
		DatabaseName: "movie_platform",
		Tables: map[string]*contextpkg.TableMetadata{
			"movies": {
				Name: "movies",
				Columns: []contextpkg.ColumnMetadata{
					{Name: "movie_id"}, {Name: "movie_title"}, {Name: "year"},
				},
			},
			"ratings": {
				Name: "ratings",
				Columns: []contextpkg.ColumnMetadata{
					{Name: "user_id"}, {Name: "rating_score"},
				},
			},
		},
	}
	got := BuildAlignerSchemaText(shared, "movie_platform", []string{"movies", "ratings"})
	if !strings.Contains(got, "Database: movie_platform") {
		t.Fatalf("missing db: %s", got)
	}
	if !strings.Contains(got, "- movies(movie_id, movie_title, year)") {
		t.Fatalf("missing movies line: %s", got)
	}
	if !strings.Contains(got, "- ratings(user_id, rating_score)") {
		t.Fatalf("missing ratings line: %s", got)
	}
}

func TestBuildProjAlignUserInput(t *testing.T) {
	in := buildProjAlignUserInput("How many users?", "count users", "Database: x\nTables/Columns:\n- t(a)")
	if !strings.Contains(in, "Question: How many users?") {
		t.Fatal(in)
	}
	if !strings.Contains(in, "Evidence: count users") {
		t.Fatal(in)
	}
	if !strings.Contains(in, "SHORT label") {
		t.Fatal(in)
	}
}

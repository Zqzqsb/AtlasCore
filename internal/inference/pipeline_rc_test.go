package inference

import (
	"os"
	"path/filepath"
	"testing"
)

func TestNewPipelineDoesNotOverwriteOfficialMeaning(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "yelp.json")
	raw := `{
	  "database_name": "yelp",
	  "tables": {
	    "Business": {
	      "name": "Business",
	      "columns": [{"name": "city", "type": "TEXT", "official_meaning": "city name from csv"}]
	    }
	  }
	}`
	if err := os.WriteFile(path, []byte(raw), 0644); err != nil {
		t.Fatal(err)
	}

	p := NewPipeline(nil, nil, &Config{
		ContextFile:   path,
		DBName:        "yelp",
		GroundingMode: "all",
		ColumnMeaning: ColumnMeaningStore{
			"yelp|business|city": "The 'city' column in the 'Business' table of the 'yelp' database records the city.",
		},
	})
	if p.context == nil {
		t.Fatal("expected RC loaded")
	}
	got := p.context.Tables["Business"].Columns[0].OfficialMeaning
	if got != "city name from csv" {
		t.Fatalf("inference must not bake column_meaning over RC, got %q", got)
	}
}

package context

import (
	"strings"
	"testing"
)

func TestClassifyValueShape(t *testing.T) {
	cases := map[string]string{
		"":             "empty",
		"12345":        "digits",
		"ABC":          "alpha",
		"A1_b":         "alnum",
		"2020-01-02":   "dateish",
		"a@b.com":      "emailish",
		"hello world!": "mixed",
	}
	for in, want := range cases {
		if got := ClassifyValueShape(in); got != want {
			t.Errorf("ClassifyValueShape(%q)=%q want %q", in, got, want)
		}
	}
}

func TestAnnotateTextProfileAndNL(t *testing.T) {
	stats := &ValueStats{
		SampleValues:  []string{"123-456-7890", "555-0100", "555-0101", "n/a"},
		DistinctCount: 4,
		NullPercent:   8,
	}
	AnnotateTextProfile(stats)
	if stats.DominantShape == "" {
		t.Fatal("expected DominantShape")
	}
	if stats.AvgLen <= 0 {
		t.Fatalf("AvgLen=%v", stats.AvgLen)
	}
	foundPhone, foundNA := false, false
	for _, s := range stats.SuspiciousDefaults {
		if s == "123-456-7890" {
			foundPhone = true
		}
		if strings.EqualFold(s, "n/a") {
			foundNA = true
		}
	}
	if !foundPhone || !foundNA {
		t.Fatalf("SuspiciousDefaults=%v", stats.SuspiciousDefaults)
	}
	nl := BuildProfileNL("phone", "TEXT", stats)
	if !strings.Contains(nl, "NULL") || !strings.Contains(nl, "shape=") {
		t.Fatalf("ProfileNL=%q", nl)
	}
}

func TestParseAndApplyOfficialMeanings(t *testing.T) {
	raw := map[string]string{
		"frpm|schools|CDSCode": "unique school id",
		"other|t|c":            "ignore",
	}
	lookup := ParseColumnMeaningForDB(raw, "frpm")
	if len(lookup) != 1 {
		t.Fatalf("lookup=%v", lookup)
	}
	sc := &SharedContext{Tables: map[string]*TableMetadata{
		"schools": {Name: "schools", Columns: []ColumnMetadata{{Name: "CDSCode", Type: "TEXT"}}},
	}}
	n := sc.ApplyOfficialMeanings(lookup)
	if n != 1 {
		t.Fatalf("applied=%d", n)
	}
	if sc.Tables["schools"].Columns[0].OfficialMeaning != "unique school id" {
		t.Fatalf("meaning=%q", sc.Tables["schools"].Columns[0].OfficialMeaning)
	}
}

func TestFormatColumnGrounding(t *testing.T) {
	col := ColumnMetadata{
		OfficialMeaning: "school code",
		Type:            "TEXT",
		ValueStats: &ValueStats{
			DominantShape: "digits",
			AvgLen:        5,
		},
	}
	opts := DefaultExportOptions()
	got := formatColumnGrounding("schools", col, opts)
	if !strings.Contains(got, "school code") || !strings.Contains(got, "stored-as-text shape=digits") {
		t.Fatalf("got=%q", got)
	}
	if formatColumnGrounding("schools", ColumnMetadata{}, opts) != "" {
		t.Fatal("expected empty")
	}
}

func TestBuildSparseProfileNLDropsGenericStats(t *testing.T) {
	col := ColumnMetadata{
		Name: "score",
		Type: "REAL",
		ValueStats: &ValueStats{
			DistinctCount: 100,
			AvgLen:        4,
			Range:         &NumericRange{Min: 1, Max: 100},
		},
	}
	if got := BuildSparseProfileNL(col); got != "" {
		t.Fatalf("generic stats should remain structured, got %q", got)
	}
}

func TestGroundingColumnsRestrictInlineNotes(t *testing.T) {
	col := ColumnMetadata{Name: "code", OfficialMeaning: "school code"}
	opts := DefaultExportOptions()
	opts.GroundingColumns = map[string]struct{}{"schools.name": {}}
	if got := formatColumnGrounding("schools", col, opts); got != "" {
		t.Fatalf("unselected column should not be grounded, got %q", got)
	}
	opts.GroundingColumns["schools.code"] = struct{}{}
	if got := formatColumnGrounding("schools", col, opts); !strings.Contains(got, "school code") {
		t.Fatalf("selected column missing meaning: %q", got)
	}
}

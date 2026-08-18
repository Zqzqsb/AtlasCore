package context

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/Zqzqsb/AtlasCore/internal/birddesc"
	"github.com/Zqzqsb/AtlasCore/internal/valueindex"
)

func TestSampledPlannerUsesStatsOverColumnName(t *testing.T) {
	ctx := &SharedContext{Tables: map[string]*TableMetadata{
		"events": {
			Name: "events", RowCount: 1000,
			Columns: []ColumnMetadata{
				{Name: "DESCRIPTION", Type: "TEXT", ValueStats: &ValueStats{
					DistinctCount: 15, DistinctMode: "exact", ObservedNDV: 15,
					SampleRows: 1000, Uniqueness: .015, AvgLen: 24, DominantShape: "alpha",
				}},
				{Name: "payload", Type: "TEXT", ValueStats: &ValueStats{
					DistinctCount: 900, DistinctMode: "exact", ObservedNDV: 900,
					SampleRows: 1000, Uniqueness: .9, AvgLen: 200, DominantShape: "mixed",
				}},
			},
		},
	}}

	include, exclude, review := ctx.LabelValueIndexSampled()
	if include != 1 || exclude != 1 || review != 0 {
		t.Fatalf("counts include=%d exclude=%d review=%d", include, exclude, review)
	}
	cols := ctx.Tables["events"].Columns
	if cols[0].ValueIndexPolicy != valueindex.PolicyInclude {
		t.Fatalf("low-NDV DESCRIPTION should be rescued: %+v", cols[0])
	}
	if cols[1].ValueIndexPolicy != valueindex.PolicyExclude {
		t.Fatalf("long payload should be excluded: %+v", cols[1])
	}
}

func TestSampledPlannerDoesNotTreatSampleNDVAsExact(t *testing.T) {
	ctx := &SharedContext{Tables: map[string]*TableMetadata{
		"methods": {
			Name: "methods", RowCount: 2_000_000,
			Columns: []ColumnMetadata{{
				Name: "Name", Type: "TEXT", ValueStats: &ValueStats{
					DistinctCount: 700, DistinctMode: "sampled", ObservedNDV: 700,
					SampleRows: 800, Uniqueness: .875, AvgLen: 35, DominantShape: "alpha",
				},
			}},
		},
	}}
	ctx.LabelValueIndexSampled()
	col := ctx.Tables["methods"].Columns[0]
	if col.ValueIndexPolicy != valueindex.PolicyReview {
		t.Fatalf("high-unique large-table sample should require review: %+v", col)
	}
	if col.ValueIndexEstimatedDocs <= 700 {
		t.Fatalf("sample NDV was treated as exact: estimated=%d", col.ValueIndexEstimatedDocs)
	}
}

func TestSampledPlannerKeepsHighCardinalityBusinessTitle(t *testing.T) {
	ctx := &SharedContext{Tables: map[string]*TableMetadata{
		"movies": {
			Name: "movies", RowCount: 500_000,
			Columns: []ColumnMetadata{{
				Name: "movie_title", Type: "TEXT", ValueStats: &ValueStats{
					DistinctCount: 790, DistinctMode: "sampled", ObservedNDV: 790,
					SampleRows: 800, Uniqueness: .9875, AvgLen: 28, DominantShape: "alpha",
				},
			}},
		},
	}}
	ctx.LabelValueIndexSampled()
	col := ctx.Tables["movies"].Columns[0]
	if col.ValueIndexPolicy != valueindex.PolicyInclude || col.ValueIndexKind != string(valueindex.LaneEntity) {
		t.Fatalf("business title should remain an entity under builder budgets: %+v", col)
	}
}

func TestSampledPlannerBoundsRepeatedCategoryCost(t *testing.T) {
	ctx := &SharedContext{Tables: map[string]*TableMetadata{
		"facts": {
			Name: "facts", RowCount: 3_000_000,
			Columns: []ColumnMetadata{{
				Name: "status", Type: "TEXT", ValueStats: &ValueStats{
					DistinctCount: 3, DistinctMode: "sampled", ObservedNDV: 3,
					SampleRows: 800, Uniqueness: 3.0 / 800, AvgLen: 1, DominantShape: "alpha",
				},
			}},
		},
	}}
	ctx.LabelValueIndexSampled()
	col := ctx.Tables["facts"].Columns[0]
	if col.ValueIndexPolicy != valueindex.PolicyInclude || col.ValueIndexEstimatedDocs != 6 {
		t.Fatalf("repeated category plan: %+v", col)
	}
}

func TestSampledPlannerForcesOfficialMapping(t *testing.T) {
	dir := t.TempDir()
	csv := "original_column_name,column_name,column_description,value_description\nflag,flag,,0: No; 1: Yes\n"
	if err := os.WriteFile(filepath.Join(dir, "events.csv"), []byte(csv), 0o644); err != nil {
		t.Fatal(err)
	}
	desc, err := birddesc.LoadDir("demo", dir)
	if err != nil {
		t.Fatal(err)
	}
	ctx := &SharedContext{Tables: map[string]*TableMetadata{
		"events": {
			Name: "events", RowCount: 100,
			Columns: []ColumnMetadata{{
				Name: "flag", Type: "INTEGER", ValueStats: &ValueStats{
					DistinctCount: 2, DistinctMode: "exact", ObservedNDV: 2, SampleRows: 100,
				},
			}},
		},
	}}
	ctx.SetOfficialDesc(desc)
	ctx.LabelValueIndexSampled()
	col := ctx.Tables["events"].Columns[0]
	if col.ValueIndexPolicy != valueindex.PolicyInclude || col.ValueIndexKind != string(valueindex.LaneCategory) {
		t.Fatalf("official mapping must force category include: %+v", col)
	}
}

func TestSampledPlannerForcesOfficialEnum(t *testing.T) {
	ctx := &SharedContext{Tables: map[string]*TableMetadata{
		"sets": {
			Name: "sets", RowCount: 100,
			Columns: []ColumnMetadata{{
				Name: "type", Type: "INTEGER", ValueStats: &ValueStats{
					DistinctCount: 4, DistinctMode: "exact", ObservedNDV: 4, SampleRows: 100,
				},
			}},
		},
	}}
	ctx.SetOfficialDesc(&birddesc.Database{Columns: []*birddesc.Column{{
		Table: "sets", Name: "type", Kind: birddesc.KindEnum,
	}}})
	ctx.LabelValueIndexSampled()
	col := ctx.Tables["sets"].Columns[0]
	if col.ValueIndexPolicy != valueindex.PolicyInclude || col.ValueIndexKind != string(valueindex.LaneCategory) {
		t.Fatalf("official enum must force category include: %+v", col)
	}
}

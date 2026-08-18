package valueindex

import "testing"

func TestSelectColumnsSkipsReviewAndForcesOfficialMapping(t *testing.T) {
	cols := []ColumnSpec{
		{Table: "t", Column: "ambiguous", DeclType: "TEXT", Policy: PolicyReview, NDV: 10},
		{Table: "t", Column: "flag", DeclType: "INTEGER", IsPK: true, Policy: PolicyInclude, ForceIndex: true, NDV: 2},
		{Table: "t", Column: "DESCRIPTION", DeclType: "TEXT", Policy: PolicyInclude, Kind: string(LaneCategory), NDV: 15},
	}
	decisions := SelectColumns(cols, DefaultOptions())
	status := map[string]string{}
	lane := map[string]Lane{}
	for _, d := range decisions {
		status[d.Spec.Column] = d.Status
		lane[d.Spec.Column] = d.Lane
	}
	if status["ambiguous"] != "review" {
		t.Fatalf("review status=%q", status["ambiguous"])
	}
	if status["flag"] != "indexed" {
		t.Fatalf("official mapping status=%q", status["flag"])
	}
	if status["DESCRIPTION"] != "indexed" {
		t.Fatalf("sampled include should rescue name gate, status=%q", status["DESCRIPTION"])
	}
	if lane["DESCRIPTION"] != LaneCategory {
		t.Fatalf("planned category was changed to %q", lane["DESCRIPTION"])
	}
}

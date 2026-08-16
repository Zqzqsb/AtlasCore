package inference

import "testing"

func TestBuildOutputContract_MaxColsAndLimit(t *testing.T) {
	c := BuildOutputContract("Who directed the movie with the most voice actors?", "")
	if c.MaxCols == 1 {
		t.Fatalf("who/which must not force MaxCols=1")
	}
	if !c.NeedsLimit {
		t.Fatalf("expected NeedsLimit for most/ranking")
	}
	c2 := BuildOutputContract("How many games were published?", "")
	if c2.MaxCols != 1 {
		t.Fatalf("count MaxCols=%d want 1", c2.MaxCols)
	}
	c3 := BuildOutputContract("List the name and id of authors", "")
	if c3.MaxCols == 1 {
		t.Fatalf("multi-attr should not force MaxCols=1")
	}
	c4 := BuildOutputContract("How many albums and singles were released?", "")
	if c4.MaxCols == 1 {
		t.Fatalf("how many A and B should not force MaxCols=1")
	}
}

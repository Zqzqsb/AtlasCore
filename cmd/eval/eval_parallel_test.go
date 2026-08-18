package main

import "testing"

func TestSplitRanges(t *testing.T) {
	got := splitRanges(10, 4)
	want := [][2]int{{0, 3}, {3, 6}, {6, 8}, {8, 10}}
	if len(got) != len(want) {
		t.Fatalf("got %v", got)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("i=%d got=%v want=%v", i, got[i], want[i])
		}
	}
	if splitRanges(3, 8); len(splitRanges(3, 8)) != 3 {
		t.Fatalf("cap parts to n: %v", splitRanges(3, 8))
	}
}

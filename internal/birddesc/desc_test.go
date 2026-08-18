package birddesc

import (
	"strings"
	"testing"
)

func TestClassifyCommentsScoreIsRule(t *testing.T) {
	c := &Column{ValueDesc: `commonsense evidence:
The score is from 0 to 100. The score more than 60 refers that the comment is a positive comment.`}
	classify(c)
	if c.Kind != KindRule {
		t.Fatalf("kind=%s", c.Kind)
	}
}

func TestClassifySetsTypeEnum(t *testing.T) {
	c := &Column{ValueDesc: `"alchemy", "archenemy", "commander", "expansion"`}
	classify(c)
	if c.Kind != KindEnum {
		t.Fatalf("kind=%s aliases=%v", c.Kind, c.Aliases)
	}
	if len(c.Enums) != 4 {
		t.Fatalf("enums=%v", c.Enums)
	}
}

func TestClassifyCharterMapping(t *testing.T) {
	c := &Column{ValueDesc: "0: N;\n1: Y"}
	classify(c)
	if c.Kind != KindMapping {
		t.Fatalf("kind=%s", c.Kind)
	}
	if got := c.Aliases["0"]; len(got) == 0 || got[0] != "N" {
		t.Fatalf("0=%v", got)
	}
	if got := c.Aliases["1"]; len(got) == 0 || got[0] != "Y" {
		t.Fatalf("1=%v", got)
	}
}

func TestClassifyClosedDateRule(t *testing.T) {
	c := &Column{ValueDesc: `commonsense evidence:
if ClosedDate is null or empty, it means this post is not well-finished`}
	classify(c)
	if c.Kind != KindRule {
		t.Fatalf("kind=%s", c.Kind)
	}
}

func TestIndexedValueColumnsIncludesEnumAndMapping(t *testing.T) {
	d := &Database{Columns: []*Column{
		{Table: "sets", Name: "type", Kind: KindEnum},
		{Table: "sets", Name: "foil", Kind: KindMapping},
		{Table: "sets", Name: "score", Kind: KindRule},
	}}
	got := d.IndexedValueColumns()
	if _, ok := got["sets|type"]; !ok {
		t.Fatal("enum column missing")
	}
	if _, ok := got["sets|foil"]; !ok {
		t.Fatal("mapping column missing")
	}
	if _, ok := got["sets|score"]; ok {
		t.Fatal("rule column should not be forced")
	}
}

func TestParseCSVAndPrompt(t *testing.T) {
	raw := `original_column_name,column_name,column_description,data_format,value_description
type,,The expansion type of the set.,text,"""alchemy"", ""commander"", ""expansion"""
isFoilOnly,is Foil Only,If the set is only available in foil.,integer,
ClosedDate,Closed Date,the closed date,date,"commonsense evidence:
if ClosedDate is null or empty, it means unfinished"
`
	cols, err := parseCSV("sets", strings.NewReader(raw))
	if err != nil {
		t.Fatal(err)
	}
	if len(cols) != 3 {
		t.Fatalf("n=%d", len(cols))
	}
	d := &Database{DBID: "card_games", byTable: map[string][]*Column{}}
	for _, c := range cols {
		d.Columns = append(d.Columns, c)
		d.byTable[strings.ToLower(c.Table)] = append(d.byTable[strings.ToLower(c.Table)], c)
	}
	prompt := d.TablePrompt("sets")
	if !strings.Contains(prompt, "REFERENCE") || !strings.Contains(prompt, "type") {
		t.Fatalf("prompt=%s", prompt)
	}
	if d.TableRules("sets") == "" {
		t.Fatal("expected ClosedDate rule")
	}
	if _, ok := d.MeaningLookup()["sets|type"]; !ok {
		t.Fatal("meaning lookup")
	}
}

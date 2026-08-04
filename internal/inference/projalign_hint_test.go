package inference

import (
	"strings"
	"testing"
)

func TestParseAlignShape(t *testing.T) {
	cases := map[string]string{
		`{"shape":"scalar","fields":[{"name":"id","kind":"count"}]}`: "scalar",
		`{"shape":"list","fields":[{"name":"name","kind":"col"}`:     "list", // truncated at 96 tokens
		`  {"shape": "entity", "fields": []}`:                        "entity",
		`{"shape":"table"}`:                                          "table",
		`no json here`:                                               "",
		`{"fields":[]}`:                                              "",
	}
	for in, want := range cases {
		if got := parseAlignShape(in); got != want {
			t.Errorf("parseAlignShape(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestFormatShapeHintForPrompt(t *testing.T) {
	// "table" precision is 58.3% offline; it must never reach the prompt.
	if got := FormatShapeHintForPrompt("table"); got != "" {
		t.Errorf("table shape should be dropped, got %q", got)
	}
	if got := FormatShapeHintForPrompt(""); got != "" {
		t.Errorf("empty shape should render nothing, got %q", got)
	}
	got := FormatShapeHintForPrompt("list")
	if !strings.Contains(got, "LIST") {
		t.Errorf("missing shape name: %q", got)
	}
	if strings.Contains(got, "align_projection") || strings.Contains(got, "Action") {
		t.Errorf("hint must not reference tools or steps: %q", got)
	}
}

func TestShapeHintPrecisionGate(t *testing.T) {
	for shape, p := range shapeHintPrecision {
		rendered := FormatShapeHintForPrompt(shape) != ""
		if trusted := p >= shapeHintMinPrecision; trusted != rendered {
			t.Errorf("shape %q precision %.3f trusted=%v but rendered=%v", shape, p, trusted, rendered)
		}
	}
}

// Shape mode must leave the ReAct prompt structure exactly as it was before the
// aligner existed: no extra tool, no extra workflow step, verify_sql untouched.
func TestShapeModeKeepsPromptStructure(t *testing.T) {
	newPipeline := func(mode string) *Pipeline {
		return &Pipeline{
			config: &Config{
				UseReact:            true,
				UseRichContext:      false,
				Benchmark:           "bird",
				ClarifyMode:         "off",
				EnableProposeFields: true,
				EnableProbeTool:     true,
				EnableProjAlignTool: true,
				ProjAlignMode:       mode,
			},
		}
	}

	shapeP := newPipeline(projAlignModeShape)
	shapeP.projAlignShape = "list"
	shaped := shapeP.buildPrompt("Question: how many?", "", "", true)

	offP := newPipeline(projAlignModeOff)
	off := offP.buildPrompt("Question: how many?", "", "", true)

	toolP := newPipeline(projAlignModeTool)
	tooled := toolP.buildPrompt("Question: how many?", "", "", true)

	if strings.Contains(shaped, "align_projection") {
		t.Error("shape mode leaked the tool name into the prompt")
	}
	if !strings.Contains(tooled, "align_projection") {
		t.Error("tool mode should still expose align_projection")
	}
	if !strings.Contains(shaped, "Result Shape Prior") {
		t.Error("shape mode should inject the static hint")
	}
	if strings.Contains(off, "Result Shape Prior") {
		t.Error("off mode should inject nothing")
	}

	// The only difference from an aligner-free run is the hint paragraph.
	if stripped := strings.Replace(shaped, FormatShapeHintForPrompt("list"), "", 1); stripped != off {
		t.Errorf("shape mode changed the prompt beyond the hint block:\n--- got ---\n%s\n--- want ---\n%s", stripped, off)
	}

	for _, want := range []string{
		"MANDATORY: Use verify_sql to check your SQL before giving Final Answer",
		"use propose_output_fields, then verify_sql",
	} {
		if !strings.Contains(shaped, want) {
			t.Errorf("shape mode dropped baseline instruction %q", want)
		}
	}
}

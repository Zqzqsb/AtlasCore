package inference

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestProjFewShotOffByDefault(t *testing.T) {
	ResetProjFewShotCache()
	if got := FormatProjFewShotForPrompt(""); got != "" {
		t.Fatalf("empty path should render nothing, got %q", got)
	}
}

func TestProjFewShotRendersLessons(t *testing.T) {
	ResetProjFewShotCache()
	path := filepath.Join("..", "..", "data", "proj_fewshot", "probe_v1.json")
	if _, err := os.Stat(path); err != nil {
		path = filepath.Join("data", "proj_fewshot", "probe_v1.json")
	}
	// resolve from module root
	wd, _ := os.Getwd()
	candidates := []string{
		filepath.Join(wd, "data", "proj_fewshot", "probe_v1.json"),
		filepath.Join(wd, "..", "..", "data", "proj_fewshot", "probe_v1.json"),
	}
	var ok string
	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			ok = c
			break
		}
	}
	if ok == "" {
		t.Skip("probe_v1.json not found")
	}
	got := FormatProjFewShotForPrompt(ok)
	if !strings.Contains(got, "Projection Taste Examples") {
		t.Fatalf("missing header: %s", got[:min(80, len(got))])
	}
	if !strings.Contains(got, "how_many_to_list") {
		t.Fatal("missing tag")
	}
	if strings.Contains(got, "align_projection") {
		t.Fatal("must not mention align tool")
	}
}

func TestProjFewShotDoesNotChangeWorkflow(t *testing.T) {
	ResetProjFewShotCache()
	p := &Pipeline{config: &Config{
		UseReact: true, UseRichContext: false, Benchmark: "bird",
		ClarifyMode: "off", EnableProposeFields: true, EnableProbeTool: true,
	}}
	off := p.buildPrompt("Question: x?", "", "", true)

	wd, _ := os.Getwd()
	path := filepath.Join(wd, "..", "..", "data", "proj_fewshot", "probe_v1.json")
	if _, err := os.Stat(path); err != nil {
		path = filepath.Join(wd, "data", "proj_fewshot", "probe_v1.json")
	}
	if _, err := os.Stat(path); err != nil {
		t.Skip(err)
	}
	p.config.ProjFewShotPath = path
	ResetProjFewShotCache()
	on := p.buildPrompt("Question: x?", "", "", true)

	if strings.Contains(off, "Projection Taste Examples") {
		t.Fatal("off prompt leaked few-shot")
	}
	if !strings.Contains(on, "Projection Taste Examples") {
		t.Fatal("on prompt missing few-shot")
	}
	if strings.Contains(on, "align_projection") {
		t.Fatal("few-shot must not add align tool")
	}
	for _, want := range []string{
		"MANDATORY: Use verify_sql to check your SQL before giving Final Answer",
		"use propose_output_fields, then verify_sql",
	} {
		if !strings.Contains(on, want) {
			t.Errorf("few-shot dropped baseline instruction %q", want)
		}
	}
}

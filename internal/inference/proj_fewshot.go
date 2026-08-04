package inference

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"sync"
)

// Projection few-shot (ablation unit).
//
// Static examples injected into the prompt — no tool, no workflow step.
// Enable with PROJ_FEWSHOT_PATH=/path/to.json (empty/unset = off).
// Drop the experiment: unset the env, or delete this file + the one call site.

type projFewShotFile struct {
	Version  string             `json:"version"`
	Examples []projFewShotExample `json:"examples"`
}

type projFewShotExample struct {
	Tag      string `json:"tag"`
	DBID     string `json:"db_id"`
	Question string `json:"question"`
	Evidence string `json:"evidence"`
	SQL      string `json:"SQL"`
	Lesson   string `json:"lesson"`
}

var (
	projFewShotOnce sync.Once
	projFewShotBlk  string
	projFewShotErr  error
)

// ProjFewShotPathFromEnv returns PROJ_FEWSHOT_PATH (empty = disabled).
func ProjFewShotPathFromEnv() string {
	return strings.TrimSpace(os.Getenv("PROJ_FEWSHOT_PATH"))
}

// FormatProjFewShotForPrompt loads (once) and renders the few-shot block.
// Empty path or load failure → "" (prompt unchanged aside from nothing).
func FormatProjFewShotForPrompt(path string) string {
	path = strings.TrimSpace(path)
	if path == "" {
		return ""
	}
	projFewShotOnce.Do(func() {
		projFewShotBlk, projFewShotErr = loadProjFewShotBlock(path)
	})
	if projFewShotErr != nil {
		return ""
	}
	return projFewShotBlk
}

func loadProjFewShotBlock(path string) (string, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	var f projFewShotFile
	if err := json.Unmarshal(raw, &f); err != nil {
		return "", err
	}
	if len(f.Examples) == 0 {
		return "", fmt.Errorf("no examples in %s", path)
	}
	var b strings.Builder
	b.WriteString("Projection Taste Examples (other BIRD questions — soft reference only):\n")
	b.WriteString("Use these ONLY for output shape / column style. Schemas differ; do NOT copy table names.\n")
	b.WriteString("Ignore an example when it conflicts with Evidence or the linked schema.\n\n")
	for i, ex := range f.Examples {
		b.WriteString(fmt.Sprintf("Example %d [%s]:\n", i+1, ex.Tag))
		b.WriteString("Q: ")
		b.WriteString(strings.TrimSpace(ex.Question))
		b.WriteByte('\n')
		if strings.TrimSpace(ex.Evidence) != "" {
			b.WriteString("Evidence: ")
			b.WriteString(strings.TrimSpace(ex.Evidence))
			b.WriteByte('\n')
		}
		b.WriteString("Gold SQL: ")
		b.WriteString(strings.TrimSpace(ex.SQL))
		b.WriteByte('\n')
		if strings.TrimSpace(ex.Lesson) != "" {
			b.WriteString("Lesson: ")
			b.WriteString(strings.TrimSpace(ex.Lesson))
			b.WriteByte('\n')
		}
		b.WriteByte('\n')
	}
	return b.String(), nil
}

// ResetProjFewShotCache is for tests.
func ResetProjFewShotCache() {
	projFewShotOnce = sync.Once{}
	projFewShotBlk = ""
	projFewShotErr = nil
}

package inference

import (
	"fmt"
	"strings"
)

// FormatRetryHint is a short brief for a whole-question retry.
// Uses the failed run's error + last ReAct steps (the agent's own last thought).
// Does not treat last verify_sql as the answer — that is often a probe.
func FormatRetryHint(err error, steps []ReActStep) string {
	var b strings.Builder
	b.WriteString("## Previous attempt failed — this is a retry\n")
	if err != nil {
		b.WriteString("Error: ")
		b.WriteString(truncate(strings.TrimSpace(err.Error()), 220))
		b.WriteString("\n")
	}
	b.WriteString("Do not repeat the same tool loop. Probe at most once if needed, then verify_sql and give Final Answer.\n")
	if thought := lastNonEmptyThought(steps); thought != "" {
		b.WriteString("Last thought: ")
		b.WriteString(truncate(thought, 240))
		b.WriteString("\n")
	}
	tail := lastActionSteps(steps, 4)
	if len(tail) == 0 {
		return b.String()
	}
	b.WriteString("Last steps:\n")
	for _, s := range tail {
		act := strings.TrimSpace(s.Action)
		in := compactActionInput(s.ActionInput, 160)
		if in == "" {
			b.WriteString(fmt.Sprintf("- %s\n", act))
			continue
		}
		b.WriteString(fmt.Sprintf("- %s: %s\n", act, in))
	}
	return b.String()
}

func lastNonEmptyThought(steps []ReActStep) string {
	for i := len(steps) - 1; i >= 0; i-- {
		t := strings.TrimSpace(steps[i].Thought)
		if t != "" {
			return t
		}
	}
	return ""
}

func lastActionSteps(steps []ReActStep, n int) []ReActStep {
	var out []ReActStep
	for i := len(steps) - 1; i >= 0 && len(out) < n; i-- {
		if strings.TrimSpace(steps[i].Action) == "" {
			continue
		}
		out = append(out, steps[i])
	}
	for i, j := 0, len(out)-1; i < j; i, j = i+1, j-1 {
		out[i], out[j] = out[j], out[i]
	}
	return out
}

func compactActionInput(in interface{}, max int) string {
	if in == nil {
		return ""
	}
	s := strings.Join(strings.Fields(fmt.Sprint(in)), " ")
	if strings.HasPrefix(s, "map[") {
		return truncate(s, max)
	}
	return truncate(s, max)
}

package inference

import (
	"context"
	"fmt"
	"strings"
)

// ProposeFieldsTool lets the agent propose an output projection without gold fields.
type ProposeFieldsTool struct {
	logger   *InferenceLogger
	lastProp string
}

func (t *ProposeFieldsTool) Name() string { return "propose_output_fields" }

func (t *ProposeFieldsTool) Description() string {
	return `Propose the output columns you intend to return (gold-free clarify substitute).
Input: comma-separated field names with optional short descriptions, e.g.
  student_name: display name of the student, count: number of courses
Output: confirmation that subsequent SQL SELECT should match this proposal.
Use when the question does not make the result columns obvious.`
}

func (t *ProposeFieldsTool) Call(ctx context.Context, input string) (string, error) {
	prop := strings.TrimSpace(input)
	t.lastProp = prop
	logf := func(format string, a ...interface{}) {
		if t.logger != nil {
			t.logger.Printf(format, a...)
		} else {
			fmt.Printf(format, a...)
		}
	}
	logf("\n🔍 Tool Call [propose_output_fields]:\nInput: %s\n", prop)
	msg := fmt.Sprintf("✓ Output field proposal recorded:\n%s\nYour Final Answer SQL SELECT list MUST match these fields (order matters if specified).", prop)
	logf("Output: %s\n", msg)
	return msg, nil
}

package context

import (
	"context"
	"fmt"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
)

// EnrichDeterministic re-runs value stats (incl. dense samples), FK cardinality,
// quality issues, and direct join paths — no LLM. Safe to apply on existing RC JSON.
func (c *SharedContext) EnrichDeterministic(ctx context.Context, dbAdapter adapter.DBAdapter) error {
	if c == nil || dbAdapter == nil {
		return fmt.Errorf("EnrichDeterministic: nil context or adapter")
	}

	tableNames := make([]string, 0, len(c.Tables))
	c.mu.RLock()
	for name := range c.Tables {
		tableNames = append(tableNames, name)
	}
	c.mu.RUnlock()

	var firstErr error
	for _, name := range tableNames {
		qc := NewQualityChecker(dbAdapter, c, name)
		if err := qc.RunAll(ctx); err != nil {
			if firstErr == nil {
				firstErr = fmt.Errorf("quality %s: %w", name, err)
			}
			if !c.Quiet {
				fmt.Printf("[Enrich] warn %s: %v\n", name, err)
			}
		}
	}

	c.AnalyzeJoinPaths()
	return firstErr
}

package main

import (
	"context"
	"fmt"
	"strings"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
	"github.com/Zqzqsb/AtlasCore/internal/inference"

	"github.com/tmc/langchaingo/llms"
)

const questionRetryAttempts = 2

func inferenceAttemptOK(res *inference.Result, err error) bool {
	return err == nil && res != nil && strings.TrimSpace(res.GeneratedSQL) != ""
}

// runPipelineWithRetry reruns the whole question on inference failure.
// Attempt 2 gets a short brief from the failed run (error + last ReAct steps).
func runPipelineWithRetry(
	ctx context.Context,
	llm llms.Model,
	dbAdapter adapter.DBAdapter,
	cfg *inference.Config,
	logger *inference.InferenceLogger,
	question string,
) (*inference.Result, error) {
	var last *inference.Result
	var lastErr error
	for attempt := 1; attempt <= questionRetryAttempts; attempt++ {
		if err := ctx.Err(); err != nil {
			if lastErr != nil {
				return last, lastErr
			}
			return nil, err
		}
		if attempt == 1 {
			cfg.RetryHint = ""
		} else {
			var steps []inference.ReActStep
			if last != nil {
				steps = last.ReActSteps
			}
			cfg.RetryHint = inference.FormatRetryHint(lastErr, steps)
			if logger != nil {
				logger.Printf("⚠️  retrying whole question (%d/%d) after: %v\n",
					attempt, questionRetryAttempts, lastErr)
			}
		}
		p := inference.NewPipeline(llm, dbAdapter, cfg)
		if logger != nil {
			p.SetLogger(logger)
		}
		res, err := p.Execute(ctx, question)
		last, lastErr = res, err
		if inferenceAttemptOK(res, err) {
			return res, nil
		}
		if err == nil {
			lastErr = fmt.Errorf("empty SQL")
		}
	}
	if lastErr == nil {
		lastErr = fmt.Errorf("inference failed after %d attempts", questionRetryAttempts)
	}
	return last, lastErr
}

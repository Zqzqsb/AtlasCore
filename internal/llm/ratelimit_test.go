package llm

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/tmc/langchaingo/llms"
)

func TestIsRateLimitMessage(t *testing.T) {
	cases := []struct {
		msg  string
		want bool
	}{
		{"HTTP 429 Too Many Requests", true},
		{"tpm limit exceeded", true},
		{"Rate limit reached", true},
		{"请求速率超过上限", true},
		{"invalid api key", false},
		{"", false},
	}
	for _, c := range cases {
		if got := IsRateLimitMessage(c.msg); got != c.want {
			t.Fatalf("msg=%q got=%v want=%v", c.msg, got, c.want)
		}
	}
}

func TestTPMLimiterWaitsWhenOverBudget(t *testing.T) {
	lim := &TPMLimiter{limit: 100}
	lim.Record(90)
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	start := time.Now()
	// 90+50 > 100 → should wait until window advances; with fresh events, wake ~60s
	// Use tiny window wait by recording an old event via direct inject.
	lim.mu.Lock()
	lim.events = []tokenEvent{{at: time.Now().Add(-59 * time.Second), n: 90}}
	lim.mu.Unlock()

	if err := lim.WaitForBudget(ctx, 50); err != nil {
		t.Fatalf("WaitForBudget: %v", err)
	}
	if time.Since(start) < 500*time.Millisecond {
		// May pass immediately if prune already dropped — either OK if under budget
		used, _ := lim.Usage()
		if used+50 > 100 && time.Since(start) < 100*time.Millisecond {
			t.Fatalf("expected wait when over budget; used=%d elapsed=%v", used, time.Since(start))
		}
	}
}

func TestTPMLimiterAllowsUnderBudget(t *testing.T) {
	lim := &TPMLimiter{limit: 1000}
	lim.ResetForTest()
	ctx := context.Background()
	if err := lim.WaitForBudget(ctx, 100); err != nil {
		t.Fatal(err)
	}
	lim.Record(100)
	used, limit := lim.Usage()
	if used != 100 || limit != 1000 {
		t.Fatalf("used=%d limit=%d", used, limit)
	}
}

type flakyModel struct {
	fails int
	calls int
}

func (m *flakyModel) Call(ctx context.Context, prompt string, options ...llms.CallOption) (string, error) {
	m.calls++
	if m.calls <= m.fails {
		return "", errors.New("429 Too Many Requests: TPM")
	}
	return "ok", nil
}

func (m *flakyModel) GenerateContent(ctx context.Context, messages []llms.MessageContent, options ...llms.CallOption) (*llms.ContentResponse, error) {
	m.calls++
	if m.calls <= m.fails {
		return nil, errors.New("429 Too Many Requests: TPM")
	}
	return &llms.ContentResponse{Choices: []*llms.ContentChoice{{
		Content: "ok",
		GenerationInfo: map[string]any{
			"TotalTokens": 42,
		},
	}}}, nil
}

func TestRateLimitBackoffRetries(t *testing.T) {
	inner := &flakyModel{fails: 2}
	wrapped := WrapWithRateLimit(inner, RateLimitConfig{
		Enabled:           true,
		TPMLimit:          20_000_000,
		CompletionReserve: 10,
		MaxRetries:        3,
		BaseWait:          5 * time.Millisecond,
		MaxWait:           20 * time.Millisecond,
	})
	// isolate limiter
	GlobalTPMLimiter().ResetForTest()
	GlobalTPMLimiter().SetLimit(20_000_000)

	out, err := wrapped.Call(context.Background(), "hello")
	if err != nil {
		t.Fatalf("Call: %v", err)
	}
	if out != "ok" {
		t.Fatalf("got %q", out)
	}
	if inner.calls != 3 {
		t.Fatalf("expected 3 calls (2 fail + 1 ok), got %d", inner.calls)
	}
}

func TestRateLimitBackoffGenerateContent(t *testing.T) {
	inner := &flakyModel{fails: 1}
	wrapped := WrapWithRateLimit(inner, RateLimitConfig{
		Enabled:           true,
		TPMLimit:          20_000_000,
		CompletionReserve: 10,
		MaxRetries:        2,
		BaseWait:          5 * time.Millisecond,
		MaxWait:           20 * time.Millisecond,
	})
	GlobalTPMLimiter().ResetForTest()
	GlobalTPMLimiter().SetLimit(20_000_000)

	resp, err := wrapped.GenerateContent(context.Background(), []llms.MessageContent{
		llms.TextParts(llms.ChatMessageTypeHuman, "hi"),
	})
	if err != nil {
		t.Fatal(err)
	}
	if resp.Choices[0].Content != "ok" {
		t.Fatalf("content=%q", resp.Choices[0].Content)
	}
	used, _ := GlobalTPMLimiter().Usage()
	if used != 42 {
		t.Fatalf("expected record 42 tokens from GenerationInfo, got %d", used)
	}
}

func TestBackoffWaitCaps(t *testing.T) {
	cfg := RateLimitConfig{BaseWait: time.Second, MaxWait: 3 * time.Second}
	if cfg.backoffWait(0) != time.Second {
		t.Fatal(cfg.backoffWait(0))
	}
	if cfg.backoffWait(1) != 2*time.Second {
		t.Fatal(cfg.backoffWait(1))
	}
	if cfg.backoffWait(5) != 3*time.Second {
		t.Fatalf("cap: %v", cfg.backoffWait(5))
	}
}

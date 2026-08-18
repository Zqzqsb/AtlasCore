package llm

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/tmc/langchaingo/llms"
)

const (
	defaultTPMLimit       int64 = 20_000_000 // user budget: TPM <= 20M
	defaultCompletionReserve    = 8192
	defaultMaxRetries           = 5
	defaultBaseWait             = 2 * time.Second
	defaultMaxWait              = 60 * time.Second
	tpmWindow                   = time.Minute
)

// RateLimitConfig controls proactive TPM gating + reactive 429 backoff.
type RateLimitConfig struct {
	Enabled           bool
	TPMLimit          int64         // tokens / rolling 60s; 0 = disable TPM gate only
	CompletionReserve int           // reserved completion tokens per call estimate
	MaxRetries        int           // retries after first attempt on rate-limit / transient
	BaseWait          time.Duration // first backoff; doubles each retry
	MaxWait           time.Duration
}

// DefaultRateLimitConfig reads env overrides.
//
//	LLM_RATE_LIMIT_BACKOFF=off|0|false  → disable entirely
//	LLM_TPM_LIMIT=20000000              → TPM ceiling (default 20M)
//	LLM_TPM_RESERVE=8192                → per-call completion reserve in estimate
func DefaultRateLimitConfig() RateLimitConfig {
	cfg := RateLimitConfig{
		Enabled:           rateLimitEnabledFromEnv(),
		TPMLimit:          tpmLimitFromEnv(),
		CompletionReserve: completionReserveFromEnv(),
		MaxRetries:        defaultMaxRetries,
		BaseWait:          defaultBaseWait,
		MaxWait:           defaultMaxWait,
	}
	return cfg
}

func rateLimitEnabledFromEnv() bool {
	v := strings.TrimSpace(strings.ToLower(os.Getenv("LLM_RATE_LIMIT_BACKOFF")))
	switch v {
	case "0", "false", "off", "no":
		return false
	default:
		return true
	}
}

func tpmLimitFromEnv() int64 {
	v := strings.TrimSpace(os.Getenv("LLM_TPM_LIMIT"))
	if v == "" {
		return defaultTPMLimit
	}
	n, err := strconv.ParseInt(v, 10, 64)
	if err != nil || n < 0 {
		return defaultTPMLimit
	}
	return n
}

// ApplyTPMControl sets the process TPM gate from --tpm-control 50|100|none.
// 50 / 100 are percent of the 20M default; none disables the gate (429 backoff stays on).
func ApplyTPMControl(mode string) error {
	mode = strings.ToLower(strings.TrimSpace(mode))
	var limit int64
	switch mode {
	case "50":
		limit = defaultTPMLimit / 2
	case "100", "":
		limit = defaultTPMLimit
	case "none", "off":
		limit = 0
	default:
		return fmt.Errorf("invalid --tpm-control %q (want 50|100|none)", mode)
	}
	if err := os.Setenv("LLM_TPM_LIMIT", strconv.FormatInt(limit, 10)); err != nil {
		return err
	}
	GlobalTPMLimiter().SetLimit(limit)
	return nil
}

func completionReserveFromEnv() int {
	v := strings.TrimSpace(os.Getenv("LLM_TPM_RESERVE"))
	if v == "" {
		return defaultCompletionReserve
	}
	n, err := strconv.Atoi(v)
	if err != nil || n < 0 {
		return defaultCompletionReserve
	}
	return n
}

// IsRateLimitError reports provider rate-limit / TPM / QPS errors.
func IsRateLimitError(err error) bool {
	if err == nil {
		return false
	}
	return IsRateLimitMessage(err.Error())
}

// IsRateLimitMessage reports whether a message looks like HTTP 429 / TPM / QPS.
func IsRateLimitMessage(msg string) bool {
	if msg == "" {
		return false
	}
	lower := strings.ToLower(msg)
	switch {
	case strings.Contains(lower, "429"):
		return true
	case strings.Contains(lower, "too many requests"):
		return true
	case strings.Contains(lower, "tpm"):
		return true
	case strings.Contains(lower, "rate limit"):
		return true
	case strings.Contains(lower, "rate exceeds"):
		return true
	case strings.Contains(lower, "请求速率超过"):
		return true
	case strings.Contains(msg, "429001"):
		return true
	default:
		return false
	}
}

// IsTransientError is retryable non-rate-limit failure (5xx / timeout).
func IsTransientError(err error) bool {
	if err == nil {
		return false
	}
	lower := strings.ToLower(err.Error())
	switch {
	case strings.Contains(lower, "timeout"):
		return true
	case strings.Contains(lower, "timed out"):
		return true
	case strings.Contains(lower, "503"):
		return true
	case strings.Contains(lower, "502"):
		return true
	case strings.Contains(lower, "500"):
		return true
	case strings.Contains(lower, "529"):
		return true
	case strings.Contains(lower, "overloaded"):
		return true
	case strings.Contains(lower, "temporarily unavailable"):
		return true
	default:
		return false
	}
}

type tokenEvent struct {
	at time.Time
	n  int64
}

// TPMLimiter is a process-wide rolling 60s token budget.
type TPMLimiter struct {
	mu     sync.Mutex
	events []tokenEvent
	limit  int64
}

var globalTPMLimiter = &TPMLimiter{limit: defaultTPMLimit}

// GlobalTPMLimiter returns the shared limiter used by WrapWithRateLimit.
func GlobalTPMLimiter() *TPMLimiter { return globalTPMLimiter }

// SetLimit updates the TPM ceiling (0 disables proactive gating).
func (l *TPMLimiter) SetLimit(limit int64) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.limit = limit
}

// Usage returns tokens recorded in the last 60s and the configured limit.
func (l *TPMLimiter) Usage() (used, limit int64) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.pruneLocked(time.Now())
	return l.sumLocked(), l.limit
}

func (l *TPMLimiter) pruneLocked(now time.Time) {
	cut := now.Add(-tpmWindow)
	i := 0
	for i < len(l.events) && l.events[i].at.Before(cut) {
		i++
	}
	if i > 0 {
		l.events = append([]tokenEvent{}, l.events[i:]...)
	}
}

func (l *TPMLimiter) sumLocked() int64 {
	var s int64
	for _, e := range l.events {
		s += e.n
	}
	return s
}

// WaitForBudget blocks until used+estimate <= limit (or ctx cancelled).
// Does not reserve; Record must be called after a successful call.
func (l *TPMLimiter) WaitForBudget(ctx context.Context, estimate int64) error {
	if estimate < 0 {
		estimate = 0
	}
	for {
		wait, ok := l.tryBudget(estimate)
		if ok {
			return nil
		}
		if wait <= 0 {
			wait = 200 * time.Millisecond
		}
		if err := sleepCtx(ctx, wait); err != nil {
			return err
		}
	}
}

func (l *TPMLimiter) tryBudget(estimate int64) (wait time.Duration, ok bool) {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.limit <= 0 {
		return 0, true
	}
	now := time.Now()
	l.pruneLocked(now)
	used := l.sumLocked()
	if used+estimate <= l.limit {
		return 0, true
	}
	// Wait until oldest event(s) fall out of the window enough to free room.
	need := used + estimate - l.limit
	freed := int64(0)
	var wakeAt time.Time
	for _, e := range l.events {
		freed += e.n
		wakeAt = e.at.Add(tpmWindow)
		if freed >= need {
			break
		}
	}
	if wakeAt.IsZero() {
		return 200 * time.Millisecond, false
	}
	d := time.Until(wakeAt) + 10*time.Millisecond
	if d < 50*time.Millisecond {
		d = 50 * time.Millisecond
	}
	return d, false
}

// Record adds tokens consumed into the rolling window.
func (l *TPMLimiter) Record(n int64) {
	if n <= 0 {
		return
	}
	l.mu.Lock()
	defer l.mu.Unlock()
	now := time.Now()
	l.pruneLocked(now)
	l.events = append(l.events, tokenEvent{at: now, n: n})
}

// ResetForTest clears events (tests only).
func (l *TPMLimiter) ResetForTest() {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.events = nil
}

func sleepCtx(ctx context.Context, wait time.Duration) error {
	if wait <= 0 {
		return nil
	}
	t := time.NewTimer(wait)
	defer t.Stop()
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-t.C:
		return nil
	}
}

func (c RateLimitConfig) backoffWait(attempt int) time.Duration {
	wait := c.BaseWait
	if wait <= 0 {
		wait = defaultBaseWait
	}
	maxWait := c.MaxWait
	if maxWait <= 0 {
		maxWait = defaultMaxWait
	}
	for i := 0; i < attempt; i++ {
		if wait >= maxWait {
			return maxWait
		}
		wait *= 2
	}
	if wait > maxWait {
		return maxWait
	}
	return wait
}

// rateLimitedModel wraps llms.Model with TPM gate + backoff.
type rateLimitedModel struct {
	inner llms.Model
	cfg   RateLimitConfig
	lim   *TPMLimiter
}

// WrapWithRateLimit wraps m. Nil m unchanged. Disabled config still wraps but
// passes through (Enabled checked per call).
func WrapWithRateLimit(m llms.Model, cfg RateLimitConfig) llms.Model {
	if m == nil {
		return nil
	}
	lim := globalTPMLimiter
	lim.SetLimit(cfg.TPMLimit)
	return &rateLimitedModel{inner: m, cfg: cfg, lim: lim}
}

func (m *rateLimitedModel) Call(ctx context.Context, prompt string, options ...llms.CallOption) (string, error) {
	if !m.cfg.Enabled {
		return m.inner.Call(ctx, prompt, options...)
	}
	estimate := estimateTokens(prompt) + int64(m.cfg.CompletionReserve)
	var lastErr error
	for attempt := 0; attempt <= m.cfg.MaxRetries; attempt++ {
		if err := ctx.Err(); err != nil {
			return "", err
		}
		if err := m.lim.WaitForBudget(ctx, estimate); err != nil {
			return "", err
		}
		out, err := m.inner.Call(ctx, prompt, options...)
		if err == nil {
			// Call() rarely returns usage; record estimate.
			m.lim.Record(estimate)
			return out, nil
		}
		lastErr = err
		if !retryable(err) || attempt >= m.cfg.MaxRetries {
			return "", err
		}
		wait := m.cfg.backoffWait(attempt)
		fmt.Printf("⏳ LLM rate-limit/transient backoff attempt=%d/%d wait=%v err=%v\n",
			attempt+1, m.cfg.MaxRetries+1, wait, truncateErr(err))
		if sleepErr := sleepCtx(ctx, wait); sleepErr != nil {
			return "", sleepErr
		}
	}
	return "", lastErr
}

func (m *rateLimitedModel) GenerateContent(ctx context.Context, messages []llms.MessageContent, options ...llms.CallOption) (*llms.ContentResponse, error) {
	if !m.cfg.Enabled {
		return m.inner.GenerateContent(ctx, messages, options...)
	}
	estimate := estimateMessages(messages) + int64(m.cfg.CompletionReserve)
	var lastErr error
	for attempt := 0; attempt <= m.cfg.MaxRetries; attempt++ {
		if err := ctx.Err(); err != nil {
			return nil, err
		}
		if err := m.lim.WaitForBudget(ctx, estimate); err != nil {
			return nil, err
		}
		resp, err := m.inner.GenerateContent(ctx, messages, options...)
		if err == nil {
			n := tokensFromResponse(resp)
			if n <= 0 {
				n = estimate
			}
			m.lim.Record(n)
			return resp, nil
		}
		lastErr = err
		if !retryable(err) || attempt >= m.cfg.MaxRetries {
			return nil, err
		}
		wait := m.cfg.backoffWait(attempt)
		fmt.Printf("⏳ LLM rate-limit/transient backoff attempt=%d/%d wait=%v err=%v\n",
			attempt+1, m.cfg.MaxRetries+1, wait, truncateErr(err))
		if sleepErr := sleepCtx(ctx, wait); sleepErr != nil {
			return nil, sleepErr
		}
	}
	return nil, lastErr
}

func retryable(err error) bool {
	return IsRateLimitError(err) || IsTransientError(err)
}

func estimateTokens(text string) int64 {
	if text == "" {
		return 0
	}
	// Rough char/4 heuristic; prefer overshoot so TPM gate stays conservative.
	n := int64((len(text) + 3) / 4)
	if n < 16 {
		n = 16
	}
	return n
}

func estimateMessages(messages []llms.MessageContent) int64 {
	var n int64
	for _, msg := range messages {
		for _, part := range msg.Parts {
			switch p := part.(type) {
			case llms.TextContent:
				n += estimateTokens(p.Text)
			case llms.ToolCallResponse:
				n += estimateTokens(p.Content)
			case llms.ToolCall:
				if p.FunctionCall != nil {
					n += estimateTokens(p.FunctionCall.Name) + estimateTokens(p.FunctionCall.Arguments)
				}
			}
		}
	}
	if n < 16 {
		n = 16
	}
	return n
}

func tokensFromResponse(resp *llms.ContentResponse) int64 {
	if resp == nil {
		return 0
	}
	for _, c := range resp.Choices {
		if c == nil || c.GenerationInfo == nil {
			continue
		}
		if v, ok := asInt64(c.GenerationInfo["TotalTokens"]); ok && v > 0 {
			return v
		}
		pt, _ := asInt64(c.GenerationInfo["PromptTokens"])
		ct, _ := asInt64(c.GenerationInfo["CompletionTokens"])
		if pt+ct > 0 {
			return pt + ct
		}
	}
	return 0
}

func asInt64(v any) (int64, bool) {
	switch t := v.(type) {
	case int:
		return int64(t), true
	case int32:
		return int64(t), true
	case int64:
		return t, true
	case float64:
		return int64(t), true
	case float32:
		return int64(t), true
	default:
		return 0, false
	}
}

func truncateErr(err error) string {
	if err == nil {
		return ""
	}
	s := err.Error()
	const max = 180
	if len(s) <= max {
		return s
	}
	return s[:max] + "…"
}

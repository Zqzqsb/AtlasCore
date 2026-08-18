package llm

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"strconv"
	"strings"
)

// thinkingTypeForConfig returns the Chat Completions thinking.type to inject.
// Default is "disabled". "enabled" / "auto" / "omit" skip injection.
func thinkingTypeForConfig(cfg ModelConfig) string {
	switch strings.ToLower(strings.TrimSpace(cfg.Thinking)) {
	case "enabled", "auto", "on", "omit":
		return ""
	case "", "disabled", "off", "none":
		return "disabled"
	default:
		return strings.ToLower(strings.TrimSpace(cfg.Thinking))
	}
}

// thinkingDoer injects a top-level Chat Completions "thinking" field.
// langchaingo only serializes extras under "metadata", which TokenHub ignores.
// TokenHub / DeepSeek-V4 accept: {"thinking":{"type":"disabled"}}
type thinkingDoer struct {
	inner        *http.Client
	thinkingType string
}

func (d *thinkingDoer) Do(req *http.Request) (*http.Response, error) {
	req = req.Clone(req.Context())
	if err := injectThinking(req, d.thinkingType); err != nil {
		return nil, err
	}
	return d.inner.Do(req)
}

func injectThinking(req *http.Request, thinkingType string) error {
	if thinkingType == "" || req.Body == nil || req.Method != http.MethodPost {
		return nil
	}
	body, err := io.ReadAll(req.Body)
	_ = req.Body.Close()
	if err != nil {
		return err
	}
	var payload map[string]any
	if err := json.Unmarshal(body, &payload); err != nil {
		req.Body = io.NopCloser(bytes.NewReader(body))
		req.ContentLength = int64(len(body))
		return nil
	}
	if _, exists := payload["thinking"]; !exists {
		payload["thinking"] = map[string]string{"type": thinkingType}
	}
	newBody, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	req.Body = io.NopCloser(bytes.NewReader(newBody))
	req.GetBody = func() (io.ReadCloser, error) {
		return io.NopCloser(bytes.NewReader(newBody)), nil
	}
	req.ContentLength = int64(len(newBody))
	req.Header.Set("Content-Length", strconv.Itoa(len(newBody)))
	return nil
}

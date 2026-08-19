package llm

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestThinkingTypeForConfigDefaultDisabled(t *testing.T) {
	if got := thinkingTypeForConfig(ModelConfig{}); got != "disabled" {
		t.Fatalf("empty config thinking=%q, want disabled", got)
	}
	if got := thinkingTypeForConfig(ModelConfig{Thinking: "enabled"}); got != "enabled" {
		t.Fatalf("enabled should inject type=enabled, got %q", got)
	}
	if got := thinkingTypeForConfig(ModelConfig{Thinking: "DISABLED"}); got != "disabled" {
		t.Fatalf("got %q", got)
	}
}

func TestInjectThinkingDisabled(t *testing.T) {
	var got string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b, _ := io.ReadAll(r.Body)
		got = string(b)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"id":"x","choices":[{"message":{"role":"assistant","content":"pong"}}]}`))
	}))
	defer srv.Close()

	doer := &thinkingDoer{inner: srv.Client(), thinkingType: "disabled"}
	req, err := http.NewRequest(http.MethodPost, srv.URL+"/chat/completions", strings.NewReader(`{"model":"deepseek-v4-pro","messages":[{"role":"user","content":"hi"}]}`))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := doer.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		t.Fatalf("status %d", resp.StatusCode)
	}

	var payload map[string]any
	if err := json.Unmarshal([]byte(got), &payload); err != nil {
		t.Fatal(err)
	}
	th, ok := payload["thinking"].(map[string]any)
	if !ok {
		t.Fatalf("thinking missing: %s", got)
	}
	if th["type"] != "disabled" {
		t.Fatalf("thinking.type=%v", th["type"])
	}
}

func TestInjectThinkingDoesNotOverride(t *testing.T) {
	var got string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b, _ := io.ReadAll(r.Body)
		got = string(b)
		w.WriteHeader(200)
		_, _ = w.Write([]byte(`{}`))
	}))
	defer srv.Close()

	doer := &thinkingDoer{inner: srv.Client(), thinkingType: "disabled"}
	req, err := http.NewRequest(http.MethodPost, srv.URL, strings.NewReader(`{"thinking":{"type":"enabled"}}`))
	if err != nil {
		t.Fatal(err)
	}
	resp, err := doer.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()

	if !strings.Contains(got, `"type":"enabled"`) {
		t.Fatalf("should keep existing thinking: %s", got)
	}
}

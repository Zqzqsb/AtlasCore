package main

import (
	"fmt"
	"testing"

	"github.com/Zqzqsb/AtlasCore/internal/inference"
)

func TestInferenceAttemptOK(t *testing.T) {
	if inferenceAttemptOK(nil, nil) {
		t.Fatal("nil result")
	}
	if inferenceAttemptOK(&inference.Result{}, nil) {
		t.Fatal("empty SQL")
	}
	if !inferenceAttemptOK(&inference.Result{GeneratedSQL: "SELECT 1 FROM t"}, nil) {
		t.Fatal("want ok")
	}
	if inferenceAttemptOK(&inference.Result{GeneratedSQL: "SELECT 1 FROM t"}, fmt.Errorf("boom")) {
		t.Fatal("err should fail")
	}
}

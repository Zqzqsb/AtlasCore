#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LIMIT="${LIMIT:-200}"
START="${START:-0}"
CONTEXT_DIR="${CONTEXT_DIR:-contexts/sqlite/bird_heldout_v1_sparse_v1}"
RUN_TAG="${RUN_TAG:-sparse_v1_n${LIMIT}_r1}"
OUTPUT_DIR="${OUTPUT_DIR:-results/bird/heldout_${RUN_TAG}}"
MODEL="${MODEL:-deepseek-v4-pro}"

if [[ ! -d "$CONTEXT_DIR" ]]; then
  echo "missing frozen context: $CONTEXT_DIR" >&2
  exit 2
fi
if [[ -e "$OUTPUT_DIR/results.json" || -e "$OUTPUT_DIR/predict.sql" ]]; then
  echo "refusing to overwrite completed output: $OUTPUT_DIR" >&2
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
{
  echo "commit=$(git rev-parse HEAD)"
  echo "dirty=$(git status --porcelain | wc -l | tr -d ' ')"
  echo "context_dir=$CONTEXT_DIR"
  echo "context_manifest=$(sha256sum "$CONTEXT_DIR"/*.json | sha256sum | awk '{print $1}')"
  echo "model=$MODEL"
  echo "grounding_mode=sparse"
  echo "start=$START"
  echo "limit=$LIMIT"
} > "$OUTPUT_DIR/run_manifest.txt"

go build -o /tmp/eval_bird_sparse ./cmd/eval

/tmp/eval_bird_sparse \
  --benchmark bird \
  --mode leaderboard \
  --model "$MODEL" \
  --data benchmarks/bird/heldout_v1_smoke/test.json \
  --db-dir benchmarks/bird/heldout_v1_smoke/test_databases \
  --context-dir "$CONTEXT_DIR" \
  --grounding-mode sparse \
  --start "$START" \
  --limit "$LIMIT" \
  --output-dir "$OUTPUT_DIR"

go run ./cmd/eval_ex \
  --predict "$OUTPUT_DIR/predict.sql" \
  --gold benchmarks/bird/heldout_v1_smoke_private/gold.json \
  --db-dir benchmarks/bird/heldout_v1_smoke/test_databases \
  --start "$START" \
  | tee "$OUTPUT_DIR/ex.txt"

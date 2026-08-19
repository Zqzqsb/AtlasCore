#!/usr/bin/env bash
# Inference after offline value-index build (leaderboard + link enhance reads sidecar).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CONTEXT_DIR="${CONTEXT_DIR:-contexts/sqlite/bird_heldout_v1_vi}"
OUTPUT_DIR="${OUTPUT_DIR:-results/bird/heldout_vi_n100_r1}"
MODEL="${MODEL:-deepseek-v4-pro}"
START="${START:-0}"
LIMIT="${LIMIT:-100}"
# all = RC official_meaning + profile notes on every selected-table column
GROUNDING_MODE="${GROUNDING_MODE:-all}"

if [[ ! -d "$CONTEXT_DIR" ]]; then
  echo "missing context dir: $CONTEXT_DIR (run scripts/run_value_index_offline.sh first)" >&2
  exit 2
fi
if [[ -e "$OUTPUT_DIR/predict.sql" || -e "$OUTPUT_DIR/results.json" ]]; then
  echo "refusing to overwrite: $OUTPUT_DIR" >&2
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
{
  echo "commit=$(git rev-parse HEAD)"
  echo "context_dir=$CONTEXT_DIR"
  echo "context_manifest=$(sha256sum "$CONTEXT_DIR"/*.json 2>/dev/null | sha256sum | awk '{print $1}')"
  echo "value_index_dbs=$(ls -1 "$CONTEXT_DIR"/value_index/*.sqlite 2>/dev/null | wc -l | tr -d ' ')"
  echo "model=$MODEL"
  echo "grounding_mode=$GROUNDING_MODE"
  echo "start=$START"
  echo "limit=$LIMIT"
} > "$OUTPUT_DIR/run_manifest.txt"

go build -o /tmp/eval_bird_vi ./cmd/eval

/tmp/eval_bird_vi \
  --benchmark bird \
  --mode leaderboard \
  --model "$MODEL" \
  --data benchmarks/bird/heldout_v1_smoke/test.json \
  --db-dir benchmarks/bird/heldout_v1_smoke/test_databases \
  --context-dir "$CONTEXT_DIR" \
  --grounding-mode "$GROUNDING_MODE" \
  --start "$START" \
  --limit "$LIMIT" \
  --output-dir "$OUTPUT_DIR"

# Local Go EX (multiset bag) — quick sanity
go run ./cmd/eval_ex \
  --predict "$OUTPUT_DIR/predict.sql" \
  --gold benchmarks/bird/heldout_v1_smoke_private/gold.json \
  --db-dir benchmarks/bird/heldout_v1_smoke/test_databases \
  --start "$START" \
  | tee "$OUTPUT_DIR/ex.txt"

# Official BIRD EX (third_party/bird_eval; set-equality) — report this for comparisons
LIMIT_OFFICIAL="$LIMIT"
if [[ "$LIMIT_OFFICIAL" -le 0 ]]; then
  LIMIT_OFFICIAL=0
fi
PREDICT="$OUTPUT_DIR/predict.sql" \
OUT_DIR="$OUTPUT_DIR/bird_official_ex" \
START="$START" \
LIMIT="$LIMIT_OFFICIAL" \
  bash scripts/run_bird_official_ex.sh || true

#!/usr/bin/env bash
# 18-Q probe: current binary, thinking OFF, old react+rc modes, March RC.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SLICE="${SLICE:-$ROOT/data/dev_main_probe}"
OUT="${OUT:-$ROOT/results/bird/dev_probe_nothink}"
MODEL="${MODEL:-deepseek-v4-flash}"
CONTEXT_DIR="${CONTEXT_DIR:-$ROOT/contexts/sqlite/bird}"
DB_DIR="${DB_DIR:-$ROOT/benchmarks/bird/dev/dev_databases}"
BIN="${BIN:-/tmp/eval_probe_nothink}"
PARALLEL="${PARALLEL:-2}"

mkdir -p "$OUT"
{
  echo "started=$(date -Iseconds)"
  echo "commit=$(git rev-parse HEAD)"
  echo "model=$MODEL"
  echo "thinking=disabled"
  echo "context_dir=$CONTEXT_DIR"
  echo "note=current parser+injector; old modes; March RC; thinking off"
} | tee "$OUT/run_manifest.txt"

echo "→ build $BIN"
go build -o "$BIN" ./cmd/eval

run_cell() {
  local name="$1" json="$2" mode="$3"
  local cell="$OUT/$name"
  if [[ -f "$cell/predict.sql" ]]; then
    echo "skip existing $cell/predict.sql"
    return
  fi
  mkdir -p "$cell"
  echo "→ $name mode=$mode thinking=disabled"
  "$BIN" \
    --benchmark bird \
    --mode "$mode" \
    --model "$MODEL" \
    --thinking disabled \
    --data "$json" \
    --db-dir "$DB_DIR" \
    --context-dir "$CONTEXT_DIR" \
    --grounding-mode off \
    --limit 0 \
    --parallel "$PARALLEL" \
    --tpm-control none \
    --log-mode simple \
    --output-dir "$cell"
}

run_cell nocol   "$SLICE/slice.json"             react+rich_context
run_cell clarify "$SLICE/slice_with_fields.json" react+rich_context+clarify

python3.12 "$ROOT/scripts/score_main_dev_probe.py" "$OUT" "$SLICE" \
  "$ROOT/results/bird/dev_official_flash_think" \
  "$ROOT/open_results/20260324_151835_react+rich_context+clarify" \
  | tee "$OUT/summary.txt"

echo "finished=$(date -Iseconds)" | tee -a "$OUT/run_manifest.txt"
echo "Done. $OUT/summary.txt"

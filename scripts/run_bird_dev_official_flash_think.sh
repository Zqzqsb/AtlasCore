#!/usr/bin/env bash
# Official BIRD Dev 1534: gen_all (flash) + value-index + leaderboard flash+think.
# Then local analyze_results (open_results scorer) + official set-EX + vs open_results.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DATA="${DATA:-$ROOT/benchmarks/bird/dev/dev.json}"
GOLD_JSON="${GOLD_JSON:-$ROOT/benchmarks/bird/dev/dev.json}"
DB_DIR="${DB_DIR:-$ROOT/benchmarks/bird/dev/dev_databases}"
CONTEXT_DIR="${CONTEXT_DIR:-$ROOT/contexts/sqlite/bird_dev_official_flash}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT/results/bird/dev_official_flash_think}"
MODEL="${MODEL:-deepseek-v4-flash}"
THINKING="${THINKING:-enabled}"
GROUNDING_MODE="${GROUNDING_MODE:-all}"
WORKERS="${WORKERS:-2}"
PARALLEL="${PARALLEL:-4}"
TPM_CONTROL="${TPM_CONTROL:-none}"
PYTHON="${PYTHON:-python3.12}"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON="python3"

EVAL_BIN="${EVAL_BIN:-/tmp/eval_bird_dev_official_flash}"
GEN_BIN="${GEN_BIN:-/tmp/gen_all_dev_official_flash}"
ENRICH_BIN="${ENRICH_BIN:-/tmp/enrich_rc_official_flash}"
EVAL_EX_BIN="${EVAL_EX_BIN:-/tmp/eval_ex_official_flash}"
ANALYZE_BIN="${ANALYZE_BIN:-/tmp/analyze_results_official_flash}"

if [[ ! -f "$DATA" || ! -d "$DB_DIR" ]]; then
  echo "missing data/db: $DATA $DB_DIR" >&2
  exit 2
fi
if [[ ! -f llm_config.json ]]; then
  echo "missing llm_config.json" >&2
  exit 2
fi

mkdir -p "$OUTPUT_DIR" "$CONTEXT_DIR"
LOG="$OUTPUT_DIR/pipeline.log"
{
  echo "started=$(date -Iseconds)"
  echo "commit=$(git rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "data=$DATA"
  echo "db_dir=$DB_DIR"
  echo "context_dir=$CONTEXT_DIR"
  echo "output_dir=$OUTPUT_DIR"
  echo "model=$MODEL"
  echo "thinking=$THINKING"
  echo "mode=leaderboard"
  echo "grounding_mode=$GROUNDING_MODE"
  echo "workers=$WORKERS parallel=$PARALLEL tpm=$TPM_CONTROL"
} | tee "$OUTPUT_DIR/run_manifest.txt" | tee -a "$LOG"

echo "→ build bins" | tee -a "$LOG"
go build -o "$GEN_BIN" ./cmd/gen_all_dev
go build -o "$ENRICH_BIN" ./cmd/enrich_rc
go build -o "$EVAL_BIN" ./cmd/eval
go build -o "$EVAL_EX_BIN" ./cmd/eval_ex
go build -o "$ANALYZE_BIN" ./cmd/analyze_results

rc_n="$(find "$CONTEXT_DIR" -maxdepth 1 -name '*.json' | wc -l | tr -d ' ')"
if [[ "$rc_n" -lt 11 ]]; then
  echo "→ gen_all_dev ($rc_n/11 existing) → $CONTEXT_DIR" | tee -a "$LOG"
  "$GEN_BIN" \
    --benchmark bird \
    --model "$MODEL" \
    --db-dir "$DB_DIR" \
    --output-dir "$CONTEXT_DIR" \
    --workers "$WORKERS" \
    --skip-existing=true
  rc_n="$(find "$CONTEXT_DIR" -maxdepth 1 -name '*.json' | wc -l | tr -d ' ')"
  echo "gen_all done rc_n=$rc_n" | tee -a "$LOG"
else
  echo "skip gen_all (rc_n=$rc_n)" | tee -a "$LOG"
fi
if [[ "$rc_n" -lt 11 ]]; then
  echo "abort: expected 11 RC json, got $rc_n" >&2
  exit 1
fi

if [[ ! -d "$CONTEXT_DIR/value_index" ]]; then
  echo "→ enrich_rc value index" | tee -a "$LOG"
  "$ENRICH_BIN" \
    --context-dir "$CONTEXT_DIR" \
    --db-dir "$DB_DIR" \
    --phase build \
    --value-index \
    --value-index-label existing
else
  echo "skip enrich_rc (value_index exists)" | tee -a "$LOG"
fi

if [[ ! -f "$OUTPUT_DIR/predict.sql" ]]; then
  echo "→ eval leaderboard flash+think 1534" | tee -a "$LOG"
  "$EVAL_BIN" \
    --benchmark bird \
    --mode leaderboard \
    --model "$MODEL" \
    --thinking "$THINKING" \
    --data "$DATA" \
    --db-dir "$DB_DIR" \
    --context-dir "$CONTEXT_DIR" \
    --grounding-mode "$GROUNDING_MODE" \
    --limit 0 \
    --parallel "$PARALLEL" \
    --tpm-control "$TPM_CONTROL" \
    --log-mode simple \
    --output-dir "$OUTPUT_DIR"
else
  echo "skip eval (predict.sql exists)" | tee -a "$LOG"
fi

npred="$(grep -cve '^$' "$OUTPUT_DIR/predict.sql" 2>/dev/null || echo 0)"
echo "npred=$npred" | tee -a "$LOG"
if [[ "$npred" -lt 1534 ]]; then
  echo "abort: predict n=$npred < 1534" >&2
  exit 1
fi

if [[ ! -f "$OUTPUT_DIR/bird_official_ex/ex_official.txt" ]]; then
  echo "→ official set-EX" | tee -a "$LOG"
  PREDICT="$OUTPUT_DIR/predict.sql" \
  GOLD_JSON="$GOLD_JSON" \
  TEST_JSON="$DATA" \
  DB_DIR="$DB_DIR" \
  OUT_DIR="$OUTPUT_DIR/bird_official_ex" \
  START=0 LIMIT=0 PYTHON="$PYTHON" \
    bash "$ROOT/scripts/run_bird_official_ex.sh" || true
else
  echo "skip official EX" | tee -a "$LOG"
fi

if [[ ! -f "$OUTPUT_DIR/eval_ex.txt" ]]; then
  echo "→ local eval_ex" | tee -a "$LOG"
  "$EVAL_EX_BIN" \
    --predict "$OUTPUT_DIR/predict.sql" \
    --gold "$GOLD_JSON" \
    --db-dir "$DB_DIR" | tee "$OUTPUT_DIR/eval_ex.txt"
else
  echo "skip eval_ex" | tee -a "$LOG"
fi

if [[ ! -f "$OUTPUT_DIR/analysis_reports/summary_report.json" ]]; then
  echo "→ analyze_results (open_results local EX)" | tee -a "$LOG"
  "$ANALYZE_BIN" --input "$OUTPUT_DIR" --db-dir "$DB_DIR" --db-type sqlite || true
else
  echo "skip analyze_results" | tee -a "$LOG"
fi

echo "→ vs open_results" | tee -a "$LOG"
"$PYTHON" "$ROOT/scripts/compare_dev_official_vs_open_results.py" "$OUTPUT_DIR" "$OUTPUT_DIR/vs_open_results.txt"

{
  echo "finished=$(date -Iseconds)"
  echo "npred=$npred"
  echo "official=$(awk '/^accuracy/{print $NF; exit}' "$OUTPUT_DIR/bird_official_ex/ex_official.txt" 2>/dev/null || echo NA)"
} | tee -a "$OUTPUT_DIR/run_manifest.txt" | tee -a "$LOG"

echo
echo "Done. output=$OUTPUT_DIR"
echo "  pipeline log: $LOG"
echo "  vs open_results: $OUTPUT_DIR/vs_open_results.txt"

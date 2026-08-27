#!/usr/bin/env bash
# Orthogonal flash/pro × thinking/no-thinking on the Dev-1106 hard slice.
# Reuses the already-scored pro+think cell from the 1534 run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BIN="${EVAL_BIN:-/tmp/eval_dev1106_ortho}"
SLICE_DIR="${SLICE_DIR:-$ROOT/data/dev_1106_hardslice}"
DATA="${DATA:-$SLICE_DIR/slice.json}"
GOLD_JSON="${GOLD_JSON:-$SLICE_DIR/gold.json}"
DB_DIR="${DB_DIR:-$SLICE_DIR/dev_databases}"
CONTEXT_DIR="${CONTEXT_DIR:-$SLICE_DIR/rc}"
BASE_OUT="${BASE_OUT:-$ROOT/results/bird/dev1106_hardslice_ortho}"
PYTHON="${PYTHON:-python3}"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON="python3.12"
PARALLEL="${PARALLEL:-2}"
TPM_CONTROL="${TPM_CONTROL:-none}"
GROUNDING_MODE="${GROUNDING_MODE:-all}"

if [[ ! -f "$DATA" || ! -f "$GOLD_JSON" ]]; then
  echo "missing slice: $DATA $GOLD_JSON (run scripts/build_dev1106_hardslice.py)" >&2
  exit 2
fi
if [[ ! -d "$DB_DIR" || ! -d "$CONTEXT_DIR" ]]; then
  echo "missing db/rc under $SLICE_DIR" >&2
  exit 2
fi
if [[ ! -f llm_config.json ]]; then
  echo "missing llm_config.json" >&2
  exit 2
fi

echo "→ build $BIN"
go build -o "$BIN" ./cmd/eval

N="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' "$DATA")"
SUMMARY="$BASE_OUT/summary.txt"
mkdir -p "$BASE_OUT"
{
  echo "started=$(date -Iseconds)"
  echo "commit=$(git rev-parse HEAD)"
  echo "n=$N"
  echo "data=$DATA"
  echo "context_dir=$CONTEXT_DIR"
  echo "parallel=$PARALLEL"
} > "$SUMMARY"

score_one() {
  local OUT="$1"
  local npred
  npred="$(grep -cve '^$' "$OUT/predict.sql" 2>/dev/null || echo 0)"
  if [[ "$npred" -lt "$N" ]]; then
    echo "abort: $OUT predict n=$npred < $N" >&2
    echo "FAIL $OUT predict_n=$npred" >> "$SUMMARY"
    exit 1
  fi
  if [[ ! -f "$OUT/bird_official_ex/ex_official.txt" ]]; then
    PREDICT="$OUT/predict.sql" \
    GOLD_JSON="$GOLD_JSON" \
    TEST_JSON="$DATA" \
    DB_DIR="$DB_DIR" \
    OUT_DIR="$OUT/bird_official_ex" \
    START=0 \
    LIMIT=0 \
    PYTHON="$PYTHON" \
      bash scripts/run_bird_official_ex.sh || true
  fi
  local acc
  acc="$(awk '/^accuracy/{print $NF; exit}' "$OUT/bird_official_ex/ex_official.txt" 2>/dev/null || true)"
  echo "$OUT npred=$npred official_ex=${acc:-NA}" | tee -a "$SUMMARY"
}

# Cell 0: reuse 1534 pro+think predictions
PRO_THINK_OUT="$BASE_OUT/pro_think"
if [[ ! -f "$PRO_THINK_OUT/predict.sql" ]]; then
  mkdir -p "$PRO_THINK_OUT"
  cp "$SLICE_DIR/baseline_pro_think.sql" "$PRO_THINK_OUT/predict.sql"
  echo "note=copied from 1534 pro+think; not re-inferred" > "$PRO_THINK_OUT/run_manifest.txt"
fi
score_one "$PRO_THINK_OUT"

run_cell() {
  local NAME="$1"
  local MODEL="$2"
  local THINKING="$3"
  local OUT="$BASE_OUT/$NAME"
  if [[ -f "$OUT/predict.sql" ]]; then
    echo "skip existing $OUT/predict.sql"
  else
    mkdir -p "$OUT"
    {
      echo "commit=$(git rev-parse HEAD)"
      echo "model=$MODEL"
      echo "thinking=$THINKING"
      echo "context_dir=$CONTEXT_DIR"
      echo "grounding_mode=$GROUNDING_MODE"
      echo "parallel=$PARALLEL"
      echo "n=$N"
    } > "$OUT/run_manifest.txt"
    "$BIN" \
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
      --output-dir "$OUT"
  fi
  score_one "$OUT"
}

run_cell flash_think   deepseek-v4-flash enabled
run_cell flash_nothink deepseek-v4-flash disabled
run_cell pro_nothink   deepseek-v4-pro   disabled

echo "finished=$(date -Iseconds)" >> "$SUMMARY"
echo
echo "Done. summary=$SUMMARY"
cat "$SUMMARY"

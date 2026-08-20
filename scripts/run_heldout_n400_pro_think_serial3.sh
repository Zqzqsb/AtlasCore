#!/usr/bin/env bash
# Three *serial* 400-question acceptances: pro+thinking + homonym *History expand.
# Intra-run shards stay --parallel 2; rounds never overlap.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BIN="${EVAL_BIN:-/tmp/eval_n400_homonym}"
CONTEXT_DIR="${CONTEXT_DIR:-contexts/sqlite/bird_heldout_v1_vi_sampled_plan}"
MODEL="${MODEL:-deepseek-v4-pro}"
GROUNDING_MODE="${GROUNDING_MODE:-all}"
ROUNDS="${ROUNDS:-3}"
BASE_OUT="${BASE_OUT:-results/bird/heldout_vi_sampled_n400_pro_think_homonym}"
DATA="${DATA:-benchmarks/bird/heldout_v1_smoke/test.json}"
DB_DIR="${DB_DIR:-benchmarks/bird/heldout_v1_smoke/test_databases}"
GOLD_JSON="${GOLD_JSON:-benchmarks/bird/heldout_v1_smoke_private/gold.json}"
PYTHON="${PYTHON:-python3}"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON="python3.12"
PARALLEL="${PARALLEL:-2}"
TPM_CONTROL="${TPM_CONTROL:-none}"
START="${START:-0}"
LIMIT="${LIMIT:-400}"
MIN_PREDICT="${MIN_PREDICT:-390}"

if [[ ! -d "$CONTEXT_DIR" ]]; then
  echo "missing context dir: $CONTEXT_DIR" >&2
  exit 2
fi
if [[ ! -f llm_config.json ]]; then
  echo "missing llm_config.json" >&2
  exit 2
fi

echo "→ build $BIN"
go build -o "$BIN" ./cmd/eval

SUMMARY="${BASE_OUT}_summary.txt"
mkdir -p "$(dirname "$SUMMARY")"
{
  echo "started=$(date -Iseconds)"
  echo "commit=$(git rev-parse HEAD)"
  echo "dirty=$(git status --porcelain | wc -l | tr -d ' ')"
  echo "bin=$BIN"
  echo "context_dir=$CONTEXT_DIR"
  echo "model=$MODEL"
  echo "grounding_mode=$GROUNDING_MODE"
  echo "rounds=$ROUNDS serial=1 parallel=$PARALLEL"
} > "$SUMMARY"

for i in $(seq 1 "$ROUNDS"); do
  OUT="${BASE_OUT}_r${i}"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▶ round $i/$ROUNDS  $OUT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [[ -e "$OUT/predict.sql" ]]; then
    echo "skip existing $OUT/predict.sql"
  else
    mkdir -p "$OUT"
    {
      echo "commit=$(git rev-parse HEAD)"
      echo "dirty=$(git status --porcelain | wc -l | tr -d ' ')"
      echo "context_dir=$CONTEXT_DIR"
      echo "model=$MODEL"
      echo "grounding_mode=$GROUNDING_MODE"
      echo "parallel=$PARALLEL"
      echo "tpm_control=$TPM_CONTROL"
      echo "start=$START"
      echo "limit=$LIMIT"
      echo "log_mode=simple"
      echo "round=$i/$ROUNDS"
      echo "note=homonym *History expand + distinctive-column hints; serial 3x400; sampled RC; pro+thinking"
    } > "$OUT/run_manifest.txt"

    "$BIN" \
      --benchmark bird \
      --mode leaderboard \
      --model "$MODEL" \
      --data "$DATA" \
      --db-dir "$DB_DIR" \
      --context-dir "$CONTEXT_DIR" \
      --grounding-mode "$GROUNDING_MODE" \
      --start "$START" \
      --limit "$LIMIT" \
      --parallel "$PARALLEL" \
      --tpm-control "$TPM_CONTROL" \
      --log-mode simple \
      --output-dir "$OUT"
  fi

  npred="$(grep -cve '^$' "$OUT/predict.sql" 2>/dev/null || echo 0)"
  if [[ "$npred" -lt "$MIN_PREDICT" ]]; then
    echo "abort: $OUT predict n=$npred < $MIN_PREDICT" >&2
    echo "r$i FAIL predict_n=$npred" >> "$SUMMARY"
    exit 1
  fi

  if [[ ! -f "$OUT/bird_official_ex/ex_official.txt" ]]; then
    PREDICT="$OUT/predict.sql" \
    GOLD_JSON="$GOLD_JSON" \
    TEST_JSON="$DATA" \
    DB_DIR="$DB_DIR" \
    OUT_DIR="$OUT/bird_official_ex" \
    START="$START" \
    LIMIT="$LIMIT" \
    PYTHON="$PYTHON" \
      bash scripts/run_bird_official_ex.sh || true
  else
    echo "skip existing official EX $OUT/bird_official_ex"
  fi

  acc="$(awk '/^accuracy/{print $NF; exit}' "$OUT/bird_official_ex/ex_official.txt" 2>/dev/null || true)"
  echo "r$i npred=$npred official_ex=${acc:-NA} dir=$OUT" | tee -a "$SUMMARY"
done

echo "finished=$(date -Iseconds)" >> "$SUMMARY"
echo
echo "Done. summary=$SUMMARY"
cat "$SUMMARY"

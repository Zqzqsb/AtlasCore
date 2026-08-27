#!/usr/bin/env bash
# Same 45-slice: Qwen3.5 on DashScope. Omit DeepSeek thinking JSON field.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BIN="${EVAL_BIN:-/tmp/eval_dev1106_ortho}"
SLICE_DIR="${SLICE_DIR:-$ROOT/data/dev_1106_hardslice}"
DATA="${DATA:-$SLICE_DIR/slice.json}"
GOLD_JSON="${GOLD_JSON:-$SLICE_DIR/gold.json}"
DB_DIR="${DB_DIR:-$SLICE_DIR/dev_databases}"
CONTEXT_DIR="${CONTEXT_DIR:-$SLICE_DIR/rc}"
OUT="${OUT:-$ROOT/results/bird/dev1106_hardslice_ortho/qwen35}"
PYTHON="${PYTHON:-python3}"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON="python3.12"
PARALLEL="${PARALLEL:-2}"

[[ -x "$BIN" ]] || { echo "missing $BIN" >&2; exit 2; }
[[ -f "$DATA" && -f llm_config.json ]] || { echo "missing slice or llm_config.json" >&2; exit 2; }

N="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' "$DATA")"
mkdir -p "$OUT"
{
  echo "commit=$(git rev-parse HEAD)"
  echo "model=qwen3.5"
  echo "thinking=omit"
  echo "endpoint=dashscope"
  echo "n=$N"
  echo "started=$(date -Iseconds)"
} > "$OUT/run_manifest.txt"

if [[ ! -f "$OUT/predict.sql" ]]; then
  "$BIN" \
    --benchmark bird \
    --mode leaderboard \
    --model qwen3.5 \
    --thinking omit \
    --data "$DATA" \
    --db-dir "$DB_DIR" \
    --context-dir "$CONTEXT_DIR" \
    --grounding-mode all \
    --limit 0 \
    --parallel "$PARALLEL" \
    --tpm-control none \
    --log-mode simple \
    --output-dir "$OUT"
fi

npred="$(grep -cve '^$' "$OUT/predict.sql" 2>/dev/null || echo 0)"
if [[ "$npred" -lt "$N" ]]; then
  echo "abort: predict n=$npred < $N" >&2
  exit 1
fi

if [[ ! -f "$OUT/bird_official_ex/ex_official.txt" ]]; then
  PREDICT="$OUT/predict.sql" \
  GOLD_JSON="$GOLD_JSON" \
  TEST_JSON="$DATA" \
  DB_DIR="$DB_DIR" \
  OUT_DIR="$OUT/bird_official_ex" \
  START=0 LIMIT=0 PYTHON="$PYTHON" \
    bash scripts/run_bird_official_ex.sh
fi

awk '/^accuracy/{print $NF; exit}' "$OUT/bird_official_ex/ex_official.txt"
echo "done $(date -Iseconds) $OUT"

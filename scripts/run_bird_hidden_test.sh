#!/usr/bin/env bash
# External BIRD hidden-test (or a local dry-run of the same flow).
# Generates RC + heuristic value-index if needed, then leaderboard inference.
# Does NOT score EX (no gold). See docs/BIRD_HIDDEN_TEST.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TEST_JSON="${TEST_JSON:-}"
DB_DIR="${DB_DIR:-}"
COLUMN_MEANING="${COLUMN_MEANING:-}"
CONTEXT_DIR="${CONTEXT_DIR:-contexts/sqlite/bird_official_test}"
OUTPUT_DIR="${OUTPUT_DIR:-results/bird/official_test}"
MODEL="${MODEL:-deepseek-v4-pro}"
GROUNDING_MODE="${GROUNDING_MODE:-off}"
START="${START:-0}"
LIMIT="${LIMIT:-0}"
WORKERS="${WORKERS:-2}"
SKIP_PREP="${SKIP_PREP:-0}"
PYTHON="${PYTHON:-python3}"

if [[ -z "$TEST_JSON" || ! -f "$TEST_JSON" ]]; then
  echo "set TEST_JSON to the questions JSON (official BIRD test.json)" >&2
  exit 2
fi
if [[ -z "$DB_DIR" || ! -d "$DB_DIR" ]]; then
  echo "set DB_DIR to the sqlite tree (<db_id>/<db_id>.sqlite)" >&2
  exit 2
fi
if [[ ! -f llm_config.json ]]; then
  echo "missing llm_config.json — copy llm_config.json.example and paste the API key" >&2
  exit 2
fi
if [[ -e "$OUTPUT_DIR/predict.sql" || -e "$OUTPUT_DIR/results.json" ]]; then
  echo "refusing to overwrite: $OUTPUT_DIR" >&2
  exit 2
fi

if [[ "$SKIP_PREP" != "1" ]]; then
  mkdir -p "$CONTEXT_DIR"
  echo "→ Rich Context: $DB_DIR → $CONTEXT_DIR (workers=$WORKERS)"
  go run ./cmd/gen_all_dev \
    --benchmark bird \
    --model "$MODEL" \
    --db-dir "$DB_DIR" \
    --output-dir "$CONTEXT_DIR" \
    --workers "$WORKERS"

  ENRICH_ARGS=(
    --context-dir "$CONTEXT_DIR"
    --db-dir "$DB_DIR"
    --value-index
    --value-index-label heuristic
  )
  if [[ -n "$COLUMN_MEANING" && -f "$COLUMN_MEANING" ]]; then
    ENRICH_ARGS+=(--column-meaning "$COLUMN_MEANING")
  fi
  echo "→ value index (heuristic): ${ENRICH_ARGS[*]}"
  go run ./cmd/enrich_rc "${ENRICH_ARGS[@]}"
fi

if [[ ! -d "$CONTEXT_DIR" ]]; then
  echo "missing context dir: $CONTEXT_DIR (run without SKIP_PREP=1 first)" >&2
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
{
  echo "commit=$(git rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "test_json=$TEST_JSON"
  echo "db_dir=$DB_DIR"
  echo "context_dir=$CONTEXT_DIR"
  echo "column_meaning=${COLUMN_MEANING:-}"
  echo "model=$MODEL"
  echo "grounding_mode=$GROUNDING_MODE"
  echo "start=$START"
  echo "limit=$LIMIT"
} > "$OUTPUT_DIR/run_manifest.txt"

EVAL_BIN="${EVAL_BIN:-/tmp/eval_bird_hidden}"
go build -o "$EVAL_BIN" ./cmd/eval

EVAL_ARGS=(
  --benchmark bird
  --mode leaderboard
  --model "$MODEL"
  --data "$TEST_JSON"
  --db-dir "$DB_DIR"
  --context-dir "$CONTEXT_DIR"
  --grounding-mode "$GROUNDING_MODE"
  --start "$START"
  --limit "$LIMIT"
  --output-dir "$OUTPUT_DIR"
)
if [[ -n "$COLUMN_MEANING" && -f "$COLUMN_MEANING" ]]; then
  EVAL_ARGS+=(--column-meaning "$COLUMN_MEANING")
fi

echo "→ inference: ${EVAL_ARGS[*]}"
"$EVAL_BIN" "${EVAL_ARGS[@]}"

PREDICT="$OUTPUT_DIR/predict.sql"
if [[ ! -f "$PREDICT" ]]; then
  echo "missing $PREDICT after eval" >&2
  exit 1
fi

"$PYTHON" - "$PREDICT" "$OUTPUT_DIR/predict.json" <<'PY'
import json, sys
from pathlib import Path

predict_path, out_path = Path(sys.argv[1]), Path(sys.argv[2])
pred_obj = {}
for i, line in enumerate(predict_path.read_text().splitlines()):
    line = line.strip()
    if not line:
        continue
    parts = line.split("\t")
    sql = parts[0]
    db = parts[1] if len(parts) > 1 else ""
    pred_obj[str(i)] = f"{sql}\t----- bird -----\t{db}"
out_path.write_text(json.dumps(pred_obj, ensure_ascii=False, indent=2) + "\n")
print(f"wrote {out_path} ({len(pred_obj)} preds)")
PY

echo
echo "Done."
echo "  native:  $PREDICT"
echo "  official json: $OUTPUT_DIR/predict.json"
echo "Score with your gold + BIRD evaluation.py (see docs/BIRD_HIDDEN_TEST.md)."

#!/usr/bin/env bash
# Optional wrapper: RC + value-index + leaderboard infer + predict.json.
# Prefer the step-by-step commands in docs/BIRD_HIDDEN_TEST.md (EN) / docs/BIRD_HIDDEN_TEST.zh.md (ZH).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DATA=""
DB_DIR=""
COLUMN_MEANING=""
CONTEXT_DIR="contexts/sqlite/bird_official_test"
OUTPUT_DIR="results/bird/official_test"
MODEL="deepseek-v4-pro"
GROUNDING_MODE="off"
START=0
LIMIT=0
WORKERS=2
SKIP_PREP=0
PARALLEL=1
TPM_CONTROL="100"
PYTHON="${PYTHON:-python3}"

usage() {
  echo "usage: $0 --data TEST.json --db-dir DIR [options]" >&2
  echo "  --data --db-dir --context-dir --output-dir --model" >&2
  echo "  --column-meaning --start --limit --workers --skip-prep" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --data) DATA="$2"; shift 2 ;;
    --db-dir) DB_DIR="$2"; shift 2 ;;
    --column-meaning) COLUMN_MEANING="$2"; shift 2 ;;
    --context-dir) CONTEXT_DIR="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --grounding-mode) GROUNDING_MODE="$2"; shift 2 ;;
    --start) START="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --workers) WORKERS="$2"; shift 2 ;;
    --parallel) PARALLEL="$2"; shift 2 ;;
    --tpm-control) TPM_CONTROL="$2"; shift 2 ;;
    --skip-prep) SKIP_PREP=1; shift ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

if [[ -z "$DATA" || ! -f "$DATA" ]]; then
  echo "missing --data TEST.json" >&2
  exit 2
fi
if [[ -z "$DB_DIR" || ! -d "$DB_DIR" ]]; then
  echo "missing --db-dir sqlite tree" >&2
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
  echo "missing context dir: $CONTEXT_DIR" >&2
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
{
  echo "commit=$(git rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "data=$DATA"
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
  --data "$DATA"
  --db-dir "$DB_DIR"
  --context-dir "$CONTEXT_DIR"
  --grounding-mode "$GROUNDING_MODE"
  --start "$START"
  --limit "$LIMIT"
  --parallel "$PARALLEL"
  --tpm-control "$TPM_CONTROL"
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

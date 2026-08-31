#!/usr/bin/env bash
# Generic eval entry. Per-cell differences are env vars, not a new script.
#
#   MODEL=qwen3-max MODE=react+rich_context+clarify \
#   OUT=results/bird/foo DATA=data/dev_strat300/slice_with_fields.json \
#   PARALLEL=2 GOLD_JSON=data/dev_strat300/gold.json \
#   TMUX_NAME=strat300_qwen3max \
#     bash scripts/run_eval.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODEL="${MODEL:-}"
MODE="${MODE:-}"
OUT="${OUT:-}"
DATA="${DATA:-}"
DB_DIR="${DB_DIR:-}"
CONTEXT_DIR="${CONTEXT_DIR:-}"
PARALLEL="${PARALLEL:-1}"
BENCHMARK="${BENCHMARK:-bird}"
GOLD_JSON="${GOLD_JSON:-}"
TMUX_NAME="${TMUX_NAME:-}"
EVAL_BIN="${EVAL_BIN:-$ROOT/bin/eval}"
EX_PYTHON="${EX_PYTHON:-python3}"
NUM_CPUS="${NUM_CPUS:-8}"
TIMEOUT="${TIMEOUT:-30.0}"

usage() {
  echo "usage: MODEL=... MODE=... OUT=... [DATA=] [PARALLEL=] [GOLD_JSON=] [TMUX_NAME=] $0" >&2
  exit 2
}

if [[ -z "$MODEL" || -z "$MODE" || -z "$OUT" ]]; then
  usage
fi

if [[ -n "$TMUX_NAME" && -z "${TMUX:-}" ]]; then
  if tmux has-session -t "$TMUX_NAME" 2>/dev/null; then
    echo "tmux session already exists: $TMUX_NAME" >&2
    echo "  tmux attach -t $TMUX_NAME" >&2
    exit 1
  fi
  cmd=$(printf 'MODEL=%q MODE=%q OUT=%q DATA=%q DB_DIR=%q CONTEXT_DIR=%q PARALLEL=%q BENCHMARK=%q GOLD_JSON=%q EVAL_BIN=%q bash %q; echo EXIT:$?; exec bash' \
    "$MODEL" "$MODE" "$OUT" "$DATA" "$DB_DIR" "$CONTEXT_DIR" "$PARALLEL" "$BENCHMARK" "$GOLD_JSON" "$EVAL_BIN" "$ROOT/scripts/run_eval.sh")
  tmux new-session -d -s "$TMUX_NAME" -c "$ROOT" "bash -lc $(printf %q "$cmd")"
  echo "started tmux $TMUX_NAME"
  echo "  tmux attach -t $TMUX_NAME"
  exit 0
fi

if [[ ! -f llm_config.json ]]; then
  echo "missing llm_config.json" >&2
  exit 2
fi

mkdir -p "$OUT" "$(dirname "$EVAL_BIN")"
LOG="$OUT/pipeline.log"
{
  echo "started=$(date -Iseconds)"
  echo "commit=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
  echo "model=$MODEL"
  echo "mode=$MODE"
  echo "benchmark=$BENCHMARK"
  echo "data=${DATA:-default}"
  echo "db_dir=${DB_DIR:-default}"
  echo "context_dir=${CONTEXT_DIR:-default}"
  echo "parallel=$PARALLEL"
  echo "out=$OUT"
  echo "bin=$EVAL_BIN"
} | tee "$OUT/run_manifest.txt" | tee -a "$LOG"

need=0
[[ -x "$EVAL_BIN" ]] || need=1
if [[ -x "$EVAL_BIN" ]]; then
  if [[ "$ROOT/cmd/eval/main.go" -nt "$EVAL_BIN" || "$ROOT/cmd/eval/eval_parallel.go" -nt "$EVAL_BIN" ]]; then
    need=1
  fi
fi
if [[ "$need" -eq 1 ]]; then
  echo "→ go build $EVAL_BIN" | tee -a "$LOG"
  go build -o "$EVAL_BIN" ./cmd/eval
else
  echo "skip build ($EVAL_BIN)" | tee -a "$LOG"
fi

args=(
  --benchmark "$BENCHMARK"
  --mode "$MODE"
  --model "$MODEL"
  --parallel "$PARALLEL"
  --limit 0
  --log-mode simple
  --output-dir "$OUT"
)
[[ -n "$DATA" ]] && args+=(--data "$DATA")
[[ -n "$DB_DIR" ]] && args+=(--db-dir "$DB_DIR")
[[ -n "$CONTEXT_DIR" ]] && args+=(--context-dir "$CONTEXT_DIR")

npred() {
  local f="$1"
  [[ -f "$f" ]] || { echo 0; return; }
  grep -cve '^$' "$f" || true
}

if [[ -f "$OUT/predict.sql" ]]; then
  echo "skip eval ($OUT/predict.sql exists, n=$(npred "$OUT/predict.sql"))" | tee -a "$LOG"
else
  echo "→ eval ${args[*]}" | tee -a "$LOG"
  "$EVAL_BIN" "${args[@]}" 2>&1 | tee -a "$LOG"
fi

EVAL_PY="$ROOT/third_party/bird_eval/llm/src/evaluation.py"
EX_DIR="$OUT/bird_official_ex"
if [[ -z "$GOLD_JSON" ]]; then
  echo "skip official EX (no GOLD_JSON)" | tee -a "$LOG"
elif [[ -f "$EX_DIR/ex_official.txt" ]]; then
  echo "skip official EX" | tee -a "$LOG"
elif [[ ! -f "$EVAL_PY" ]]; then
  echo "skip official EX (no $EVAL_PY)" | tee -a "$LOG"
elif [[ ! -f "$OUT/predict.sql" ]]; then
  echo "skip official EX (no predict.sql)" | tee -a "$LOG"
else
  echo "→ official set-EX gold=$GOLD_JSON python=$EX_PYTHON" | tee -a "$LOG"
  STAGE="$EX_DIR/stage"
  mkdir -p "$STAGE"
  DB_ROOT="${DB_DIR:-$ROOT/benchmarks/bird/dev/dev_databases}"
  PREDICT="$OUT/predict.sql" GOLD_JSON="$GOLD_JSON" STAGE="$STAGE" DATA="${DATA:-$GOLD_JSON}" \
  python3 - <<'PY'
import json, os
from pathlib import Path

predict_path = Path(os.environ["PREDICT"])
gold = json.loads(Path(os.environ["GOLD_JSON"]).read_text())
data_path = Path(os.environ["DATA"])
tests = json.loads(data_path.read_text()) if data_path.exists() else gold
stage = Path(os.environ["STAGE"])

preds = []
for line in predict_path.read_text().splitlines():
    line = line.strip()
    if not line:
        continue
    parts = line.split("\t")
    preds.append((parts[0], parts[1] if len(parts) > 1 else ""))

if len(preds) != len(gold):
    raise SystemExit(f"predict n={len(preds)} != gold n={len(gold)}")

pred_obj = {}
for i, ((sql, pdb), g) in enumerate(zip(preds, gold)):
    db = pdb or g.get("db_id") or ""
    pred_obj[str(i)] = f"{sql}\t----- bird -----\t{db}"
(stage / "predict_heldout.json").write_text(json.dumps(pred_obj, ensure_ascii=False, indent=2))

with (stage / "heldout_gold.sql").open("w") as f:
    for g in gold:
        sql = " ".join((g.get("SQL") or "").split())
        f.write(f"{sql}\t{g['db_id']}\n")

diff_items = []
for i, (g, t) in enumerate(zip(gold, tests if isinstance(tests, list) else gold)):
    item = t if isinstance(t, dict) else g
    diff_items.append({
        "question_id": g.get("question_id", i),
        "db_id": g["db_id"],
        "difficulty": item.get("difficulty") or g.get("difficulty") or "",
    })
(stage / "heldout.json").write_text(json.dumps(diff_items, ensure_ascii=False, indent=2))
print(f"staged {len(gold)} → {stage}")
PY
  set +e
  "$EX_PYTHON" -u "$EVAL_PY" \
    --predicted_sql_path "$STAGE/" \
    --ground_truth_path "$STAGE/" \
    --data_mode heldout \
    --db_root_path "${DB_ROOT%/}/" \
    --num_cpus "$NUM_CPUS" \
    --meta_time_out "$TIMEOUT" \
    --mode_gt gt \
    --mode_predict gpt \
    --diff_json_path "$STAGE/heldout.json" \
    2>&1 | tee "$EX_DIR/ex_official.txt" | tee -a "$LOG"
  set -e
fi

{
  echo "finished=$(date -Iseconds)"
  echo "npred=$(npred "$OUT/predict.sql")"
  echo "official=$(awk '/^accuracy/{print $NF; exit}' "$EX_DIR/ex_official.txt" 2>/dev/null || echo NA)"
} | tee -a "$OUT/run_manifest.txt" | tee -a "$LOG"

echo "Done. $OUT"

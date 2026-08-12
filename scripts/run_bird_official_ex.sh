#!/usr/bin/env bash
# Score predict.sql with official BIRD EX (third_party/bird_eval/llm/src/evaluation.py).
# Converts AtlasCore predict/gold into the formats evaluation.py expects.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PREDICT="${PREDICT:-}"
GOLD_JSON="${GOLD_JSON:-benchmarks/bird/heldout_v1_smoke_private/gold.json}"
TEST_JSON="${TEST_JSON:-benchmarks/bird/heldout_v1_smoke/test.json}"
DB_DIR="${DB_DIR:-benchmarks/bird/heldout_v1_smoke/test_databases}"
START="${START:-0}"
LIMIT="${LIMIT:-0}"          # 0 = all remaining from START
OUT_DIR="${OUT_DIR:-}"       # default: next to predict
NUM_CPUS="${NUM_CPUS:-16}"
TIMEOUT="${TIMEOUT:-30.0}"
PYTHON="${PYTHON:-python3}"

if [[ -z "$PREDICT" || ! -f "$PREDICT" ]]; then
  echo "usage: PREDICT=results/.../predict.sql bash scripts/run_bird_official_ex.sh" >&2
  exit 2
fi
if [[ ! -f "$GOLD_JSON" || ! -d "$DB_DIR" ]]; then
  echo "missing gold/db: GOLD_JSON=$GOLD_JSON DB_DIR=$DB_DIR" >&2
  exit 2
fi

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$(dirname "$PREDICT")/bird_official_ex"
fi
STAGE="$OUT_DIR/stage"
mkdir -p "$STAGE"

EVAL_PY="$ROOT/third_party/bird_eval/llm/src/evaluation.py"
if [[ ! -f "$EVAL_PY" ]]; then
  echo "missing official eval: $EVAL_PY" >&2
  exit 2
fi

"$PYTHON" - <<PY
import json, os
from pathlib import Path

predict_path = Path(${PREDICT@Q})
gold_path = Path(${GOLD_JSON@Q})
test_path = Path(${TEST_JSON@Q}) if ${TEST_JSON@Q} and Path(${TEST_JSON@Q}).exists() else None
stage = Path(${STAGE@Q})
start = int(${START@Q})
limit = int(${LIMIT@Q})

preds = []
for line in predict_path.read_text().splitlines():
    line = line.strip()
    if not line:
        continue
    parts = line.split("\t")
    sql = parts[0]
    db = parts[1] if len(parts) > 1 else ""
    preds.append((sql, db))

gold = json.loads(gold_path.read_text())
if start < 0 or start >= len(gold):
    raise SystemExit(f"START={start} out of range for gold n={len(gold)}")
end = len(gold) if limit <= 0 else min(len(gold), start + limit)
gold_slice = gold[start:end]
if len(preds) < len(gold_slice):
    print(f"⚠️  predict n={len(preds)} < gold_slice n={len(gold_slice)}; scoring {len(preds)}")
    gold_slice = gold_slice[: len(preds)]
elif len(preds) > len(gold_slice):
    print(f"⚠️  predict n={len(preds)} > gold_slice n={len(gold_slice)}; truncating predict")
    preds = preds[: len(gold_slice)]

# Official predict_<mode>.json: {"0": "SQL\\t----- bird -----\\tDB", ...}
pred_obj = {}
for i, ((sql, pdb), g) in enumerate(zip(preds, gold_slice)):
    db = pdb or g.get("db_id") or ""
    pred_obj[str(i)] = f"{sql}\t----- bird -----\t{db}"

mode = "heldout"
(stage / f"predict_{mode}.json").write_text(json.dumps(pred_obj, ensure_ascii=False, indent=2))

# Official <mode>_gold.sql: SQL\\tdb_id per line
with (stage / f"{mode}_gold.sql").open("w") as f:
    for g in gold_slice:
        f.write(f"{g['SQL']}\t{g['db_id']}\n")

# difficulty json for by-diff breakdown (heldout has none → leave unset / unknown)
diff_items = []
if test_path is not None:
    tests = json.loads(test_path.read_text())[start : start + len(gold_slice)]
else:
    tests = [{} for _ in gold_slice]
for i, (g, t) in enumerate(zip(gold_slice, tests)):
    diff = t.get("difficulty") or g.get("difficulty") or ""
    # keep empty so counts land in none of the three buckets; total still computed
    diff_items.append({
        "question_id": g.get("question_id", start + i),
        "db_id": g["db_id"],
        "difficulty": diff,
    })
(stage / f"{mode}.json").write_text(json.dumps(diff_items, ensure_ascii=False, indent=2))
print(f"staged {len(gold_slice)} examples → {stage} (mode={mode})")
PY

# evaluation.py joins path + filename; paths must end with /
PRED_DIR="$STAGE/"
GT_DIR="$STAGE/"
DB_ROOT="${DB_DIR%/}/"
DIFF_JSON="$STAGE/heldout.json"

{
  echo "predict=$PREDICT"
  echo "gold_json=$GOLD_JSON"
  echo "db_dir=$DB_DIR"
  echo "start=$START limit=$LIMIT"
  echo "python=$PYTHON"
  echo "eval=$EVAL_PY"
  echo "num_cpus=$NUM_CPUS timeout=$TIMEOUT"
} | tee "$OUT_DIR/run_manifest.txt"

set +e
"$PYTHON" -u "$EVAL_PY" \
  --predicted_sql_path "$PRED_DIR" \
  --ground_truth_path "$GT_DIR" \
  --data_mode heldout \
  --db_root_path "$DB_ROOT" \
  --num_cpus "$NUM_CPUS" \
  --meta_time_out "$TIMEOUT" \
  --mode_gt gt \
  --mode_predict gpt \
  --diff_json_path "$DIFF_JSON" \
  2>&1 | tee "$OUT_DIR/ex_official.txt"
ec=${PIPESTATUS[0]}
set -e
exit "$ec"

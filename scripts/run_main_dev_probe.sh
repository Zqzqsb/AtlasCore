#!/usr/bin/env bash
# Probe typical Dev failures on trunk `main` (old pipeline, March RC).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WT="${WT:-/data/workspace/ReActSqlExp_wt_main}"
SLICE="${SLICE:-$ROOT/data/dev_main_probe}"
OUT="${OUT:-$ROOT/results/bird/main_dev_probe}"
MODEL="${MODEL:-deepseek-v4-flash}"
OLD_RC="${OLD_RC:-$ROOT/contexts/sqlite/bird}"
DB_DIR="${DB_DIR:-$ROOT/benchmarks/bird/dev/dev_databases}"

mkdir -p "$OUT"
{
  echo "started=$(date -Iseconds)"
  echo "wt=$WT"
  echo "model=$MODEL"
  echo "rc=$OLD_RC"
} | tee "$OUT/run_manifest.txt"

if [[ ! -d "$WT/.git" && ! -f "$WT/.git" ]]; then
  echo "→ worktree $WT from main"
  git -C "$ROOT" worktree add "$WT" main
fi

# Isolated data/RC/DBs so we do not touch the primary tree.
mkdir -p "$WT/benchmarks/bird/dev" "$WT/contexts/sqlite"
ln -sfn "$DB_DIR" "$WT/benchmarks/bird/dev/dev_databases"
ln -sfn "$OLD_RC" "$WT/contexts/sqlite/bird"
cp -n "$ROOT/llm_config.json" "$WT/llm_config.json"

echo "→ build eval on main"
git -C "$WT" checkout --force main
( cd "$WT" && go build -o /tmp/eval_main_probe ./cmd/eval )

run_cell() {
  local name="$1" json="$2" mode="$3"
  local cell="$OUT/$name"
  if [[ -f "$cell/predict.sql" ]]; then
    echo "skip existing $cell/predict.sql"
    return
  fi
  mkdir -p "$cell"
  cp "$json" "$WT/benchmarks/bird/dev/dev_with_fields.json"
  echo "→ $name mode=$mode json=$(basename "$json")"
  (
    cd "$WT"
    /tmp/eval_main_probe \
      --benchmark bird \
      --mode "$mode" \
      --model "$MODEL" \
      --limit 0 \
      --log-mode simple \
      --output-dir "$cell"
  )
}

run_cell nocol   "$SLICE/slice.json"             react+rich_context
run_cell clarify "$SLICE/slice_with_fields.json" react+rich_context+clarify

python3.12 "$ROOT/scripts/score_main_dev_probe.py" "$OUT" "$SLICE" \
  "$ROOT/results/bird/dev_official_flash_think" \
  "$ROOT/open_results/20260324_151835_react+rich_context+clarify" \
  | tee "$OUT/summary.txt"

echo "finished=$(date -Iseconds)" | tee -a "$OUT/run_manifest.txt"
echo "Done. $OUT/summary.txt"

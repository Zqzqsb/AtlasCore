#!/usr/bin/env bash
# Offline: copy frozen RC → enrich + label + build value index sidecars.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SRC_RC="${SRC_RC:-contexts/sqlite/bird_heldout_v1_pre_profile}"
DST_RC="${DST_RC:-contexts/sqlite/bird_heldout_v1_vi}"
DB_DIR="${DB_DIR:-benchmarks/bird/heldout_v1_smoke/test_databases}"
COLUMN_MEANING="${COLUMN_MEANING:-benchmarks/bird/heldout_v1_smoke/column_meaning.json}"
LABEL="${LABEL:-heuristic}"   # heuristic | llm
LABEL_MODEL="${LABEL_MODEL:-deepseek-v4-flash}"
DB_FILTER="${DB:-}"            # optional single db_id
LIMIT="${LIMIT:-0}"

if [[ ! -d "$SRC_RC" ]]; then
  echo "missing source RC: $SRC_RC" >&2
  exit 2
fi

if [[ ! -d "$DST_RC" ]]; then
  echo "→ copy $SRC_RC → $DST_RC"
  mkdir -p "$(dirname "$DST_RC")"
  cp -a "$SRC_RC" "$DST_RC"
else
  echo "→ reuse existing $DST_RC"
fi

ARGS=(
  --context-dir "$DST_RC"
  --db-dir "$DB_DIR"
  --value-index
  --value-index-label "$LABEL"
)
if [[ -f "$COLUMN_MEANING" ]]; then
  ARGS+=(--column-meaning "$COLUMN_MEANING")
fi
if [[ "$LABEL" == "llm" ]]; then
  ARGS+=(--label-model "$LABEL_MODEL")
fi
if [[ -n "$DB_FILTER" ]]; then
  ARGS+=(--db "$DB_FILTER")
fi
if [[ "$LIMIT" != "0" ]]; then
  ARGS+=(--limit "$LIMIT")
fi

echo "→ enrich_rc ${ARGS[*]}"
go run ./cmd/enrich_rc "${ARGS[@]}"

echo
echo "Done. Sidecars: $DST_RC/value_index/"
echo "Next: inference with --context-dir $DST_RC"

#!/usr/bin/env bash
# Fetch only sqlite DBs needed by heldout_v1_standard
# Expect BIRD train_databases root via TRAIN_DB_ROOT env, or pass as $1.
set -euo pipefail
SRC="${1:-${TRAIN_DB_ROOT:-}}"
DST="$(cd "$(dirname "$0")" && pwd)/test_databases"
if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "Usage: TRAIN_DB_ROOT=/path/to/train_databases $0"
  echo "   or: $0 /path/to/train_databases"
  exit 1
fi
mkdir -p "$DST"
while read -r db; do
  [[ -z "$db" ]] && continue
  if [[ -d "$SRC/$db" ]]; then
    rsync -a "$SRC/$db" "$DST/"
    echo "ok $db"
  else
    echo "MISSING $db under $SRC" >&2
  fi
done < "$(dirname "$0")/db_ids.txt"
echo "Done -> $DST"

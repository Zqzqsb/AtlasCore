#!/usr/bin/env bash
# Download BIRD train_databases and wire into held-out packs.
# Usage: bash scripts/download_bird_train_dbs.sh [--proxy host:port]
set -euo pipefail
PROXY=""
USE_PROXY=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --proxy)
      USE_PROXY=true
      PROXY="${2:-127.0.0.1:7890}"
      [[ "${2:-}" != --* && -n "${2:-}" ]] && shift
      shift
      ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done
if [[ "$USE_PROXY" == true ]]; then
  export http_proxy="http://$PROXY" https_proxy="http://$PROXY" HTTP_PROXY="http://$PROXY" HTTPS_PROXY="http://$PROXY"
  echo "[INFO] proxy $PROXY"
fi
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRAIN_DIR="$ROOT/benchmarks/bird/train"
mkdir -p "$TRAIN_DIR"
python3 - <<PY
import os
from huggingface_hub import hf_hub_download
print("Downloading Sudnya/bird-sql databases/train_databases.zip ...")
p = hf_hub_download(
    repo_id="Sudnya/bird-sql",
    filename="databases/train_databases.zip",
    repo_type="dataset",
    local_dir="$TRAIN_DIR",
)
print("saved", p, os.path.getsize(p))
PY
ZIP="$TRAIN_DIR/databases/train_databases.zip"
# huggingface may place under databases/
if [[ ! -f "$ZIP" ]]; then
  ZIP=$(find "$TRAIN_DIR" -name 'train_databases.zip' | head -1)
fi
[[ -f "$ZIP" ]] || { echo "zip not found"; exit 1; }
EXTRACT="$TRAIN_DIR/train_databases"
mkdir -p "$EXTRACT"
echo "[INFO] unzipping to $EXTRACT"
unzip -q -o "$ZIP" -d "$TRAIN_DIR/_unzip_tmp"
# normalize layout to train_databases/{db}/{db}.sqlite
if [[ -d "$TRAIN_DIR/_unzip_tmp/train_databases" ]]; then
  rsync -a "$TRAIN_DIR/_unzip_tmp/train_databases/" "$EXTRACT/"
elif [[ -d "$TRAIN_DIR/_unzip_tmp" ]]; then
  # maybe flat list of db folders
  rsync -a "$TRAIN_DIR/_unzip_tmp/" "$EXTRACT/"
fi
rm -rf "$TRAIN_DIR/_unzip_tmp"
echo "[INFO] wiring held-out smoke/standard"
for tier in smoke standard; do
  bash "$ROOT/benchmarks/bird/heldout_v1_${tier}/fetch_databases.sh" "$EXTRACT"
done
echo "[INFO] done"

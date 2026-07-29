#!/usr/bin/env python3
"""Build BIRD held-out packs in official test shape.

Two tiers (seed=42, stratified by db_id):
  smoke     N=400
  standard  N=1500

Outputs (under benchmarks/bird/):
  heldout_v1_{tier}/
    test.json              # no SQL (SQL field omitted or "")
    column_meaning.json    # subset of train_column_meaning for used dbs
    README.md
    db_ids.txt
  heldout_v1_{tier}_private/
    gold.json              # question_id -> {db_id, SQL}
    gold.sql               # one line: SQL\\tdb_id
    manifest.json

Does NOT copy sqlite files; writes fetch_databases.sh listing required db_ids.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import random
import shutil
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRAIN_JSONL = ROOT / "benchmarks/bird/train/data/train-00000-of-00001.jsonl"
COLUMN_MEANING = ROOT / "benchmarks/bird/train/train_column_meaning.json"
OUT_ROOT = ROOT / "benchmarks/bird"

TIERS = {
    "smoke": 400,
    "standard": 1500,
}
SEED = 42


def load_train(path: Path) -> list[dict]:
    rows = []
    with path.open() as f:
        for i, line in enumerate(f):
            line = line.strip()
            if not line:
                continue
            o = json.loads(line)
            o["_src_idx"] = i
            rows.append(o)
    return rows


def stratified_sample(rows: list[dict], n: int, seed: int) -> list[dict]:
    by_db: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        by_db[r["db_id"]].append(r)
    rng = random.Random(seed)
    for db in by_db:
        rng.shuffle(by_db[db])

    dbs = sorted(by_db.keys())
    # Proportional allocation with at least 1 per db when possible
    total = len(rows)
    alloc = {}
    remaining = n
    for i, db in enumerate(dbs):
        if i == len(dbs) - 1:
            alloc[db] = min(len(by_db[db]), remaining)
        else:
            share = max(1, round(n * len(by_db[db]) / total))
            share = min(share, len(by_db[db]), remaining - (len(dbs) - i - 1))
            share = max(0, share)
            alloc[db] = share
            remaining -= share

    # Fix under/over due to rounding
    picked = []
    for db in dbs:
        picked.extend(by_db[db][: alloc[db]])

    if len(picked) < n:
        used = {(r["db_id"], r["_src_idx"]) for r in picked}
        pool = [r for r in rows if (r["db_id"], r["_src_idx"]) not in used]
        rng.shuffle(pool)
        picked.extend(pool[: n - len(picked)])
    elif len(picked) > n:
        rng.shuffle(picked)
        picked = picked[:n]

    rng.shuffle(picked)
    return picked


def subset_column_meaning(all_cm: dict, db_ids: set[str]) -> dict:
    out = {}
    for k, v in all_cm.items():
        db = k.split("|", 1)[0]
        if db in db_ids:
            out[k] = v
    return out


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def build_tier(tier: str, n: int, rows: list[dict], column_meaning: dict) -> None:
    sample = stratified_sample(rows, n, SEED + hash(tier) % 10007)
    # Stable question_id within pack: 0..n-1
    public_dir = OUT_ROOT / f"heldout_v1_{tier}"
    private_dir = OUT_ROOT / f"heldout_v1_{tier}_private"
    if public_dir.exists():
        shutil.rmtree(public_dir)
    if private_dir.exists():
        shutil.rmtree(private_dir)
    public_dir.mkdir(parents=True)
    private_dir.mkdir(parents=True)

    test_items = []
    gold_items = []
    gold_sql_lines = []
    db_ids = set()

    for qid, r in enumerate(sample):
        db_ids.add(r["db_id"])
        test_items.append(
            {
                "question_id": qid,
                "db_id": r["db_id"],
                "question": r["question"],
                "evidence": r.get("evidence") or "",
                "SQL": "",
                "_src_idx": r["_src_idx"],
            }
        )
        gold_items.append(
            {
                "question_id": qid,
                "db_id": r["db_id"],
                "SQL": r["SQL"],
                "_src_idx": r["_src_idx"],
            }
        )
        # Official-ish gold line: SQL \t db_id
        sql_one = " ".join(r["SQL"].split())
        gold_sql_lines.append(f"{sql_one}\t{r['db_id']}")

    test_path = public_dir / "test.json"
    test_path.write_text(json.dumps(test_items, ensure_ascii=False, indent=2) + "\n")

    cm = subset_column_meaning(column_meaning, db_ids)
    cm_path = public_dir / "column_meaning.json"
    cm_path.write_text(json.dumps(cm, ensure_ascii=False, indent=2) + "\n")

    (public_dir / "db_ids.txt").write_text("\n".join(sorted(db_ids)) + "\n")

    gold_json = private_dir / "gold.json"
    gold_json.write_text(json.dumps(gold_items, ensure_ascii=False, indent=2) + "\n")
    gold_sql = private_dir / "gold.sql"
    gold_sql.write_text("\n".join(gold_sql_lines) + "\n")

    manifest = {
        "tier": tier,
        "n": len(test_items),
        "seed": SEED,
        "source": str(TRAIN_JSONL.relative_to(ROOT)),
        "source_n": len(rows),
        "db_count": len(db_ids),
        "db_ids": sorted(db_ids),
        "sha256": {
            "test.json": sha256_file(test_path),
            "gold.json": sha256_file(gold_json),
            "gold.sql": sha256_file(gold_sql),
            "column_meaning.json": sha256_file(cm_path),
        },
        "note": "Inference must NOT read private/. EX scripts only.",
    }
    (private_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    )

    # fetch helper (DBs not included)
    fetch = public_dir / "fetch_databases.sh"
    fetch.write_text(
        f"""#!/usr/bin/env bash
# Fetch only sqlite DBs needed by heldout_v1_{tier}
# Expect BIRD train_databases root via TRAIN_DB_ROOT env, or pass as $1.
set -euo pipefail
SRC="${{1:-${{TRAIN_DB_ROOT:-}}}}"
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
"""
    )
    fetch.chmod(0o755)

    readme = public_dir / "README.md"
    readme.write_text(
        f"""# BIRD held-out v1 — {tier}

- **N**: {len(test_items)} (seed={SEED}, stratified by db_id)
- **Source**: birdsql/bird23-train-filtered ({len(rows)} rows)
- **Official test size (reference)**: 1789
- **DBs used**: {len(db_ids)}

## Layout

- `test.json` — official-test shape (`SQL` empty); for inference only
- `column_meaning.json` — subset for used DBs
- `db_ids.txt` / `fetch_databases.sh` — pull sqlite into `test_databases/`
- Private gold: `../heldout_v1_{tier}_private/` (do not feed to the agent)

## Inference

```bash
go run ./cmd/eval --benchmark bird --mode leaderboard \\
  --data benchmarks/bird/heldout_v1_{tier}/test.json \\
  --db-dir benchmarks/bird/heldout_v1_{tier}/test_databases \\
  --column-meaning benchmarks/bird/heldout_v1_{tier}/column_meaning.json
```
"""
    )

    print(
        f"[{tier}] n={len(test_items)} dbs={len(db_ids)} -> {public_dir.relative_to(ROOT)}"
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tiers", nargs="+", default=list(TIERS.keys()))
    args = ap.parse_args()

    if not TRAIN_JSONL.exists():
        raise SystemExit(f"missing train jsonl: {TRAIN_JSONL}")
    rows = load_train(TRAIN_JSONL)
    cm = {}
    if COLUMN_MEANING.exists():
        cm = json.loads(COLUMN_MEANING.read_text())

    for tier in args.tiers:
        if tier not in TIERS:
            raise SystemExit(f"unknown tier {tier}, choose from {list(TIERS)}")
        n = TIERS[tier]
        if n > len(rows):
            raise SystemExit(f"tier {tier} n={n} > train {len(rows)}")
        build_tier(tier, n, rows, cm)


if __name__ == "__main__":
    main()

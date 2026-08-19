# BIRD held-out v1 — standard

Black-box pack mimicking official BIRD **test** shape (questions without gold SQL).

| | |
|--|--|
| **N** | **1500** |
| **Seed** | `42` (tier offset applied in `scripts/build_heldout_bird.py`) |
| **Sampling** | Stratified by `db_id` (proportional; ≥1 per DB when possible) |
| **Source** | `birdsql/bird23-train-filtered` → `benchmarks/bird/train/data/train-00000-of-00001.jsonl` (**6601** rows) |
| **DBs** | **69** (same DB set cost as smoke; see `db_ids.txt`) |
| **Official test (ref)** | 1789 |

> Full download / eval flow: root [README.md](../../../README.md) → **Datasets**.  
> Prefer **smoke (400)** for iteration; use **standard** for larger validation.

## Layout

```text
heldout_v1_standard/              # public — safe for inference
  test.json                       # SQL="" ; question / evidence / db_id
  column_meaning.json
  db_ids.txt
  fetch_databases.sh
  test_databases/                 # NOT in git
  README.md

heldout_v1_standard_private/      # gitignored — EX only
  gold.json / gold.sql / manifest.json
```

## How this split was made

```bash
python3 scripts/build_heldout_bird.py --tiers standard
# or both: python3 scripts/build_heldout_bird.py
```

Frozen as `heldout_v1`; do not re-roll seed without bumping version.

## Wire databases

```bash
bash scripts/download_bird_train_dbs.sh --proxy 127.0.0.1:7890
# or:
bash benchmarks/bird/heldout_v1_standard/fetch_databases.sh /path/to/train_databases
```

## Inference (no gold)

```bash
go run ./cmd/eval --benchmark bird --mode leaderboard \
  --data benchmarks/bird/heldout_v1_standard/test.json \
  --db-dir benchmarks/bird/heldout_v1_standard/test_databases \
  --context-dir contexts/sqlite/bird_heldout_v1 \
  --output-dir results/bird/heldout_v1_standard_leaderboard
```

## Score EX (private gold only)

```bash
go run ./cmd/eval_ex \
  --predict results/bird/heldout_v1_standard_leaderboard/predict.sql \
  --gold benchmarks/bird/heldout_v1_standard_private/gold.json \
  --db-dir benchmarks/bird/heldout_v1_standard/test_databases
```

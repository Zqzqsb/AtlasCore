# BIRD held-out v1 — smoke

Black-box pack mimicking official BIRD **test** shape (questions without gold SQL).

| | |
|--|--|
| **N** | **400** |
| **Seed** | `42` (tier offset applied in `scripts/build_heldout_bird.py`) |
| **Sampling** | Stratified by `db_id` (proportional; ≥1 per DB when possible) |
| **Source** | `birdsql/bird23-train-filtered` → `benchmarks/bird/train/data/train-00000-of-00001.jsonl` (**6601** rows) |
| **DBs** | **69** (see `db_ids.txt`) |
| **Official test (ref)** | 1789 |

> Full download / eval flow: root [README.md](../../../README.md) → **Datasets**.

## Layout

```text
heldout_v1_smoke/                 # public — safe for inference
  test.json                       # SQL="" ; question / evidence / db_id
  column_meaning.json             # column meanings for used DBs
  db_ids.txt
  fetch_databases.sh              # symlink/copy sqlite from train_databases
  test_databases/                 # NOT in git — created by fetch script
  README.md

heldout_v1_smoke_private/         # gitignored — EX only, never feed to agent
  gold.json / gold.sql / manifest.json
```

## How this split was made

```bash
# Prerequisites under benchmarks/bird/train/ (gitignored):
#   data/train-00000-of-00001.jsonl
#   train_column_meaning.json
python3 scripts/build_heldout_bird.py --tiers smoke
```

Do **not** re-sample casually: `heldout_v1` packs are frozen; changes → new version (`v2`).

## Wire databases

```bash
# Option A — one shot (HF zip + wire smoke & standard)
bash scripts/download_bird_train_dbs.sh --proxy 127.0.0.1:7890

# Option B — already have train_databases/
bash benchmarks/bird/heldout_v1_smoke/fetch_databases.sh \
  /path/to/train_databases
```

Expect `test_databases/{db_id}/{db_id}.sqlite`.

## Inference (no gold)

```bash
go run ./cmd/eval --benchmark bird --mode leaderboard \
  --data benchmarks/bird/heldout_v1_smoke/test.json \
  --db-dir benchmarks/bird/heldout_v1_smoke/test_databases \
  --context-dir contexts/sqlite/bird_heldout_v1 \
  --output-dir results/bird/heldout_v1_smoke_leaderboard
```

- `leaderboard`: clarify=off, output contract + propose_fields (black-box).
- `leaderboard_scale`: same + 6-candidate execution vote.
- Do **not** use `react+rich_context+clarify` (force gold fields) for leaderboard claims.

## Score EX (private gold only)

```bash
go run ./cmd/eval_ex \
  --predict results/bird/heldout_v1_smoke_leaderboard/predict.sql \
  --gold benchmarks/bird/heldout_v1_smoke_private/gold.json \
  --db-dir benchmarks/bird/heldout_v1_smoke/test_databases
```

If `*_private/` is missing (fresh clone): rebuild after placing train jsonl + column_meaning, or obtain private pack from the validation host. Never commit gold into the inference tree.

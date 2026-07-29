# BIRD held-out v1 — standard

- **N**: 1500 (seed=42, stratified by db_id)
- **Source**: birdsql/bird23-train-filtered (6601 rows)
- **Official test size (reference)**: 1789
- **DBs used**: 69

## Layout

- `test.json` — official-test shape (`SQL` empty); for inference only
- `column_meaning.json` — subset for used DBs
- `db_ids.txt` / `fetch_databases.sh` — pull sqlite into `test_databases/`
- Private gold: `../heldout_v1_standard_private/` (do not feed to the agent)

## Inference

```bash
go run ./cmd/eval --benchmark bird --mode leaderboard \
  --data benchmarks/bird/heldout_v1_standard/test.json \
  --db-dir benchmarks/bird/heldout_v1_standard/test_databases \
  --column-meaning benchmarks/bird/heldout_v1_standard/column_meaning.json
```

# BIRD hidden-test reproduction

Chinese version: [BIRD_HIDDEN_TEST.zh.md](BIRD_HIDDEN_TEST.zh.md)

Repo: https://github.com/Zqzqsb/AtlasCore  
Branch: `prepare_for_bird_test` (latest)

Requires Go 1.24+. Replace the paths in the commands with yours.

---

## 1. Clone

```bash
git clone https://github.com/Zqzqsb/AtlasCore.git
cd AtlasCore
```

## 2. Switch branch

```bash
git checkout prepare_for_bird_test
```

## 3. Paste key

```bash
cp llm_config.json.example llm_config.json
```

Paste both keys into the `"token"` fields of the matching blocks in `llm_config.json`. Pick one with `--model` and use the same value in every later step. Thinking is off by default (`"thinking": "disabled"`). Set `"thinking": "enabled"` only if you want DeepSeek-V4 reasoning.

| `--model` | `llm_config.json` block |
| --------- | ----------------------- |
| `deepseek-v4-pro` | `deepseek_v4_pro` |
| `deepseek-v4-pro-official` | `deepseek_v4_pro_official` |

## 4. Gen RC and index

Build Rich Context per database, then the value index.

Point `--db-dir` at your sqlite root. Use the same `--model` as step 3.

```bash
go run ./cmd/gen_all_dev \
  --benchmark bird \
  --model deepseek-v4-pro \
  --db-dir /path/to/test_databases \
  --output-dir contexts/sqlite/bird_official_test \
  --workers 2

go run ./cmd/enrich_rc \
  --context-dir contexts/sqlite/bird_official_test \
  --db-dir /path/to/test_databases \
  --value-index \
  --value-index-label heuristic
```

## 5. Prepare and confirm dataset

Use the official BIRD questions JSON as-is. It is an array with `question_id`, `db_id`, `question`, `evidence`. Extra fields are ignored. Official test leaves `SQL` empty — that is fine.

```json
[
  {
    "question_id": 0,
    "db_id": "california_schools",
    "question": "What is the highest eligible free rate for K-12 students in schools in Alameda County?",
    "evidence": "Eligible free rate for K-12 = `Free Meal Count (K-12)` / `Enrollment (K-12)`",
    "SQL": ""
  }
]
```

SQLite layout (official BIRD tree; `database_description/*.csv` is read automatically when present):

```text
/path/to/test_databases/
  california_schools/california_schools.sqlite
  california_schools/database_description/*.csv
  <db_id>/<db_id>.sqlite
```

Confirm every `db_id` has a matching sqlite file, and that step 4 produced `contexts/sqlite/bird_official_test/<db_id>.json`.

## 6. Smoke test

Run 3 questions first to check wiring. Default inference is sequential; full-run flags are in **Reference** below.

Point `--data` / `--db-dir` at the files from step 5.

```bash
go run ./cmd/eval \
  --benchmark bird \
  --mode leaderboard \
  --model deepseek-v4-pro \
  --data /path/to/test.json \
  --db-dir /path/to/test_databases \
  --context-dir contexts/sqlite/bird_official_test \
  --grounding-mode off \
  --limit 3 \
  --output-dir results/bird/official_test_smoke
```

Success: `results/bird/official_test_smoke/predict.sql` with one `SQL<TAB>db_id` line per question.

## 7. Run full test

Use a fresh `--output-dir` (an existing `predict.sql` is not overwritten). `--limit 0` means all questions. Steps 4 and 7 take a long time — run them in tmux.

```bash
tmux new -s bird_eval
# paste the go run … command below
# detach: Ctrl-b d    reattach: tmux attach -t bird_eval
```

```bash
go run ./cmd/eval \
  --benchmark bird \
  --mode leaderboard \
  --model deepseek-v4-pro \
  --data /path/to/test.json \
  --db-dir /path/to/test_databases \
  --context-dir contexts/sqlite/bird_official_test \
  --grounding-mode off \
  --limit 0 \
  --parallel 4 \
  --tpm-control none \
  --output-dir results/bird/official_test
```

Outputs (same order as `test.json`):

- `results/bird/official_test/predict.sql` — `SQL<TAB>db_id`
- Official `predict.json`:

```bash
python3 - <<'PY'
import json
from pathlib import Path
lines = Path("results/bird/official_test/predict.sql").read_text().splitlines()
obj = {}
for i, line in enumerate(lines):
    line = line.strip()
    if not line:
        continue
    sql, _, db = line.partition("\t")
    obj[str(i)] = f"{sql}\t----- bird -----\t{db}"
Path("results/bird/official_test/predict.json").write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n")
print(len(obj), "preds")
PY
```

After `predict.sql` is ready, score with your gold and the official `evaluation.py`.

---

## Reference

### Official `database_description/*.csv`

Place them next to each sqlite (official BIRD train/dev/test layout). `gen_all_dev` and `enrich_rc` **read them automatically**. No `column_meaning.json` is required. Descriptions are used as reference; RC generation still runs.

| CSV field | Used for |
| --- | --- |
| `column_description` | Referenced during RC gen; stored as column meaning |
| Value encodings / closed enums (`0: N; 1: Y`, `"commander"` lists) | Aliases on the matching value-index entries; recalled by the linker at inference |
| NULL / commonsense rules | Merged into that table's `business_rules` |

CSV filename = table name. Column names match `original_column_name`.

### Inference flags

| Flag | Values | Meaning |
| --- | --- | --- |
| `--parallel` | integer, default `1` | Split questions into N shards under `output-dir/p0`…`p{N-1}`, then merge `predict.sql` / `results.json` / `logs/` |
| `--tpm-control` | `50` / `100` / `none`, default `100` | Internal TPM gate: 50% or 100% of 20M tokens/min; `none` disables the gate (429 backoff stays on) |

### tmux and logs

Run step 4 (RC) and step 7 (full infer) inside tmux (`tmux new -s bird_eval`) so an SSH drop does not kill the job.

| Check | Command |
| --- | --- |
| Still running | `tmux ls` / `tmux attach -t bird_eval` |
| Questions written so far (while `--parallel` is running) | `wc -l results/bird/official_test/p0/predict.sql` |
| Final predictions | `wc -l results/bird/official_test/predict.sql` |
| Compact progress | `tail -f results/bird/official_test/inference.log` (use `p0/inference.log` during a parallel run) |
| One example | `results/bird/official_test/logs/0001_*.log` |

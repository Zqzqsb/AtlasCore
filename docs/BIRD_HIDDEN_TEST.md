# BIRD hidden-test reproduction

Repo: https://github.com/Zqzqsb/AtlasCore  
Branch: `prepare_for_bird_test` (latest)

We provide the repo + an LLM key. You provide `test.json` and sqlite databases. Gold is not used at inference.

```bash
git clone https://github.com/Zqzqsb/AtlasCore.git && cd AtlasCore
git checkout prepare_for_bird_test
cp llm_config.json.example llm_config.json   # paste the emailed token into the matching model block
```

Needs Go 1.24+. Questions JSON: `question_id`, `db_id`, `question`, `evidence`, `SQL=""`.  
SQLite layout: `<DB_DIR>/<db_id>/<db_id>.sqlite`. Optional `column_meaning.json` keys: `db|table|column`.

```bash
TEST_JSON=/path/to/test.json \
DB_DIR=/path/to/test_databases \
COLUMN_MEANING=/path/to/column_meaning.json \   # omit if absent
MODEL=deepseek-v4-pro \
  bash scripts/run_bird_hidden_test.sh
```

`MODEL=deepseek-v4-pro` for Ark/TokenHub; `deepseek-v4-pro-official` for api.deepseek.com.

Outputs (question order): `results/bird/official_test/predict.sql` (`SQL<TAB>db_id`) and `predict.json` (official BIRD shape). Score with your gold + `evaluation.py`.

Inference is sequential (~100s/question). RC generation uses `WORKERS` (default 2). Shard inference with `START`/`LIMIT` and separate `OUTPUT_DIR`s, then concat `predict.sql` in order — only if you have separate keys; one key in parallel will 429.

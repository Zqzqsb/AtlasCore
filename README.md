# ReAct SQL — ATLAS Inference Engine

<p align="center">
  <img src="pics/react_sql.png" width="720" alt="ReAct SQL" />
</p>

<p align="center">
  The standalone experiment framework for the inference engine of
  <b><a href="https://github.com/zqzqsb/atlas">ATLAS</a></b>,
  a Text-to-SQL system presented at VLDB 2026 Demo Track.<br/>
  This repository isolates the core <b>ReAct + Rich Context</b> pipeline for reproducible benchmark evaluation.
</p>

<p align="center">
  <b>76.40%</b> EX on BIRD dev · <b>94.39%</b> EX on Spider dev (calibrated)
</p>

<p align="center">
  Scores in this README and <code>open_results/</code> use our local EX scorer
  (<code>cmd/eval_ex</code>), which is slightly stricter than official BIRD EX.
  See <a href="#evaluators">Evaluators</a>.
</p>

---

## Quick Start

```bash
# 1. Clone & download Dev databases (Spider + BIRD dev)
git clone https://github.com/zqzqsb/AtlasCore.git && cd AtlasCore
bash scripts/download_datasets.sh          # optional: --proxy 127.0.0.1:7890

# 2. Configure LLM API
cp llm_config.json.example llm_config.json
# Edit llm_config.json — fill in your API Key (any OpenAI-compatible model)

# 3. Run evaluation (interactive menu)
go run ./cmd/eval
```

The interactive menu covers Spider / BIRD **dev** and research modes. For black-box held-out / leaderboard evaluation, see [Datasets](#datasets--bird-held-out) below.

```
📦 Select Benchmark
  1. spider  — Spider dev set (1034 examples)
  2. bird    — BIRD dev set (1534 examples)

🎯 Select Evaluation Mode (subset)
  … research modes (baseline / react / rich_context / …)
  leaderboard         Black-box: ReAct+RC, clarify=off, output contract
  leaderboard_scale   leaderboard + 6-candidate execution vote
```

> `react+rich_context+clarify` uses gold-derived result fields — **Dev research only**, not for leaderboard claims.

## Datasets & BIRD Held-out

### What ships where

| Asset | In git? | How to get it |
| ----- | ------- | ------------- |
| Spider / BIRD **dev** questions | mostly yes | DBs via `scripts/download_datasets.sh` |
| BIRD **dev** sqlite | no | `download_datasets.sh` → `benchmarks/bird/dev/dev_databases/` |
| Held-out **public** packs (`test.json`, …) | yes | `benchmarks/bird/heldout_v1_{smoke,standard}/` |
| Held-out **private** gold | **no** (gitignore) | rebuild or copy from validation host — see below |
| BIRD **train** sqlite (~69 DBs used) | no | `scripts/download_bird_train_dbs.sh` |
| Train questions jsonl + column_meaning | no | HuggingFace / rebuild inputs — see below |
| Rich Context for held-out DBs | no | `go run ./cmd/gen_all_dev` (or use a shared `contexts/` dump) |

Pack details: [heldout_v1_smoke/README.md](benchmarks/bird/heldout_v1_smoke/README.md) · [heldout_v1_standard/README.md](benchmarks/bird/heldout_v1_standard/README.md)

### BIRD Dev (ablation / paper numbers)

```bash
bash scripts/download_datasets.sh --proxy 127.0.0.1:7890
go run ./cmd/eval --benchmark bird   # interactive, or pass --mode …
```

### Held-out packs (smoke / standard) — how they were cut

Official BIRD **test** is hidden. We build local held-out sets from the filtered **train** questions in official-test shape (`SQL` empty at inference).

| Tier | N | Role |
| ---- | - | ---- |
| **smoke** | 400 | Fast iteration / CI feel |
| **standard** | 1500 | Main local validation (~official test 1789) |

- **Source**: HuggingFace `birdsql/bird23-train-filtered` → `benchmarks/bird/train/data/train-00000-of-00001.jsonl` (**6601** rows)
- **Sampler**: `scripts/build_heldout_bird.py` — `seed=42`, **stratified by `db_id`** (proportional share, at least one question per DB when possible), then shuffled
- **DBs**: **69** train databases (same set for smoke and standard → one download covers both)
- **Public** `test.json`: `question_id`, `db_id`, `question`, `evidence`, `SQL=""` (+ `_src_idx` for audit)
- **Private** `*_private/gold.json`: gold SQL for `eval_ex` only — **never** pass into the agent / `ClarifyMode=force`
- Train has **no** official `difficulty` labels (those exist on Dev only)

Rebuild (overwrites packs; only do this for a new version):

```bash
# Place under benchmarks/bird/train/ (gitignored):
#   data/train-00000-of-00001.jsonl
#   train_column_meaning.json   # e.g. from TA-SQL / project dump
python3 scripts/build_heldout_bird.py          # both tiers
# python3 scripts/build_heldout_bird.py --tiers smoke
```

Frozen name: `heldout_v1_*`. Changing the sample → bump to `v2`.

### Download train databases & wire held-out

```bash
# Needs: python3, huggingface_hub, unzip, rsync
# Downloads Sudnya/bird-sql databases/train_databases.zip, extracts to
# benchmarks/bird/train/train_databases/, then runs fetch_databases.sh for smoke+standard.
bash scripts/download_bird_train_dbs.sh --proxy 127.0.0.1:7890
```

If you already have `train_databases/{db}/{db}.sqlite`:

```bash
bash benchmarks/bird/heldout_v1_smoke/fetch_databases.sh \
  benchmarks/bird/train/train_databases
# same for standard if needed
```

> HF can be slow. Alternatives: official BIRD train release / other mirrors — unpack so the layout is `train_databases/<db_id>/<db_id>.sqlite`, then run `fetch_databases.sh`.

### Private gold on a fresh clone

`benchmarks/bird/heldout_v1_*_private/` is gitignored. Options:

1. Re-run `build_heldout_bird.py` with the **same** train jsonl (same seed → same split; verify `manifest.json` sha256), or  
2. Copy private packs from the validation machine (recommended for EX continuity).

### Black-box eval (smoke example)

```bash
# Optional: Rich Context for the 69 DBs → contexts/sqlite/bird_heldout_v1/
go run ./cmd/gen_all_dev

go run ./cmd/eval --benchmark bird --mode leaderboard \
  --data benchmarks/bird/heldout_v1_smoke/test.json \
  --db-dir benchmarks/bird/heldout_v1_smoke/test_databases \
  --context-dir contexts/sqlite/bird_heldout_v1 \
  --column-meaning benchmarks/bird/heldout_v1_smoke/column_meaning.json \
  --output-dir results/bird/heldout_v1_smoke_leaderboard

# Local EX (slightly stricter; same scorer as open_results/)
go run ./cmd/eval_ex \
  --predict results/bird/heldout_v1_smoke_leaderboard/predict.sql \
  --gold benchmarks/bird/heldout_v1_smoke_private/gold.json \
  --db-dir benchmarks/bird/heldout_v1_smoke/test_databases

# Official BIRD EX — vendor evaluation.py, then:
#   git clone --depth 1 https://github.com/AlibabaResearch/DAMO-ConvAI.git /tmp/DAMO-ConvAI
#   mkdir -p third_party && ln -s /tmp/DAMO-ConvAI/bird third_party/bird_eval
PREDICT=results/bird/heldout_v1_smoke_leaderboard/predict.sql \
  bash scripts/run_bird_official_ex.sh
```

Experiment status / EX numbers for the current branch live in `iters/7. Handoff-*.md` (handoff; not a download guide).

## Rich Context Generation

<p align="center">
  <img src="pics/rc_gen.png" width="680" alt="Rich Context Generation" />
</p>

Rich Context is the core of this method — a multi-agent system automatically analyzes database structure and generates structured context (field semantics, JOIN paths, data characteristics, etc.).

```bash
# Interactive mode — select benchmark and generate
go run ./cmd/gen_all_dev
```

Pre-generated contexts for 20 Spider + 2 BIRD databases are included in `contexts/sqlite/`.

## ReAct Loop Example

The following is a representative ReAct reasoning loop from a BIRD moderate-difficulty question, demonstrating **self-correction**: the agent detects NULL results from its first attempt and fixes the query by adding null-safety filters.

```
[2/1534] DB: california_schools (difficulty: moderate)
Question: Please list the lowest three eligible free rates for students aged 5-17
         in continuation schools.
Evidence: Eligible free rates for students aged 5-17 =
          `Free Meal Count (Ages 5-17)` / `Enrollment (Ages 5-17)`

┌─ Iteration 1 ─────────────────────────────────────────────────────
│ 💭 Thought: I need to find the lowest three eligible free rates
│    for students aged 5-17 in continuation schools ...
│ 🎯 Action: verify_sql
│ 📥 SELECT CAST("Free Meal Count (Ages 5-17)" AS REAL)
│       / "Enrollment (Ages 5-17)" AS rate
│    FROM frpm
│    WHERE "Educational Option Type" = 'Continuation School'
│    ORDER BY rate ASC LIMIT 3;
│
│ 🔍 Output: ✓ SQL is valid!  Row count: 3
│    Row 1: <nil>   Row 2: <nil>   Row 3: <nil>
│    ⚠️  100% of result values are NULL. This may indicate a wrong
│        JOIN or missing table. Double-check.

┌─ Iteration 2 (Effective: 1/5) ────────────────────────────────────
│ 💭 Thought: All results are NULL. I need to filter out rows where
│    either the numerator or denominator is NULL ...
│ 🎯 Action: verify_sql
│ 📥 SELECT CAST("Free Meal Count (Ages 5-17)" AS REAL)
│       / "Enrollment (Ages 5-17)" AS rate
│    FROM frpm
│    WHERE "Educational Option Type" = 'Continuation School'
│      AND "Free Meal Count (Ages 5-17)" IS NOT NULL
│      AND "Enrollment (Ages 5-17)" IS NOT NULL
│      AND "Enrollment (Ages 5-17)" > 0
│    ORDER BY rate ASC LIMIT 3;
│
│ 🔍 Output: ✓ SQL is valid!  Row count: 3
│    Row 1: 0.0435   Row 2: 0.0704   Row 3: 0.1136

┌─ Iteration 3 (Effective: 2/5) ────────────────────────────────────
│ 💭 Thought: Verification shows valid non-NULL results ...
└─ ✅ Final Answer ──────────────────────────────────
   SELECT ... FROM frpm WHERE ... IS NOT NULL AND ... > 0 ORDER BY ... ASC LIMIT 3;
```

## Result Analysis

```bash
# Interactive mode — auto-discovers results, select and analyze
go run ./cmd/analyze_results
```

## CLI Overview

| Command                               | Description                                                                 |
| ------------------------------------- | --------------------------------------------------------------------------- |
| `go run ./cmd/eval`                   | Run evaluation (Spider / BIRD; modes include `leaderboard`)                 |
| `go run ./cmd/eval_ex`                | Local EX vs **private** gold (no gold in inference; slightly stricter than official) |
| `bash scripts/run_bird_official_ex.sh` | Official BIRD EX wrapper around [`evaluation.py`](https://github.com/AlibabaResearch/DAMO-ConvAI/blob/main/bird/llm/src/evaluation.py) |
| `go run ./cmd/gen_all_dev`            | Generate Rich Context (interactive)                                         |
| `go run ./cmd/analyze_results`        | Analyze evaluation results (interactive)                                    |
| `go run ./cmd/gen_field_descriptions` | Generate result field descriptions for BIRD/Spider datasets                 |
| `go run ./cmd/extract_result_fields`  | (Legacy) Extract result field descriptions from Gold SQL                    |
| `python3 scripts/build_heldout_bird.py` | Rebuild held-out smoke/standard packs from train jsonl                   |
| `bash scripts/download_bird_train_dbs.sh` | Download train sqlite + wire held-out `test_databases/`                |

All Go commands support both **interactive mode** (no args, where applicable) and **CLI mode** (with flags). Run with `--help` for details.

## Evaluators

Two EX scorers are available. Official BIRD EX is usually a bit **higher**.

| Scorer | Source | How it compares rows |
| ------ | ------ | -------------------- |
| **Official BIRD EX** | [`bird/llm/src/evaluation.py`](https://github.com/AlibabaResearch/DAMO-ConvAI/blob/main/bird/llm/src/evaluation.py) in [AlibabaResearch/DAMO-ConvAI](https://github.com/AlibabaResearch/DAMO-ConvAI/tree/main/bird) | Set equality (duplicate rows collapse) |
| **Local EX** | `go run ./cmd/eval_ex` | Order-insensitive **multiset** of row tuples — stricter, so the number is slightly lower |

Local wrapper for the official script (expects `third_party/bird_eval/llm/src/evaluation.py`):

```bash
PREDICT=results/.../predict.sql bash scripts/run_bird_official_ex.sh
```

**Every published number in `open_results/` and in the tables below was scored with the local evaluator**, not `evaluation.py`. Use the official script when comparing to the BIRD leaderboard / hidden test.

## Key Results

> 📄 **Latest run**: [open_results/20260324_151835_react+rich_context+clarify/summary.txt](open_results/20260324_151835_react+rich_context+clarify/summary.txt)

### BIRD Dev Set (1,534 questions, 11 databases)

#### Overall Accuracy

| Configuration                     | EX (%)    | Avg Iters | Δ EX    |
| --------------------------------- | --------- | --------- | ------- |
| **Full ATLAS pipeline**           | **76.40** | **3.37**  | —       |
| − ReAct Loop (one-shot + RC)      | 68.71     | 1.00      | −7.69   |
| − Business rules & value mappings | 72.04     | 3.62      | −4.36   |
| − Sample values & synonyms        | 70.86     | 3.91      | −5.54   |
| Schema only (no Rich Context)     | 65.45     | 4.49      | −10.95  |
| Baseline (direct generation)      | 58.93     | 1.00      | −17.47  |

> **Reading guide**: "− X" means removing component X from the full pipeline.
> *Avg Iters* = average ReAct reasoning iterations per query (1.00 = one-shot, no self-correction).

#### Rich Context Ablation

Each row removes one Rich Context layer from the full pipeline, isolating the contribution of each context component.

| Configuration                     | EX (%)    | Avg Iters |
| --------------------------------- | --------- | --------- |
| Full ATLAS pipeline               | **76.40** | **3.37**  |
| − Business rules & value mappings | 72.04     | 3.62      |
| − Sample values & synonyms        | 70.86     | 3.91      |
| Schema only (no Rich Context)     | 65.45     | 4.49      |

#### Accuracy by Difficulty

| Difficulty  | Total | Correct | EX (%)    | Primary Error Types                                           |
| ----------- | ----- | ------- | --------- | ------------------------------------------------------------ |
| Simple      | 925   | 727     | **78.6%** | row_count: 119, data_mismatch: 79                            |
| Moderate    | 464   | 336     | **72.4%** | data_mismatch: 71, row_count: 53, execution: 3, timeout: 1   |
| Challenging | 145   | 108     | **74.5%** | data_mismatch: 18, row_count: 18, timeout: 1                 |

## Prerequisites

- **Go** >= 1.21 (this branch develops against **1.24.x**; use a matching toolchain if builds fail)
- **LLM API**: Any OpenAI-compatible endpoint (DeepSeek, Qwen, etc.)
- **curl** / **unzip** / **rsync**: dataset download & held-out DB wiring
- **python3** + `huggingface_hub` (+ `sqlglot` if washing projection SFT data): train DB / held-out tooling

## License

MIT License

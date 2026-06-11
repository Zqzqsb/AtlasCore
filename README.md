# ReAct SQL — ATLAS Inference Engine

<p align="center">
  <img src="pics/react_sql.png" width="720" alt="ReAct SQL" />
</p>

<p align="center">
  The standalone experiment framework for the inference engine of
  <b><a href="https://github.com/Zqzqsb/Lucid">ATLAS</a></b>,
  a Text-to-SQL system presented at VLDB 2026 Demo Track.<br/>
  This repository isolates the core <b>ReAct + Rich Context</b> pipeline for reproducible benchmark evaluation.
</p>

<p align="center">
  <b>76.40%</b> EX on BIRD dev · <b>94.39%</b> EX on Spider dev (calibrated)
</p>

---

## Quick Start

```bash
# 1. Clone & download datasets
git clone https://github.com/Zqzqsb/AtlasCore.git && cd AtlasCore
bash scripts/download_datasets.sh

# 2. Configure LLM API
cp llm_config.json.example llm_config.json
# Edit llm_config.json — fill in your API Key (any OpenAI-compatible model)

# 3. Run evaluation (interactive menu)
go run ./cmd/eval
```

The interactive menu will guide you through benchmark selection (Spider / BIRD) and evaluation mode:

```
📦 Select Benchmark
  1. spider  — Spider dev set (1034 examples)
  2. bird    — BIRD dev set (1534 examples)

🎯 Select Evaluation Mode
  1. baseline                   Direct SQL generation
  2. react                      Multi-step reasoning with tool use
  3. rich_context               Enhanced schema context
  4. react+rich_context         ReAct + Rich Context
  5. react+rich_context+linking Full pipeline with schema linking
  6. full                       All features enabled
```

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

| Command                               | Description                                                 |
| ------------------------------------- | ----------------------------------------------------------- |
| `go run ./cmd/eval`                   | Run evaluation (Spider / BIRD, interactive)                 |
| `go run ./cmd/gen_all_dev`            | Generate Rich Context (interactive)                         |
| `go run ./cmd/analyze_results`        | Analyze evaluation results (interactive)                    |
| `go run ./cmd/gen_field_descriptions` | Generate result field descriptions for BIRD/Spider datasets |
| `go run ./cmd/extract_result_fields`  | (Legacy) Extract result field descriptions from Gold SQL    |

All commands support both **interactive mode** (no args) and **CLI mode** (with flags). Run with `--help` for details.

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

- **Go** >= 1.21
- **LLM API**: Any OpenAI-compatible endpoint (DeepSeek-V3, Qwen-3 Max, etc.)
- **curl** + **unzip**: For dataset download

## License

MIT License

# ReAct SQL — ATLAS Inference Engine

<p align="center">
  <img src="pics/react_sql.png" width="720" alt="ReAct SQL" />
</p>

<p align="center">
  The standalone experiment framework for the inference engine of
  <b><a href="https://github.com/Zqzqsb/Lucid">ATLAS</a></b>,
  a lake-based Text-to-SQL system presented at VLDB 2025 Demo Track.<br/>
  This repository isolates the core <b>ReAct + Rich Context</b> pipeline for reproducible benchmark evaluation.
</p>

<p align="center">
  <b>75.55%</b> EX on BIRD dev · <b>94.39%</b> EX on Spider dev (calibrated) · DeepSeek-V3
</p>

---

## Quick Start

```bash
# 1. Clone & download datasets
git clone <repo-url> && cd ReActSqlExp
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

### BIRD Dev Set (1,534 questions, 11 databases, DeepSeek-V3)

#### Overall Accuracy

| Configuration                     | EX (%)    | Avg Iters | Δ EX    |
| --------------------------------- | --------- | --------- | ------- |
| **Full ATLAS pipeline**           | **75.55** | **3.37**  | —       |
| − ReAct Loop (one-shot + RC)      | 68.71     | 1.00      | −6.84   |
| − Business rules & value mappings | 72.04     | 3.62      | −3.51   |
| − Sample values & synonyms        | 70.86     | 3.91      | −4.69   |
| Schema only (no Rich Context)     | 65.45     | 4.49      | −10.10  |
| Baseline (direct generation)      | 58.93     | 1.00      | −16.62  |

> **Reading guide**: "− X" means removing component X from the full pipeline.
> *Avg Iters* = average ReAct reasoning iterations per query (1.00 = one-shot, no self-correction).

#### Rich Context Ablation

Each row removes one Rich Context layer from the full pipeline, isolating the contribution of each context component.

| Configuration                     | EX (%)    | Avg Iters |
| --------------------------------- | --------- | --------- |
| Full ATLAS pipeline               | **75.55** | **3.37**  |
| − Business rules & value mappings | 72.04     | 3.62      |
| − Sample values & synonyms        | 70.86     | 3.91      |
| Schema only (no Rich Context)     | 65.45     | 4.49      |

#### Accuracy by Difficulty

| Difficulty  | Total | Correct | EX (%)    | Primary Error Types                        |
| ----------- | ----- | ------- | --------- | ------------------------------------------ |
| Simple      | 925   | 725     | **78.4%** | row_count: 111, data_mismatch: 79          |
| Moderate    | 464   | 332     | **71.6%** | data_mismatch: 70, row_count: 56           |
| Challenging | 145   | 101     | **69.7%** | row_count: 20, data_mismatch: 20           |

## Prerequisites

- **Go** >= 1.21
- **LLM API**: Any OpenAI-compatible endpoint (DeepSeek-V3, Qwen-3 Max, etc.)
- **curl** + **unzip**: For dataset download

## License

MIT License

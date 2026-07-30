#!/usr/bin/env python3
"""Wash BIRD gold SQL into projection-field SFT data for TaiJi.

Deterministically parse SELECT projections (sqlglot) — no LLM.
Excludes held-out questions to avoid leakage.

Outputs under data/proj_fields/:
  train.jsonl          — rich records (for analysis / RL rewards)
  taiji_sft.jsonl      — alpaca-style for 模版化 SFT
  probe_report.md      — signal stats + design notes
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any

import sqlglot
from sqlglot import exp

ROOT = Path(__file__).resolve().parents[1]


def parse_projection(sql: str) -> dict[str, Any] | None:
    """Extract ordered output fields + shape from gold SQL."""
    try:
        tree = sqlglot.parse_one(sql, read="sqlite")
    except Exception:
        return None

    sel: exp.Select | None
    if isinstance(tree, exp.With):
        sel = tree.this if isinstance(tree.this, exp.Select) else tree.find(exp.Select)
    elif isinstance(tree, exp.Select):
        sel = tree
    else:
        sel = tree.find(exp.Select)
    if sel is None:
        return None

    fields: list[dict[str, str]] = []
    for e in sel.expressions:
        node = e.this if isinstance(e, exp.Alias) else e
        kind = "col"
        for agg_t, name in (
            (exp.Count, "count"),
            (exp.Avg, "avg"),
            (exp.Sum, "sum"),
            (exp.Max, "max"),
            (exp.Min, "min"),
        ):
            if node.find(agg_t):
                kind = name
                break
        if isinstance(node, exp.Star):
            kind = "star"

        expr_sql = re.sub(r"\s+", " ", node.sql(dialect="sqlite")).strip()
        alias = e.alias if isinstance(e, exp.Alias) else ""
        if alias:
            out_name = alias
        elif isinstance(node, exp.Column):
            out_name = node.name
        else:
            out_name = expr_sql

        fields.append({"name": out_name, "expr": expr_sql, "kind": kind})

    has_group = sel.args.get("group") is not None
    has_agg = any(f["kind"] in {"count", "avg", "sum", "max", "min"} for f in fields)
    limit = sel.args.get("limit")
    limit_1 = False
    if limit is not None:
        lim_sql = limit.sql(dialect="sqlite")
        limit_1 = bool(re.search(r"\b1\b", lim_sql)) and not re.search(r"\b1\d", lim_sql)

    if has_agg and not has_group:
        shape = "scalar"
    elif has_agg and has_group:
        shape = "table"
    elif limit_1:
        shape = "entity"
    else:
        shape = "list"

    return {
        "shape": shape,
        "fields": fields,
        "has_group": bool(has_group),
        "has_agg": has_agg,
        "limit_1": limit_1,
    }


def schema_text(db_id: str, tables_by_db: dict[str, Any], max_cols: int = 80) -> str:
    meta = tables_by_db.get(db_id)
    if not meta:
        return f"Database: {db_id}\n(schema unavailable)"
    table_names = meta.get("table_names_original") or meta.get("table_names") or []
    cols = meta.get("column_names_original") or meta.get("column_names") or []
    lines = [f"Database: {db_id}", "Tables/Columns:"]
    by_table: dict[int, list[str]] = {}
    for pair in cols:
        if not isinstance(pair, list) or len(pair) < 2:
            continue
        ti, cname = pair[0], pair[1]
        if ti < 0:
            continue
        by_table.setdefault(ti, []).append(cname)
    n = 0
    for ti, tname in enumerate(table_names):
        cl = by_table.get(ti, [])
        chunk = ", ".join(cl[:40])
        if len(cl) > 40:
            chunk += ", ..."
        lines.append(f"- {tname}({chunk})")
        n += len(cl)
        if n >= max_cols:
            lines.append("- ...")
            break
    return "\n".join(lines)


def target_obj(proj: dict[str, Any]) -> dict[str, Any]:
    """Canonical model output object (reward-friendly)."""
    return {
        "shape": proj["shape"],
        "fields": [{"name": f["name"], "kind": f["kind"]} for f in proj["fields"]],
    }


def target_text(obj: dict[str, Any]) -> str:
    """Single-line JSON assistant target for SFT."""
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def build_user_prompt(question: str, evidence: str, schema: str) -> str:
    return (
        "You predict the BIRD gold SQL output projection (not the full SQL).\n"
        "Return ONLY a JSON object with keys:\n"
        '  shape: one of "scalar" | "list" | "entity" | "table"\n'
        "  fields: ordered list of {name, kind} where kind in "
        "col|count|avg|sum|max|min|star\n"
        "Rules:\n"
        "- Follow gold taste: if gold returns a row list instead of COUNT, use shape=list.\n"
        "- Preserve field ORDER; prefer aliases / result column names.\n"
        "- Do not invent columns not needed by the gold projection.\n\n"
        f"{schema}\n\n"
        f"Question: {question}\n"
        f"Evidence: {evidence or '(none)'}\n"
    )


def load_tables(path: Path) -> dict[str, Any]:
    raw = json.loads(path.read_text())
    return {x["db_id"]: x for x in raw}


def heldout_keys(root: Path) -> set[tuple[str, str]]:
    keys: set[tuple[str, str]] = set()
    for tier in ("smoke", "standard"):
        p = root / f"benchmarks/bird/heldout_v1_{tier}/test.json"
        if not p.exists():
            continue
        for x in json.loads(p.read_text()):
            keys.add((x["db_id"], x["question"].strip()))
    return keys


def nl_wants_count(question: str) -> bool:
    q = question.lower()
    return any(
        w in q
        for w in (
            "how many",
            "number of",
            "count the",
            "total number",
            "what is the number",
            "what's the number",
        )
    )


def wash_split(
    examples: list[dict[str, Any]],
    tables_by_db: dict[str, Any],
    exclude: set[tuple[str, str]],
    split: str,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], Counter]:
    rich: list[dict[str, Any]] = []
    taiji: list[dict[str, Any]] = []
    stats: Counter = Counter()
    for i, x in enumerate(examples):
        db_id = x["db_id"]
        question = x["question"]
        if (db_id, question.strip()) in exclude:
            stats["excluded_heldout"] += 1
            continue
        sql = x.get("SQL") or x.get("query") or ""
        proj = parse_projection(sql)
        if proj is None:
            stats["parse_fail"] += 1
            continue
        stats["ok"] += 1
        stats[f"shape_{proj['shape']}"] += 1
        stats[f"nfields_{len(proj['fields'])}"] += 1
        if nl_wants_count(question) and proj["shape"] == "list":
            stats["nl_count_but_gold_list"] += 1
        if nl_wants_count(question) and proj["shape"] == "scalar":
            stats["nl_count_and_gold_scalar"] += 1

        tgt = target_obj(proj)
        schema = schema_text(db_id, tables_by_db)
        user = build_user_prompt(question, x.get("evidence", ""), schema)
        assistant = target_text(tgt)

        rich.append(
            {
                "id": f"{split}_{i}",
                "split": split,
                "db_id": db_id,
                "question": question,
                "evidence": x.get("evidence", ""),
                "SQL": sql,
                "projection": proj,
                "target": tgt,
                "difficulty": x.get("difficulty"),
            }
        )
        taiji.append(
            {
                "instruction": (
                    "Predict BIRD gold SQL output projection as JSON "
                    '(keys: shape, fields[{name,kind}]).'
                ),
                "input": user,
                "output": assistant,
                "meta": {"id": f"{split}_{i}", "db_id": db_id, "split": split},
            }
        )
    return rich, taiji, stats


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")


def probe_report(stats_map: dict[str, Counter], samples: list[dict[str, Any]], out: Path) -> None:
    lines: list[str] = []
    lines.append("# Projection-field wash probe\n")
    lines.append("## Counts\n")
    for name, st in stats_map.items():
        lines.append(f"### {name}\n")
        lines.append("```")
        for k, v in sorted(st.items(), key=lambda kv: (-kv[1], kv[0])):
            lines.append(f"{k}: {v}")
        lines.append("```\n")

    lines.append("## Output target design\n")
    lines.append(
        "Assistant emits **one JSON object**:\n\n"
        "```json\n"
        '{"shape":"scalar|list|entity|table","fields":[{"name":"...","kind":"col|count|..."}]}\n'
        "```\n\n"
        "| shape | Meaning |\n"
        "|-------|--------|\n"
        "| scalar | Aggregates without GROUP BY (typical one-number answer) |\n"
        "| list | Multi-row projection (gold returns rows, even if NL says how many) |\n"
        "| entity | Non-agg with LIMIT 1 |\n"
        "| table | Agg + GROUP BY |\n\n"
        "**Why shape matters:** BIRD often returns a **list of ids** when the question "
        "says “how many”; forcing COUNT loses EX. Shape is a first-class label.\n"
    )
    lines.append("## Reward signals (for later GRPO)\n")
    lines.append(
        "1. **Field-set F1** on `fields[].name` (normalize case/backticks).\n"
        "2. **Order exact-match** bonus if names equal as sequences.\n"
        "3. **Shape exact-match** (high weight — fixes count-vs-list).\n"
        "4. **Kind match** optional (count vs col).\n"
        "5. Optional downstream: freeze SQL agent, only vary projection contract → EX.\n"
    )
    lines.append("## Gold-quirk samples (NL count → gold list)\n")
    n = 0
    for r in samples:
        if not nl_wants_count(r["question"]):
            continue
        if r["target"]["shape"] != "list":
            continue
        lines.append(f"- **{r['db_id']}**: {r['question'][:100]}")
        lines.append(f"  - target: `{target_text(r['target'])}`")
        lines.append(f"  - sql: `{r['SQL'][:140]}`")
        n += 1
        if n >= 8:
            break
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", default=str(ROOT / "data/proj_fields"))
    ap.add_argument("--train", default=str(ROOT / "benchmarks/bird/train/train.json"))
    ap.add_argument("--dev", default=str(ROOT / "benchmarks/bird/dev/dev.json"))
    ap.add_argument(
        "--tables",
        default=str(ROOT / "benchmarks/bird/train/train_tables.json"),
        help="Also tries benchmarks/bird/dev/dev_tables.json for missing DBs",
    )
    args = ap.parse_args()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    tables_by_db = load_tables(Path(args.tables))
    dev_tables = ROOT / "benchmarks/bird/dev/dev_tables.json"
    if dev_tables.exists():
        tables_by_db.update(load_tables(dev_tables))

    exclude = heldout_keys(ROOT)
    print(f"held-out exclude keys: {len(exclude)}")

    train = json.loads(Path(args.train).read_text())
    rich_tr, taiji_tr, st_tr = wash_split(train, tables_by_db, exclude, "train")

    rich_dv: list[dict[str, Any]] = []
    taiji_dv: list[dict[str, Any]] = []
    st_dv: Counter = Counter()
    if Path(args.dev).exists():
        dev = json.loads(Path(args.dev).read_text())
        rich_dv, taiji_dv, st_dv = wash_split(dev, tables_by_db, set(), "dev")

    write_jsonl(out_dir / "train_rich.jsonl", rich_tr)
    write_jsonl(out_dir / "taiji_sft_train.jsonl", taiji_tr)
    if rich_dv:
        write_jsonl(out_dir / "dev_rich.jsonl", rich_dv)
        write_jsonl(out_dir / "taiji_sft_dev.jsonl", taiji_dv)

    # small preview for TaiJi upload smoke
    write_jsonl(out_dir / "taiji_sft_train_preview100.jsonl", taiji_tr[:100])

    probe_report(
        {"train": st_tr, "dev": st_dv},
        rich_tr,
        out_dir / "probe_report.md",
    )

    # design sidecar for TaiJi form
    (out_dir / "README.md").write_text(
        "\n".join(
            [
                "# proj_fields SFT pack",
                "",
                "Upload **`taiji_sft_train.jsonl`** to TaiJi 数据仓库 (alpaca: instruction/input/output).",
                "Use **`taiji_sft_dev.jsonl`** as eval if the template supports it.",
                "",
                "Held-out smoke/standard questions are **excluded** from train.",
                "",
                "See `probe_report.md` for signal design.",
                "",
                f"Train rows: {len(taiji_tr)}",
                f"Dev rows: {len(taiji_dv)}",
                "",
            ]
        ),
        encoding="utf-8",
    )

    print(f"train ok={st_tr['ok']} excluded={st_tr['excluded_heldout']} fail={st_tr['parse_fail']}")
    print(f"dev ok={st_dv['ok']}")
    print(f"wrote {out_dir}")


if __name__ == "__main__":
    main()

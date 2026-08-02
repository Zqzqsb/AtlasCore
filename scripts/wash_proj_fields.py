#!/usr/bin/env python3
"""Wash BIRD gold SQL into projection-field SFT data.

Deterministically parse SELECT projections (sqlglot) — no LLM.
Excludes held-out questions to avoid leakage.

Label versions:
  v1 — legacy: name may be full SQL expr (COUNT(T2.x)); full-DB schema
  v2 — normalized short names + kind; gold-table (+FK hop) schema (default)

Outputs under --out-dir (default data/proj_fields_v2 for v2).
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

AGG_KINDS = ("count", "avg", "sum", "max", "min")
LABEL_VERSION = "v2"


def _strip_ident(s: str) -> str:
    s = (s or "").strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "`\"'":
        s = s[1:-1]
    return s


def _bare_col_name(col: exp.Column) -> str:
    return _strip_ident(col.name)


def _is_count_star(node: exp.Expression) -> bool:
    c = node.find(exp.Count)
    if c is None:
        return False
    # COUNT(*) / COUNT(1)
    inner = c.this
    if inner is None or isinstance(inner, exp.Star):
        return True
    if isinstance(inner, exp.Literal) and str(inner.this) in {"1", "*"}:
        return True
    return False


def _primary_column(node: exp.Expression) -> str | None:
    """Best-effort bare column inside an expression."""
    cols = list(node.find_all(exp.Column))
    if not cols:
        return None
    # Prefer column inside aggregate
    for agg_t in (exp.Count, exp.Avg, exp.Sum, exp.Max, exp.Min):
        agg = node.find(agg_t)
        if agg is not None:
            inner_cols = list(agg.find_all(exp.Column))
            if inner_cols:
                return _bare_col_name(inner_cols[0])
    if len(cols) == 1:
        return _bare_col_name(cols[0])
    # multiple cols (e.g. a||b): keep first
    return _bare_col_name(cols[0])


def _alias_usable(alias: str) -> bool:
    a = _strip_ident(alias)
    if not a:
        return False
    # reject aliases that are just expressions
    if re.search(r"[\(\)\+\-\*/]", a):
        return False
    if re.match(r"(?i)^(count|sum|avg|max|min)\b", a):
        return False
    return True


def _unwrap(node: exp.Expression) -> exp.Expression:
    while isinstance(node, (exp.Cast, exp.Paren)):
        node = node.this
    return node


def _classify_kind(node: exp.Expression) -> str:
    """Kind for a SELECT item. Complex multi-agg formulas → col (computed)."""
    if isinstance(node, exp.Star):
        return "star"
    core = _unwrap(node)
    for agg_t, name in (
        (exp.Count, "count"),
        (exp.Avg, "avg"),
        (exp.Sum, "sum"),
        (exp.Max, "max"),
        (exp.Min, "min"),
    ):
        if isinstance(core, agg_t):
            return name
    found: list[str] = []
    for agg_t, name in (
        (exp.Count, "count"),
        (exp.Avg, "avg"),
        (exp.Sum, "sum"),
        (exp.Max, "max"),
        (exp.Min, "min"),
    ):
        if node.find(agg_t):
            found.append(name)
    # Single clean agg buried only under Cast/Paren already handled; anything else
    # with aggs inside arithmetic (ratio / percent) is a computed column.
    if found:
        return "col"
    return "col"


def normalize_field_v2(
    node: exp.Expression, alias: str, kind: str, expr_sql: str
) -> dict[str, str]:
    """Short, agent-friendly field label + kind."""
    alias = _strip_ident(alias)

    if kind == "star":
        return {"name": "*", "kind": "star", "expr": expr_sql}

    if kind in AGG_KINDS:
        if kind == "count" and _is_count_star(node):
            name = alias if _alias_usable(alias) else "*"
            return {"name": name, "kind": "count", "expr": expr_sql}
        col = _primary_column(node)
        if alias and _alias_usable(alias):
            # Prefer human alias when present (e.g. AS total)
            # but if alias equals a real column keep it; still OK
            name = alias
        elif col:
            name = col
        else:
            name = kind  # last resort: "count"/"avg"/…
        return {"name": name, "kind": kind, "expr": expr_sql}

    # non-agg
    if alias and _alias_usable(alias):
        return {"name": alias, "kind": "col", "expr": expr_sql}
    if isinstance(node, exp.Column):
        return {"name": _bare_col_name(node), "kind": "col", "expr": expr_sql}
    col = _primary_column(node)
    if col:
        return {"name": col, "kind": "col", "expr": expr_sql}
    # complex expression without alias — compress whitespace, drop table qualifiers
    compact = re.sub(r"\b\w+\.", "", expr_sql)
    compact = re.sub(r"\s+", " ", compact).strip()
    if len(compact) > 48:
        compact = compact[:45] + "..."
    return {"name": compact or "expr", "kind": "col", "expr": expr_sql}


def normalize_field_v1(
    node: exp.Expression, alias: str, kind: str, expr_sql: str
) -> dict[str, str]:
    """Legacy naming (may keep full expr)."""
    if alias:
        out_name = _strip_ident(alias)
    elif isinstance(node, exp.Column):
        out_name = _bare_col_name(node)
    else:
        out_name = expr_sql
    return {"name": out_name, "kind": kind, "expr": expr_sql}


def parse_projection(sql: str, label_version: str = "v2") -> dict[str, Any] | None:
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

    norm = normalize_field_v2 if label_version == "v2" else normalize_field_v1

    fields: list[dict[str, str]] = []
    for e in sel.expressions:
        node = e.this if isinstance(e, exp.Alias) else e
        kind = _classify_kind(node)
        expr_sql = re.sub(r"\s+", " ", node.sql(dialect="sqlite")).strip()
        alias = e.alias if isinstance(e, exp.Alias) else ""
        f = norm(node, alias or "", kind, expr_sql)
        # Complex computed metrics (e.g. SUM(CASE)/COUNT(*)) → short generic name
        if (
            label_version == "v2"
            and kind == "col"
            and not (alias and _alias_usable(alias))
            and any(node.find(t) for t in (exp.Count, exp.Avg, exp.Sum, exp.Max, exp.Min))
        ):
            f["name"] = "value"
        fields.append(f)

    has_group = sel.args.get("group") is not None
    # Shape uses presence of aggregates in SELECT, even if field kind is computed "col"
    has_agg = any(
        e.find(t) is not None
        for e in sel.expressions
        for t in (exp.Count, exp.Avg, exp.Sum, exp.Max, exp.Min)
    ) or any(f["kind"] in AGG_KINDS for f in fields)
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


def tables_from_sql(sql: str) -> list[str]:
    try:
        tree = sqlglot.parse_one(sql, read="sqlite")
    except Exception:
        return []
    names: list[str] = []
    seen: set[str] = set()
    for t in tree.find_all(exp.Table):
        n = _strip_ident(t.name)
        if not n:
            continue
        key = n.lower()
        if key in seen:
            continue
        seen.add(key)
        names.append(n)
    return names


def fk_neighbor_tables(meta: dict[str, Any], seed: list[str]) -> list[str]:
    """One-hop FK expansion using BIRD column-index foreign_keys."""
    table_names = meta.get("table_names_original") or meta.get("table_names") or []
    cols = meta.get("column_names_original") or meta.get("column_names") or []
    seed_l = {s.lower() for s in seed}
    out = list(seed)
    seen = set(seed_l)
    for pair in meta.get("foreign_keys") or []:
        if not isinstance(pair, (list, tuple)) or len(pair) < 2:
            continue
        a, b = int(pair[0]), int(pair[1])
        if a < 0 or b < 0 or a >= len(cols) or b >= len(cols):
            continue
        ta, _ = cols[a][0], cols[a][1]
        tb, _ = cols[b][0], cols[b][1]
        if ta < 0 or tb < 0 or ta >= len(table_names) or tb >= len(table_names):
            continue
        na, nb = table_names[ta], table_names[tb]
        if na.lower() in seed_l and nb.lower() not in seen:
            seen.add(nb.lower())
            out.append(nb)
        if nb.lower() in seed_l and na.lower() not in seen:
            seen.add(na.lower())
            out.append(na)
    return out


def schema_text(
    db_id: str,
    tables_by_db: dict[str, Any],
    keep_tables: list[str] | None = None,
    max_cols: int = 120,
) -> str:
    meta = tables_by_db.get(db_id)
    if not meta:
        return f"Database: {db_id}\n(schema unavailable)"
    table_names = meta.get("table_names_original") or meta.get("table_names") or []
    cols = meta.get("column_names_original") or meta.get("column_names") or []
    keep_l = {t.lower() for t in keep_tables} if keep_tables else None

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
    emitted = 0
    for ti, tname in enumerate(table_names):
        if keep_l is not None and tname.lower() not in keep_l:
            continue
        cl = by_table.get(ti, [])
        chunk = ", ".join(cl[:40])
        if len(cl) > 40:
            chunk += ", ..."
        lines.append(f"- {tname}({chunk})")
        emitted += 1
        n += len(cl)
        if n >= max_cols:
            lines.append("- ...")
            break
    if keep_l is not None and emitted == 0:
        # fallback full schema if gold table parse missed
        return schema_text(db_id, tables_by_db, keep_tables=None, max_cols=max_cols)
    return "\n".join(lines)


def target_obj(proj: dict[str, Any]) -> dict[str, Any]:
    return {
        "shape": proj["shape"],
        "fields": [{"name": f["name"], "kind": f["kind"]} for f in proj["fields"]],
    }


def target_text(obj: dict[str, Any]) -> str:
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def build_user_prompt(question: str, evidence: str, schema: str, label_version: str) -> str:
    if label_version == "v2":
        rules = (
            "Rules:\n"
            "- Follow gold taste: if gold returns a row list instead of COUNT, use shape=list.\n"
            "- field.name is a SHORT label: SQL alias if present, else bare column name "
            "(NO table prefix like T1./movies.).\n"
            "- For aggregates: kind encodes the agg; name is the aggregated column "
            '(or "*" for COUNT(*)).\n'
            "- Do NOT put full SQL expressions into name (no COUNT(...), no AVG(...)).\n"
            "- Preserve field ORDER as in the gold SELECT list.\n"
        )
    else:
        rules = (
            "Rules:\n"
            "- Follow gold taste: if gold returns a row list instead of COUNT, use shape=list.\n"
            "- Preserve field ORDER; prefer aliases / result column names.\n"
            "- Do not invent columns not needed by the gold projection.\n"
        )
    return (
        "You predict the BIRD gold SQL output projection (not the full SQL).\n"
        "Return ONLY a JSON object with keys:\n"
        '  shape: one of "scalar" | "list" | "entity" | "table"\n'
        "  fields: ordered list of {name, kind} where kind in "
        "col|count|avg|sum|max|min|star\n"
        f"{rules}\n"
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
    label_version: str,
    schema_mode: str,
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
        proj = parse_projection(sql, label_version=label_version)
        if proj is None:
            stats["parse_fail"] += 1
            continue
        stats["ok"] += 1
        stats[f"shape_{proj['shape']}"] += 1
        stats[f"nfields_{len(proj['fields'])}"] += 1
        for f in proj["fields"]:
            stats[f"kind_{f['kind']}"] += 1
            if "(" in f["name"] or ")" in f["name"]:
                stats["name_has_parens"] += 1
            if re.search(r"\b\w+\.\w+", f["name"]):
                stats["name_has_table_qual"] += 1

        if nl_wants_count(question) and proj["shape"] == "list":
            stats["nl_count_but_gold_list"] += 1
        if nl_wants_count(question) and proj["shape"] == "scalar":
            stats["nl_count_and_gold_scalar"] += 1

        keep_tables: list[str] | None = None
        if schema_mode == "gold_fk":
            seed = tables_from_sql(sql)
            meta = tables_by_db.get(db_id) or {}
            keep_tables = fk_neighbor_tables(meta, seed) if seed else None
            if keep_tables:
                stats["schema_gold_fk"] += 1
            else:
                stats["schema_fallback_full"] += 1
        elif schema_mode == "gold":
            keep_tables = tables_from_sql(sql) or None
            if keep_tables:
                stats["schema_gold"] += 1
            else:
                stats["schema_fallback_full"] += 1
        else:
            stats["schema_full"] += 1

        tgt = target_obj(proj)
        schema = schema_text(db_id, tables_by_db, keep_tables=keep_tables)
        user = build_user_prompt(question, x.get("evidence", ""), schema, label_version)
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
                "schema_tables": keep_tables,
                "label_version": label_version,
                "difficulty": x.get("difficulty"),
            }
        )
        taiji.append(
            {
                "instruction": (
                    "Predict BIRD gold SQL output projection as JSON "
                    '(keys: shape, fields[{name,kind}]). '
                    f"label_version={label_version}."
                ),
                "input": user,
                "output": assistant,
                "meta": {
                    "id": f"{split}_{i}",
                    "db_id": db_id,
                    "split": split,
                    "label_version": label_version,
                    "schema_mode": schema_mode,
                },
            }
        )
    return rich, taiji, stats


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")


def probe_report(
    stats_map: dict[str, Counter],
    samples: list[dict[str, Any]],
    out: Path,
    label_version: str,
    schema_mode: str,
) -> None:
    lines: list[str] = []
    lines.append(f"# Projection-field wash probe ({label_version}, schema={schema_mode})\n")
    lines.append("## Counts\n")
    for name, st in stats_map.items():
        lines.append(f"### {name}\n")
        lines.append("```")
        for k, v in sorted(st.items(), key=lambda kv: (-kv[1], kv[0])):
            lines.append(f"{k}: {v}")
        lines.append("```\n")

    lines.append("## v2 label design\n")
    lines.append(
        "| shape | Meaning |\n"
        "|-------|--------|\n"
        "| scalar | Aggregates without GROUP BY |\n"
        "| list | Multi-row projection |\n"
        "| entity | Non-agg with LIMIT 1 |\n"
        "| table | Agg + GROUP BY |\n\n"
        "**field.name (v2):** short label — alias or bare column; "
        'aggregates use column name + kind (COUNT(*) → name `"*"`).\n'
        "**schema (v2 default):** gold SQL tables + one FK hop (not full DB).\n"
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
    ap.add_argument("--label-version", choices=("v1", "v2"), default="v2")
    ap.add_argument(
        "--schema-mode",
        choices=("full", "gold", "gold_fk"),
        default="gold_fk",
        help="full=whole DB; gold=tables in gold SQL; gold_fk=gold+1 FK hop (v2 default)",
    )
    ap.add_argument("--out-dir", default="")
    ap.add_argument("--train", default=str(ROOT / "benchmarks/bird/train/train.json"))
    ap.add_argument("--dev", default=str(ROOT / "benchmarks/bird/dev/dev.json"))
    ap.add_argument(
        "--tables",
        default=str(ROOT / "benchmarks/bird/train/train_tables.json"),
    )
    args = ap.parse_args()

    if not args.out_dir:
        args.out_dir = str(
            ROOT / ("data/proj_fields_v2" if args.label_version == "v2" else "data/proj_fields")
        )
    # v1 convenience: full schema unless overridden
    if args.label_version == "v1" and args.schema_mode == "gold_fk":
        # keep explicit; user can pass --schema-mode full for classic v1
        pass

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    tables_by_db = load_tables(Path(args.tables))
    for extra in (
        ROOT / "benchmarks/bird/dev/dev_tables.json",
        ROOT / "benchmarks/bird/heldout_v1_smoke/test_tables.json",
    ):
        if extra.exists():
            tables_by_db.update(load_tables(extra))

    exclude = heldout_keys(ROOT)
    print(
        f"label={args.label_version} schema_mode={args.schema_mode} "
        f"held-out exclude={len(exclude)} out={out_dir}"
    )

    train = json.loads(Path(args.train).read_text())
    rich_tr, taiji_tr, st_tr = wash_split(
        train, tables_by_db, exclude, "train", args.label_version, args.schema_mode
    )

    rich_dv: list[dict[str, Any]] = []
    taiji_dv: list[dict[str, Any]] = []
    st_dv: Counter = Counter()
    if Path(args.dev).exists():
        dev = json.loads(Path(args.dev).read_text())
        rich_dv, taiji_dv, st_dv = wash_split(
            dev, tables_by_db, set(), "dev", args.label_version, args.schema_mode
        )

    write_jsonl(out_dir / "train_rich.jsonl", rich_tr)
    write_jsonl(out_dir / "taiji_sft_train.jsonl", taiji_tr)
    if rich_dv:
        write_jsonl(out_dir / "dev_rich.jsonl", rich_dv)
        write_jsonl(out_dir / "taiji_sft_dev.jsonl", taiji_dv)
    write_jsonl(out_dir / "taiji_sft_train_preview100.jsonl", taiji_tr[:100])

    probe_report(
        {"train": st_tr, "dev": st_dv},
        rich_tr,
        out_dir / "probe_report.md",
        args.label_version,
        args.schema_mode,
    )

    (out_dir / "README.md").write_text(
        "\n".join(
            [
                f"# proj_fields SFT pack ({args.label_version})",
                "",
                f"- **label_version**: `{args.label_version}`",
                f"- **schema_mode**: `{args.schema_mode}`",
                "",
                "### v2 changes vs v1",
                "- `fields[].name`: short labels (alias / bare column / `*` for COUNT(*)); "
                "**no** `COUNT(T2.x)` expressions",
                "- `kind` carries agg type (`count|avg|sum|max|min|col|star`)",
                "- Input schema: gold SQL tables + one FK hop (less noise than full DB)",
                "- Held-out smoke/standard questions excluded from train",
                "",
                "Upload **`taiji_sft_train.jsonl`** for SFT; "
                "**`taiji_sft_train_preview100.jsonl`** for format smoke; "
                "**`taiji_sft_dev.jsonl`** for eval.",
                "",
                f"Train rows: {len(taiji_tr)}",
                f"Dev rows: {len(taiji_dv)}",
                "",
                "See `probe_report.md`.",
                "",
            ]
        ),
        encoding="utf-8",
    )

    # label card for trainers
    (out_dir / "LABEL_V2.md").write_text(
        "\n".join(
            [
                "# ProjAligner label v2",
                "",
                "## Target JSON",
                "```json",
                '{"shape":"scalar","fields":[{"name":"user_id","kind":"count"}]}',
                "```",
                "",
                "## name rules",
                "1. Prefer SELECT alias if human-readable",
                "2. Else bare column name (strip `T1.` / `table.`)",
                "3. Aggregates: name=column (or `*` for COUNT(*)), kind=agg",
                "4. Never put `COUNT(...)` / `AVG(...)` into name",
                "",
                "## shape rules (unchanged, from gold SQL)",
                "- scalar: agg without GROUP BY",
                "- table: agg with GROUP BY",
                "- entity: no agg + LIMIT 1",
                "- list: otherwise",
                "",
                "## Train tips",
                "- max_seq_length ≥ 1024 recommended (schema still shorter than v1 full DB)",
                "- LoRA: consider attn+mlp, r=16~32, epochs 2~3",
                "- Eval metric: fields order exact + shape; EX cares about fields more than entity/list",
                "",
            ]
        ),
        encoding="utf-8",
    )

    print(f"train ok={st_tr['ok']} excluded={st_tr['excluded_heldout']} fail={st_tr['parse_fail']}")
    print(f"  name_has_parens={st_tr['name_has_parens']} name_has_table_qual={st_tr['name_has_table_qual']}")
    print(f"  schema_gold_fk={st_tr['schema_gold_fk']} fallback_full={st_tr['schema_fallback_full']}")
    print(f"dev ok={st_dv['ok']} name_has_parens={st_dv['name_has_parens']}")
    print(f"wrote {out_dir}")


if __name__ == "__main__":
    main()

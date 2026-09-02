#!/usr/bin/env python3.12
"""Wash BIRD gold SQL into schema-free result-intent labels.

The gold SQL is available only to this offline labeler. The output intentionally
contains no physical table/column names or SQL expressions, so it can later be
injected as an oracle intent without leaking the gold projection.

Example:
  python3.12 scripts/wash_result_intents.py \
    --questions data/dev_strat300/slice.json \
    --gold data/dev_strat300/gold.json \
    --output-dir results/intent_wash/strat300

  python3.12 scripts/wash_result_intents.py \
    --mode predicted \
    --questions data/dev_strat300/slice.json \
    --context-dir contexts/sqlite/bird \
    --output-dir results/intent_wash/strat300_predicted
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import random
import re
import threading
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SYSTEM_PROMPT = """You create oracle result-intent labels for BIRD text-to-SQL.

You are given a user question, optional evidence, and a projection-only summary
parsed from its gold SQL. Use the gold summary only to determine the benchmark's
output taste: exactly what semantic values are returned, their order, whether
the result is one value/row or a list, and any
highest/lowest/top-k/grouped/count/aggregate behavior.

Write the intent at the semantic level. It will be given to another model that
must bind it to a schema itself.

Hard rules:
1. Return exactly one JSON object: {"result_intent":"..."}.
2. Never include physical table names, column names, aliases, SQL snippets, or
   formulas from the gold SQL.
3. Name outputs using natural concepts from the question/evidence.
4. Preserve the gold projection's output count and order, even when the gold
   taste differs from a literal reading of the question.
5. Describe result shape/ranking only when relevant. Remove all population and
   scope constraints used only for filtering: locations, dates, statuses,
   thresholds, entity literals, and WHERE conditions. The original question
   remains available to the downstream model.
6. Be concise: normally one sentence, at most 60 words.
7. "Output values" always means output columns, never rows. For top-k with one
   projected value, say "Return k rows with one output per row", not "Return k
   output values".
8. Before answering, internally separate output semantics from source-row
   filters. Keep aggregation/ranking/grouping and metric definitions; remove
   conditions that merely select the input population.
9. The gold ORDER BY expression tells you the ranking criterion. Never invent
   tie-breaking behavior or a secondary ordering that is not explicitly present
   in the question or gold order expression.

Examples:
- Return exactly one value: the highest eligible free meal rate for K-12 students.
- Return two output values per row, in order: school name; funding type.
- Return one row per country with two outputs, in order: country; number of singers.

Filter-removal example:
- Question: "What is the highest eligible free rate for K-12 students in Alameda County?"
- Correct intent: "Return exactly one value: the highest eligible free meal rate for K-12 students."
- Wrong intent: "... in Alameda County" (Alameda is only a filter).
"""

PREDICTED_SYSTEM_PROMPT = """You infer result intent for BIRD text-to-SQL without
seeing gold SQL. You are given the user question, optional evidence, and compact
database schema semantics. Infer exactly what the result should return, while
leaving physical schema binding to the downstream SQL generator.

Hard rules:
1. Return exactly one JSON object: {"result_intent":"..."}.
2. Never include physical table names, column names, aliases, SQL snippets, or
   formulas. Express outputs as natural concepts from the question/evidence.
3. Describe only output semantics: output count/order, row shape, aggregation,
   grouping, distinctness, and ranking/top-k behavior when relevant.
4. Do not repeat population constraints used only for filtering, such as dates,
   locations, statuses, thresholds, and entity literals. The downstream model
   already receives the original question.
5. Distinguish requested outputs from ranking/filter/grouping keys. Do not add a
   metric merely because it is used to rank the requested entity.
6. "Output values" means output columns, never rows. For top-k with one output
   column, say "Return k rows with one output per row".
7. Never invent tie-breaking or secondary ordering.
8. Be concise: normally one sentence, at most 60 words.

Examples:
- Return exactly one value: the highest eligible free meal rate for K-12 students.
- Return two outputs per row, in order: school name; funding type.
- Return one row per country with two outputs, in order: country; number of singers.
"""

SQL_LEAK_RE = re.compile(
    r"(?i)(?:"
    r"\b(?:count|sum|avg|min|max|cast|case)\s*\(|"
    r"\bT\d+\s*\.\s*[A-Za-z_]|"
    r"\bselect\b.+\bfrom\b|"
    r"`)"
)


@dataclass(frozen=True)
class ModelConfig:
    model_name: str
    token: str
    base_url: str


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--mode",
        choices=("oracle", "predicted"),
        default="oracle",
        help="oracle uses gold projection; predicted sees no gold SQL",
    )
    p.add_argument("--questions", required=True, help="Question JSON array")
    p.add_argument(
        "--gold",
        default="",
        help="Optional gold JSON array. If omitted, questions[].SQL is used.",
    )
    p.add_argument("--output-dir", required=True)
    p.add_argument(
        "--context-dir",
        default="",
        help="RC directory required by predicted mode",
    )
    p.add_argument("--config", default=str(ROOT / "llm_config.json"))
    p.add_argument("--model-config", default="deepseek_v4_flash")
    p.add_argument("--workers", type=int, default=4)
    p.add_argument("--limit", type=int, default=0, help="0 = all")
    p.add_argument("--start", type=int, default=0)
    p.add_argument("--max-retries", type=int, default=6)
    p.add_argument("--max-tokens", type=int, default=4096)
    return p.parse_args()


def load_json_array(path: Path) -> list[dict[str, Any]]:
    obj = json.loads(path.read_text())
    if not isinstance(obj, list):
        raise ValueError(f"{path}: expected a JSON array")
    return obj


def load_model_config(path: Path, key: str) -> ModelConfig:
    data = json.loads(path.read_text())
    raw = data.get(key)
    if not isinstance(raw, dict):
        raise ValueError(f"{path}: missing model config {key!r}")
    missing = [k for k in ("model_name", "token", "base_url") if not raw.get(k)]
    if missing:
        raise ValueError(f"{path}: {key} missing {', '.join(missing)}")
    return ModelConfig(raw["model_name"], raw["token"], raw["base_url"])


def record_key(item: dict[str, Any], index: int) -> str:
    return f"{item.get('db_id', '')}:{item.get('question_id', index)}"


def attach_gold(
    questions: list[dict[str, Any]], gold: list[dict[str, Any]] | None
) -> list[dict[str, Any]]:
    if gold is None:
        out = []
        for i, q in enumerate(questions):
            sql = (q.get("SQL") or "").strip()
            if not sql:
                raise ValueError(f"question index {i} has no SQL; pass --gold")
            out.append({**q, "_gold_sql": sql})
        return out

    by_key = {record_key(g, i): g for i, g in enumerate(gold)}
    out = []
    for i, q in enumerate(questions):
        key = record_key(q, i)
        g = by_key.get(key)
        if g is None and i < len(gold):
            candidate = gold[i]
            if candidate.get("db_id") == q.get("db_id"):
                g = candidate
        sql = ((g or {}).get("SQL") or "").strip()
        if not sql:
            raise ValueError(f"no gold SQL for {key}")
        out.append({**q, "_gold_sql": sql})
    return out


def gold_projection_summary(sql: str) -> str:
    """Extract outer SELECT projection and non-expression result modifiers.

    This intentionally omits FROM/JOIN/WHERE so the labeler cannot echo filters
    into result_intent. It is a small scanner rather than a SQL rewriter: BIRD
    identifiers may contain spaces/backticks, and nested subqueries must not
    terminate the outer projection.
    """

    lower = sql.lower()
    depth = 0
    quote = ""
    select_end = -1
    from_start = -1
    i = 0
    while i < len(sql):
        ch = sql[i]
        if quote:
            if ch == quote:
                if i + 1 < len(sql) and sql[i + 1] == quote and quote in ("'", '"'):
                    i += 2
                    continue
                quote = ""
            i += 1
            continue
        if ch in ("'", '"', "`"):
            quote = ch
            i += 1
            continue
        if ch == "[":
            quote = "]"
            i += 1
            continue
        if ch == "(":
            depth += 1
            i += 1
            continue
        if ch == ")":
            depth = max(0, depth - 1)
            i += 1
            continue
        if depth == 0:
            if select_end < 0 and lower.startswith("select", i):
                before = lower[i - 1] if i else " "
                after = lower[i + 6] if i + 6 < len(sql) else " "
                if not (before.isalnum() or before == "_") and not (
                    after.isalnum() or after == "_"
                ):
                    select_end = i + 6
                    i = select_end
                    continue
            if select_end >= 0 and lower.startswith("from", i):
                before = lower[i - 1] if i else " "
                after = lower[i + 4] if i + 4 < len(sql) else " "
                if not (before.isalnum() or before == "_") and not (
                    after.isalnum() or after == "_"
                ):
                    from_start = i
                    break
        i += 1

    if select_end < 0:
        raise ValueError("gold SQL has no outer SELECT")
    projection = sql[select_end : from_start if from_start >= 0 else len(sql)].strip()
    if not projection:
        raise ValueError("gold SQL has an empty outer projection")

    def modifier(pattern: str, default: str = "no") -> str:
        match = re.search(pattern, sql, flags=re.I)
        return match.group(1) if match and match.lastindex else ("yes" if match else default)

    distinct = "yes" if re.match(r"(?is)^distinct\b", projection) else "no"
    projection = re.sub(r"(?is)^distinct\s+", "", projection).strip()
    grouped = modifier(r"\bgroup\s+by\b")
    order_by = top_level_clause(
        sql,
        r"order\s+by",
        [r"limit", r"offset", r"union", r"intersect", r"except"],
    )
    limit = modifier(r"\blimit\s+(\d+)\b", "none")
    return (
        f"Output column count: {projection_arity_from_text(projection)}\n"
        f"Output projection: {projection}\n"
        f"Result modifiers: distinct={distinct}; grouped={grouped}; "
        f"order_by={order_by or 'none'}; limit={limit}"
    )


def top_level_clause(sql: str, start_pattern: str, end_patterns: list[str]) -> str:
    """Return one outer SQL clause body, excluding its keyword."""

    start_re = re.compile(rf"(?i)\b(?:{start_pattern})\b")
    end_res = [re.compile(rf"(?i)\b(?:{p})\b") for p in end_patterns]
    depth = 0
    quote = ""
    clause_start = -1
    i = 0
    while i < len(sql):
        ch = sql[i]
        if quote:
            if ch == quote:
                if i + 1 < len(sql) and sql[i + 1] == quote and quote in ("'", '"'):
                    i += 2
                    continue
                quote = ""
            i += 1
            continue
        if ch in ("'", '"', "`"):
            quote = ch
            i += 1
            continue
        if ch == "[":
            quote = "]"
            i += 1
            continue
        if ch == "(":
            depth += 1
            i += 1
            continue
        if ch == ")":
            depth = max(0, depth - 1)
            i += 1
            continue
        if depth == 0:
            if clause_start < 0:
                match = start_re.match(sql, i)
                if match:
                    clause_start = match.end()
                    i = clause_start
                    continue
            else:
                for end_re in end_res:
                    match = end_re.match(sql, i)
                    if match:
                        return sql[clause_start:i].strip().rstrip(";")
        i += 1
    if clause_start < 0:
        return ""
    return sql[clause_start:].strip().rstrip(";")


def projection_arity_from_text(projection: str) -> int:
    depth = 0
    quote = ""
    count = 1
    i = 0
    while i < len(projection):
        ch = projection[i]
        if quote:
            if ch == quote:
                quote = ""
            i += 1
            continue
        if ch in ("'", '"', "`"):
            quote = ch
        elif ch == "[":
            quote = "]"
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth = max(0, depth - 1)
        elif ch == "," and depth == 0:
            count += 1
        i += 1
    return count


def gold_projection_arity(sql: str) -> int:
    for line in gold_projection_summary(sql).splitlines():
        if line.startswith("Output column count: "):
            return int(line.removeprefix("Output column count: "))
    raise ValueError("projection summary has no output column count")


def build_user_prompt(item: dict[str, Any]) -> str:
    return "\n".join(
        [
            f"Question: {(item.get('question') or '').strip()}",
            f"Evidence: {(item.get('evidence') or '').strip() or '(none)'}",
            gold_projection_summary(item["_gold_sql"]),
        ]
    )


def compact_context(context_dir: Path, db_id: str) -> str:
    path = context_dir / f"{db_id}.json"
    raw = json.loads(path.read_text())
    diagram = ((raw.get("schema_diagram") or {}).get("content") or "").strip()
    table_semantics = []
    for table_name, table in (raw.get("tables") or {}).items():
        description = (table.get("description") or "").strip()
        if description:
            table_semantics.append(f"- {table_name}: {description}")
    parts = ["Available schema (for semantic disambiguation only):", diagram]
    if table_semantics:
        parts.extend(["Table semantics:", *table_semantics])
    return "\n".join(x for x in parts if x)


def build_predicted_user_prompt(
    item: dict[str, Any], context_dir: Path
) -> str:
    return "\n".join(
        [
            f"Question: {(item.get('question') or '').strip()}",
            f"Evidence: {(item.get('evidence') or '').strip() or '(none)'}",
            compact_context(context_dir, item.get("db_id") or ""),
        ]
    )


def extract_json_object(text: str) -> dict[str, Any]:
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.I)
        text = re.sub(r"\s*```$", "", text)
    start = text.find("{")
    if start < 0:
        raise ValueError("response contains no JSON object")
    obj, _ = json.JSONDecoder().raw_decode(text[start:])
    if not isinstance(obj, dict):
        raise ValueError("response JSON is not an object")
    return obj


def validate_result(obj: dict[str, Any], expected_arity: int | None = None) -> str:
    if set(obj) != {"result_intent"}:
        raise ValueError("response must contain only result_intent")
    intent = obj["result_intent"]
    if not isinstance(intent, str) or not intent.strip():
        raise ValueError("result_intent must be a non-empty string")
    intent = " ".join(intent.split())
    if len(intent) > 600:
        raise ValueError("result_intent is too long")
    if SQL_LEAK_RE.search(intent):
        raise ValueError("result_intent appears to contain physical SQL")
    if expected_arity is not None:
        number_words = {
            "one": 1,
            "two": 2,
            "three": 3,
            "four": 4,
            "five": 5,
            "six": 6,
            "seven": 7,
            "eight": 8,
            "nine": 9,
            "ten": 10,
        }
        match = re.search(
            r"(?i)\b(?:return\s+(?:exactly\s+)?)"
            r"(one|two|three|four|five|six|seven|eight|nine|ten|\d+)"
            r"\s+output values?\b",
            intent,
        )
        if match:
            token = match.group(1).lower()
            stated = int(token) if token.isdigit() else number_words[token]
            if stated != expected_arity:
                raise ValueError(
                    f"intent says {stated} output columns; gold projection has "
                    f"{expected_arity} (do not confuse rows with columns)"
                )
    return intent


def request_label(
    cfg: ModelConfig,
    system_prompt: str,
    user_prompt: str,
    *,
    expected_arity: int | None,
    max_retries: int,
    max_tokens: int,
) -> tuple[str, dict[str, Any]]:
    endpoint = cfg.base_url.rstrip("/") + "/chat/completions"
    last_error: Exception | None = None
    correction = ""
    for attempt in range(max_retries):
        prompt = user_prompt
        if correction:
            prompt += (
                "\n\nYour previous response was invalid: "
                + correction
                + "\nRetry and obey every hard rule."
            )
        payload = {
            "model": cfg.model_name,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt},
            ],
            "thinking": {"type": "enabled"},
            "temperature": 0,
            "max_tokens": max_tokens,
        }
        req = urllib.request.Request(
            endpoint,
            data=json.dumps(payload, ensure_ascii=False).encode(),
            headers={
                "Authorization": f"Bearer {cfg.token}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                raw = json.loads(resp.read())
            message = raw["choices"][0]["message"]
            content = message.get("content") or ""
            intent = validate_result(
                extract_json_object(content),
                expected_arity=expected_arity,
            )
            audit = {
                "response_content": content,
                "reasoning_content": message.get("reasoning_content") or "",
                "usage": raw.get("usage") or {},
                "model": raw.get("model") or cfg.model_name,
            }
            return intent, audit
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as exc:
            last_error = exc
            if isinstance(exc, urllib.error.HTTPError):
                try:
                    detail = exc.read().decode(errors="replace")[:1000]
                except Exception:
                    detail = ""
                last_error = RuntimeError(f"HTTP {exc.code}: {detail}")
                if exc.code not in (408, 409, 429) and exc.code < 500:
                    raise last_error
            delay = min(60.0, 2**attempt) + random.random()
            time.sleep(delay)
        except (KeyError, json.JSONDecodeError, ValueError) as exc:
            last_error = exc
            correction = str(exc)
            time.sleep(min(5.0, attempt + 1))
    raise RuntimeError(f"labeling failed after {max_retries} attempts: {last_error}")


def load_checkpoint(path: Path) -> dict[str, dict[str, Any]]:
    done: dict[str, dict[str, Any]] = {}
    if not path.exists():
        return done
    for line_no, line in enumerate(path.read_text().splitlines(), 1):
        if not line.strip():
            continue
        row = json.loads(line)
        if not row.get("key"):
            raise ValueError(f"{path}:{line_no}: checkpoint row has no key")
        done[row["key"]] = row
    return done


def write_final_outputs(
    output_dir: Path,
    selected: list[tuple[int, dict[str, Any]]],
    done: dict[str, dict[str, Any]],
) -> None:
    intents = []
    merged = []
    for index, item in selected:
        key = record_key(item, index)
        row = done.get(key)
        if row is None:
            continue
        intent_row = {
            "question_id": item.get("question_id", index),
            "db_id": item.get("db_id", ""),
            "result_intent": row["result_intent"],
        }
        if "_src_idx" in item:
            intent_row["_src_idx"] = item["_src_idx"]
        intents.append(intent_row)
        clean_item = {k: v for k, v in item.items() if k != "_gold_sql"}
        clean_item["result_intent"] = row["result_intent"]
        merged.append(clean_item)

    (output_dir / "intents.json").write_text(
        json.dumps(intents, ensure_ascii=False, indent=2) + "\n"
    )
    (output_dir / "dataset_with_intent.json").write_text(
        json.dumps(merged, ensure_ascii=False, indent=2) + "\n"
    )


def main() -> None:
    args = parse_args()
    if args.workers < 1:
        raise SystemExit("--workers must be >= 1")
    questions_path = Path(args.questions)
    gold_path = Path(args.gold) if args.gold else None
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    questions = load_json_array(questions_path)
    gold = load_json_array(gold_path) if gold_path else None
    if args.mode == "oracle":
        items = attach_gold(questions, gold)
        context_dir = None
    else:
        if gold is not None:
            raise SystemExit("--gold is forbidden in predicted mode")
        if not args.context_dir:
            raise SystemExit("--context-dir is required in predicted mode")
        items = questions
        context_dir = Path(args.context_dir)
    end = len(items) if args.limit <= 0 else min(len(items), args.start + args.limit)
    selected = list(enumerate(items))[args.start:end]
    cfg = load_model_config(Path(args.config), args.model_config)

    checkpoint_path = output_dir / "checkpoint.jsonl"
    raw_path = output_dir / "raw_responses.jsonl"
    failures_path = output_dir / "failures.jsonl"
    done = load_checkpoint(checkpoint_path)
    pending = [
        (index, item)
        for index, item in selected
        if record_key(item, index) not in done
    ]
    print(
        f"mode={args.mode} questions={questions_path} "
        f"gold={gold_path or ('none' if args.mode == 'predicted' else 'embedded')} "
        f"selected={len(selected)} resumed={len(selected) - len(pending)} "
        f"pending={len(pending)} model={cfg.model_name} thinking=enabled"
    )

    lock = threading.Lock()

    def run_one(index: int, item: dict[str, Any]) -> tuple[str, dict[str, Any], dict[str, Any]]:
        key = record_key(item, index)
        if args.mode == "oracle":
            system_prompt = SYSTEM_PROMPT
            user_prompt = build_user_prompt(item)
            expected_arity = gold_projection_arity(item["_gold_sql"])
        else:
            system_prompt = PREDICTED_SYSTEM_PROMPT
            user_prompt = build_predicted_user_prompt(item, context_dir)
            expected_arity = None
        intent, audit = request_label(
            cfg,
            system_prompt,
            user_prompt,
            expected_arity=expected_arity,
            max_retries=args.max_retries,
            max_tokens=args.max_tokens,
        )
        row = {
            "key": key,
            "index": index,
            "question_id": item.get("question_id", index),
            "db_id": item.get("db_id", ""),
            "result_intent": intent,
        }
        raw = {**row, **audit}
        return key, row, raw

    completed = 0
    failures = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            pool.submit(run_one, index, item): (index, item)
            for index, item in pending
        }
        for future in concurrent.futures.as_completed(futures):
            index, item = futures[future]
            key = record_key(item, index)
            try:
                key, row, raw = future.result()
            except Exception as exc:
                failure = {
                    "key": key,
                    "index": index,
                    "question_id": item.get("question_id", index),
                    "db_id": item.get("db_id", ""),
                    "error": str(exc),
                }
                with lock:
                    with failures_path.open("a") as f:
                        f.write(json.dumps(failure, ensure_ascii=False) + "\n")
                    failures += 1
                    print(f"FAILED {key}: {exc}", flush=True)
                continue
            with lock:
                with checkpoint_path.open("a") as f:
                    f.write(json.dumps(row, ensure_ascii=False) + "\n")
                with raw_path.open("a") as f:
                    f.write(json.dumps(raw, ensure_ascii=False) + "\n")
                done[key] = row
                completed += 1
                print(
                    f"[{len(done)}/{len(selected)}] {key}: {row['result_intent']}",
                    flush=True,
                )

    write_final_outputs(output_dir, selected, done)
    manifest = {
        "mode": args.mode,
        "questions": str(questions_path),
        "gold": str(gold_path) if gold_path else (
            "none" if args.mode == "predicted" else "embedded"
        ),
        "context_dir": str(context_dir) if context_dir else "",
        "model_config": args.model_config,
        "model_name": cfg.model_name,
        "thinking": "enabled",
        "selected": len(selected),
        "completed_this_run": completed,
        "failures_this_run": failures,
        "finished": len([1 for i, x in selected if record_key(x, i) in done]),
    }
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    )
    print(f"DONE output={output_dir} rows={manifest['finished']}")


if __name__ == "__main__":
    main()

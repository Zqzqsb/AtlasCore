#!/usr/bin/env python3
"""Compare a new official-Dev run against open_results/20260324 (local EX buckets)."""
from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OLD_DIR = ROOT / "open_results" / "20260324_151835_react+rich_context+clarify"
DEV = json.loads((ROOT / "benchmarks" / "bird" / "dev" / "dev.json").read_text())
SKIP_PARTS = {
    "analysis_reports",
    "contexts",
    "bird_official_ex",
    "logs",
    "ambiguous_queries",
}


def load_bucket_correct(base: Path) -> dict[int, bool]:
    out: dict[int, bool] = {}
    for p in base.rglob("*.json"):
        if any(part in SKIP_PARTS for part in p.parts):
            continue
        try:
            d = json.loads(p.read_text())
        except Exception:
            continue
        if not isinstance(d, dict) or "id" not in d:
            continue
        if "is_correct" in d:
            out[int(d["id"])] = bool(d["is_correct"])
    return out


def load_results_json(path: Path) -> dict[int, bool]:
    raw = json.loads(path.read_text())
    items = raw if isinstance(raw, list) else raw.get("results") or raw.get("items") or []
    out: dict[int, bool] = {}
    for i, d in enumerate(items):
        if not isinstance(d, dict):
            continue
        qid = d.get("id", d.get("question_id", i))
        if "is_correct" in d:
            out[int(qid)] = bool(d["is_correct"])
        elif "correct" in d:
            out[int(qid)] = bool(d["correct"])
    return out


def acc(d: dict[int, bool]) -> tuple[int, int, float]:
    n = len(d)
    c = sum(1 for v in d.values() if v)
    return c, n, (100.0 * c / n if n else 0.0)


def main() -> int:
    new_dir = Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / "results" / "bird" / "dev_official_flash_think")
    out_path = Path(sys.argv[2]) if len(sys.argv) > 2 else new_dir / "vs_open_results.txt"

    old = load_bucket_correct(OLD_DIR)
    new = load_bucket_correct(new_dir)
    if len(new) < 1000:
        rj = new_dir / "results.json"
        if rj.exists():
            new = load_results_json(rj)

    lines: list[str] = []
    oc, on, op = acc(old)
    nc, nn, np_ = acc(new)
    lines.append(f"old={OLD_DIR.name} local_ex={oc}/{on} {op:.2f}%")
    lines.append(f"new={new_dir} local_ex={nc}/{nn} {np_:.2f}%")
    lines.append(f"delta_pp={np_ - op:+.2f}")
    lines.append("")

    meta = {int(x["question_id"]): x for x in DEV}
    shared = sorted(set(old) & set(new))
    help_ids = [i for i in shared if new[i] and not old[i]]
    hurt_ids = [i for i in shared if old[i] and not new[i]]
    both_ok = [i for i in shared if old[i] and new[i]]
    both_bad = [i for i in shared if not old[i] and not new[i]]
    lines.append(f"shared={len(shared)} both_ok={len(both_ok)} both_bad={len(both_bad)} help={len(help_ids)} hurt={len(hurt_ids)}")
    lines.append("")

    def group(ids: list[int], key: str) -> str:
        c = Counter(meta[i].get(key, "?") for i in ids if i in meta)
        return ", ".join(f"{k}:{v}" for k, v in c.most_common())

    lines.append(f"help_by_db {group(help_ids, 'db_id')}")
    lines.append(f"hurt_by_db {group(hurt_ids, 'db_id')}")
    lines.append(f"help_by_diff {group(help_ids, 'difficulty')}")
    lines.append(f"hurt_by_diff {group(hurt_ids, 'difficulty')}")
    lines.append("")

    by_db = defaultdict(lambda: [0, 0, 0])  # old_ok, new_ok, n
    for i in shared:
        db = meta.get(i, {}).get("db_id", "?")
        by_db[db][2] += 1
        if old[i]:
            by_db[db][0] += 1
        if new[i]:
            by_db[db][1] += 1
    lines.append("per_db old_ex new_ex n delta")
    for db, (o, n, tot) in sorted(by_db.items(), key=lambda kv: (kv[1][1] / kv[1][2] if kv[1][2] else 0)):
        lines.append(f"  {db:28s} {100*o/tot:5.1f} {100*n/tot:5.1f} {tot:4d} {100*(n-o)/tot:+5.1f}")

    def dump(title: str, ids: list[int], limit: int = 40) -> None:
        lines.append("")
        lines.append(f"{title} n={len(ids)} (first {min(limit, len(ids))})")
        for i in ids[:limit]:
            m = meta.get(i, {})
            q = (m.get("question") or "")[:80]
            lines.append(f"  {i:4d} {m.get('db_id','?'):24s} {m.get('difficulty','?'):11s} {q}")

    dump("HELP", help_ids)
    dump("HURT", hurt_ids)

    text = "\n".join(lines) + "\n"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(text)
    print(text)
    print(f"wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

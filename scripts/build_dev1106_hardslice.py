#!/usr/bin/env python3
"""Build a small Dev-1106 slice: worst DBs + mixed fail/correct questions.

Reads the 1534-run fail taxonomy and official per-item scores, writes:
  slice.json, gold.json, ids.json, baseline_pro_think.sql
"""
from __future__ import print_function

import json
import os
import sys
from collections import defaultdict

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(ROOT, "data/dev_1106_hardslice/_src")
OUT = os.path.join(ROOT, "data/dev_1106_hardslice")

DBS = ("financial", "california_schools")
BUDGET = {
    ("financial", "能力"): 12,
    ("california_schools", "能力"): 12,
    ("financial", "信息"): 8,
    ("california_schools", "信息"): 5,
    ("financial", "correct"): 4,
    ("california_schools", "correct"): 4,
}

DIFF_RANK = {"challenging": 0, "moderate": 1, "simple": 2}


def load_json(path):
    with open(path) as f:
        return json.load(f)


def main():
    golds = load_json(os.path.join(SRC, "dev_20251106.json"))
    fails = load_json(os.path.join(SRC, "fails_pass2.json"))
    items = load_json(os.path.join(SRC, "per_item.json"))
    preds = []
    with open(os.path.join(SRC, "predict.sql")) as f:
        for line in f:
            if line.strip():
                preds.append(line.split("\t")[0])
    if not (len(golds) == len(items) == len(preds)):
        raise SystemExit("src length mismatch gold/items/pred")

    fail_by_idx = {f["idx"]: f for f in fails}
    buckets = defaultdict(list)
    for i, g in enumerate(golds):
        db = g.get("db_id")
        if db not in DBS:
            continue
        rec = fail_by_idx.get(i)
        if rec is None and items[i].get("correct"):
            buckets[(db, "correct")].append(i)
        elif rec is not None and rec.get("root") in ("能力", "信息"):
            buckets[(db, rec["root"])].append(i)

    def sort_key(i):
        rec = fail_by_idx.get(i)
        diff = (rec or {}).get("difficulty") or golds[i].get("difficulty") or "simple"
        # Prefer challenging fails; for correct, keep original order (easy first).
        if rec is None:
            return (DIFF_RANK.get(diff, 9), i)
        return (DIFF_RANK.get(diff, 9), i)

    picked = []
    meta = []
    for key, n in BUDGET.items():
        cands = sorted(buckets.get(key, []), key=sort_key)
        take = cands[:n]
        if len(take) < n:
            print("warn: %s want %d got %d" % (key, n, len(take)), file=sys.stderr)
        for i in take:
            rec = fail_by_idx.get(i)
            picked.append(i)
            meta.append(
                {
                    "idx": i,
                    "question_id": golds[i].get("question_id", i),
                    "db_id": golds[i]["db_id"],
                    "difficulty": golds[i].get("difficulty"),
                    "bucket": key[1],
                    "root": None if rec is None else rec.get("root"),
                    "why": None if rec is None else rec.get("why"),
                    "baseline_official_ok": bool(items[i].get("correct")),
                }
            )

    slice_q = [golds[i] for i in picked]
    gold_out = [
        {
            "question_id": g.get("question_id", i),
            "db_id": g["db_id"],
            "SQL": g.get("SQL") or g.get("sql") or "",
            "difficulty": g.get("difficulty"),
        }
        for i, g in zip(picked, slice_q)
    ]
    baseline_sql = "\n".join(
        "%s\t%s" % (preds[i], golds[i]["db_id"]) for i in picked
    ) + "\n"

    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "slice.json"), "w") as f:
        json.dump(slice_q, f, ensure_ascii=False, indent=2)
    with open(os.path.join(OUT, "gold.json"), "w") as f:
        json.dump(gold_out, f, ensure_ascii=False, indent=2)
    with open(os.path.join(OUT, "ids.json"), "w") as f:
        json.dump({"n": len(picked), "budget": {str(k): v for k, v in BUDGET.items()}, "items": meta}, f, ensure_ascii=False, indent=2)
    with open(os.path.join(OUT, "baseline_pro_think.sql"), "w") as f:
        f.write(baseline_sql)
    print("wrote %d questions -> %s" % (len(picked), OUT))
    from collections import Counter
    print("db", Counter(g["db_id"] for g in slice_q))
    print("bucket", Counter(m["bucket"] for m in meta))
    print("baseline_ok", sum(m["baseline_official_ok"] for m in meta), "/", len(meta))


if __name__ == "__main__":
    main()

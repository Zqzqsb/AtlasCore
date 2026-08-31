#!/usr/bin/env python3
"""Stratified 300-question slice of official BIRD Dev.

Matches the 20260324 open_results mix of difficulty × outcome bucket, and
within each cell the per-database mix. Seed 42. Not a random 300: historical
EX on this slice is ~76% by construction (same mix as the full run).
"""
from __future__ import annotations

import json
import math
import random
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANA = ROOT / "open_results/20260324_151835_react+rich_context+clarify"
DEV_PATH = ROOT / "benchmarks/bird/dev/dev_with_fields.json"
OUT = ROOT / "data/dev_strat300"
N = 300
SEED = 42

DIR_BUCKET = {
    "correct_exact_match": "ok_exact",
    "correct_equivalent": "ok_equiv",
    "incorrect_row_count": "row_count",
    "incorrect_data_mismatch": "data_mismatch",
    "incorrect_execution": "other",
    "incorrect_projection": "other",
    "incorrect_reference": "other",
    "incorrect_timeout": "other",
    "incorrect_unknown": "other",
}
DIFFS = ("simple", "moderate", "challenging")
BKTS = ("ok_exact", "ok_equiv", "row_count", "data_mismatch", "other")


def largest_remainder(weights: dict[str, int], n: int) -> dict[str, int]:
    total = sum(weights.values())
    if total <= 0 or n <= 0:
        return {k: 0 for k in weights}
    raw = {k: weights[k] / total * n for k in weights}
    floors = {k: int(math.floor(raw[k])) for k in weights}
    leftover = n - sum(floors.values())
    order = sorted(
        weights,
        key=lambda k: (raw[k] - floors[k], weights[k], k),
        reverse=True,
    )
    for k in order[:leftover]:
        floors[k] += 1
    return floors


def load_rows():
    dev = json.loads(DEV_PATH.read_text())
    by_id = {}
    for dname, bkt in DIR_BUCKET.items():
        folder = ANA / dname
        if not folder.is_dir():
            continue
        for f in folder.glob("*.json"):
            obj = json.loads(f.read_text())
            i = int(obj["id"])  # 1-based Dev line
            idx = i - 1
            g = dev[idx]
            by_id[i] = {
                "id": i,
                "idx": idx,
                "question_id": g.get("question_id", idx),
                "db_id": g["db_id"],
                "difficulty": g.get("difficulty") or obj.get("difficulty"),
                "bucket": bkt,
                "ana_dir": dname,
                "gold": g,
            }
    if len(by_id) != 1534:
        raise SystemExit(f"expected 1534 analysis rows, got {len(by_id)}")
    return [by_id[i] for i in range(1, 1535)]


def sample_cell(rng: random.Random, items: list, k: int) -> list:
    if k <= 0:
        return []
    if k >= len(items):
        return list(items)
    by_db = defaultdict(list)
    for it in items:
        by_db[it["db_id"]].append(it)
    db_n = largest_remainder({db: len(v) for db, v in by_db.items()}, k)
    picked = []
    leftover_need = 0
    pool = []
    for db, take in db_n.items():
        cands = list(by_db[db])
        rng.shuffle(cands)
        if take <= len(cands):
            picked.extend(cands[:take])
            pool.extend(cands[take:])
        else:
            picked.extend(cands)
            leftover_need += take - len(cands)
    if leftover_need:
        rng.shuffle(pool)
        picked.extend(pool[:leftover_need])
    if len(picked) < k:
        rest = [it for it in items if it not in picked]
        rng.shuffle(rest)
        picked.extend(rest[: k - len(picked)])
    return picked[:k]


def pct(n, d):
    return 0.0 if d == 0 else 100.0 * n / d


def main():
    rng = random.Random(SEED)
    rows = load_rows()
    cells = defaultdict(list)
    for it in rows:
        cells[(it["difficulty"], it["bucket"])].append(it)

    weights = {f"{d}|{b}": len(cells[(d, b)]) for d in DIFFS for b in BKTS}
    target = largest_remainder(weights, N)

    picked = []
    for key, k in target.items():
        d, b = key.split("|", 1)
        got = sample_cell(rng, cells[(d, b)], k)
        if len(got) != k:
            raise SystemExit(f"cell {key} want {k} got {len(got)}")
        picked.extend(got)
    picked.sort(key=lambda it: it["id"])
    if len(picked) != N:
        raise SystemExit(f"want {N} got {len(picked)}")

    slice_with = []
    slice_no = []
    gold_out = []
    for it in picked:
        g = it["gold"]
        with_f = dict(g)
        no_f = {k: v for k, v in g.items() if k not in ("result_fields", "result_fields_description")}
        slice_with.append(with_f)
        slice_no.append(no_f)
        gold_out.append(
            {
                "question_id": g.get("question_id", it["idx"]),
                "db_id": g["db_id"],
                "SQL": g.get("SQL") or "",
                "difficulty": g.get("difficulty"),
            }
        )

    def dist(seq, key):
        return dict(Counter(key(x) for x in seq))

    full_diff = Counter(r["difficulty"] for r in rows)
    full_bkt = Counter(r["bucket"] for r in rows)
    full_db = Counter(r["db_id"] for r in rows)
    samp_diff = Counter(it["difficulty"] for it in picked)
    samp_bkt = Counter(it["bucket"] for it in picked)
    samp_db = Counter(it["db_id"] for it in picked)
    hist_ok = samp_bkt["ok_exact"] + samp_bkt["ok_equiv"]

    manifest = {
        "n": N,
        "seed": SEED,
        "source_run": "open_results/20260324_151835_react+rich_context+clarify",
        "historical_ok": hist_ok,
        "historical_ex": round(hist_ok / N, 4),
        "note": "Mix matches the 20260324 run. Re-running clarify on this slice should land near 76% if the original setup is reproduced. Do not read that as an unbiased estimate of a new method.",
        "target_cells": target,
        "full": {
            "difficulty": dict(full_diff),
            "bucket": dict(full_bkt),
            "db": dict(full_db),
        },
        "sample": {
            "difficulty": dict(samp_diff),
            "bucket": dict(samp_bkt),
            "db": dict(samp_db),
        },
        "items": [
            {
                "id": it["id"],
                "question_id": it["question_id"],
                "db_id": it["db_id"],
                "difficulty": it["difficulty"],
                "bucket": it["bucket"],
            }
            for it in picked
        ],
    }

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "slice.json").write_text(json.dumps(slice_no, ensure_ascii=False, indent=2) + "\n")
    (OUT / "slice_with_fields.json").write_text(json.dumps(slice_with, ensure_ascii=False, indent=2) + "\n")
    (OUT / "gold.json").write_text(json.dumps(gold_out, ensure_ascii=False, indent=2) + "\n")
    (OUT / "ids.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")

    print(f"wrote {N} -> {OUT}  historical EX {hist_ok}/{N} = {hist_ok/N:.1%}")
    print(f"{'':12} {'full':>8} {'sample':>8} {'full%':>7} {'samp%':>7}")
    for d in DIFFS:
        print(f"{d:12} {full_diff[d]:8d} {samp_diff[d]:8d} {pct(full_diff[d],1534):6.1f}% {pct(samp_diff[d],N):6.1f}%")
    for b in BKTS:
        print(f"{b:12} {full_bkt[b]:8d} {samp_bkt[b]:8d} {pct(full_bkt[b],1534):6.1f}% {pct(samp_bkt[b],N):6.1f}%")
    for db, n in full_db.most_common():
        print(f"{db:28} {n:8d} {samp_db[db]:8d} {pct(n,1534):6.1f}% {pct(samp_db[db],N):6.1f}%")


if __name__ == "__main__":
    main()

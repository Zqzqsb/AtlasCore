#!/usr/bin/env python3
"""Score main-probe cells against gold and the two full-Dev runs."""
import json
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_preds(path: Path):
    rows = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split("\t")
        rows.append((parts[0], parts[1] if len(parts) > 1 else ""))
    return rows


def exec_rows(db_path: Path, sql: str):
    if not sql.strip():
        return "empty"
    con = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True, timeout=30)
    con.execute("pragma busy_timeout=5000")
    try:
        cur = con.execute(sql)
        rows = cur.fetchall()
    except Exception as e:
        con.close()
        return f"ERR:{type(e).__name__}"
    con.close()
    # official-ish: set of tuples, stringify
    return frozenset(tuple("" if c is None else str(c) for c in r) for r in rows)


def eq(db_dir: Path, db_id: str, a: str, b: str) -> bool:
    p = db_dir / db_id / f"{db_id}.sqlite"
    ra, rb = exec_rows(p, a), exec_rows(p, b)
    if isinstance(ra, str) or isinstance(rb, str):
        return False
    return ra == rb


def bucket_correct(base: Path):
    skip = {
        "analysis_reports",
        "contexts",
        "bird_official_ex",
        "logs",
        "ambiguous_queries",
        "p0",
        "p1",
        "p2",
        "p3",
    }
    out = {}
    for p in base.rglob("*.json"):
        if any(x in p.parts for x in skip):
            continue
        try:
            d = json.loads(p.read_text())
        except Exception:
            continue
        if isinstance(d, dict) and "id" in d and "is_correct" in d:
            out[int(d["id"])] = bool(d["is_correct"])
    return out


def main():
    out = Path(sys.argv[1])
    slice_dir = Path(sys.argv[2])
    lb_dir = Path(sys.argv[3])
    open_dir = Path(sys.argv[4])
    ids = json.loads((slice_dir / "ids.json").read_text())
    gold = json.loads((slice_dir / "gold.json").read_text())
    db_dir = ROOT / "benchmarks" / "bird" / "dev" / "dev_databases"
    order = ids["fail"] + ids["control"]
    lb_pred = load_preds(lb_dir / "predict.sql")
    open_pred = load_preds(open_dir / "predict.sql")
    lb_ok = bucket_correct(lb_dir)
    open_ok = bucket_correct(open_dir)

    cells = {}
    for name in ("nocol", "clarify"):
        p = out / name / "predict.sql"
        cells[name] = load_preds(p) if p.exists() else []

    lines = []
    hdr = f"{'id':>5} {'db':<24} {'bkt':<7} open   lb  nocol clar  question"
    lines.append(hdr)
    n_ok = {k: 0 for k in ("open", "lb", "nocol", "clarify")}
    fail_n = len(ids["fail"])

    def yn(v):
        return "OK" if v else "NO"

    for j, iid in enumerate(order):
        g = gold[j]
        q = next(x["q"] for x in ids["items"] if x["id"] == iid)
        bkt = "fail" if iid in ids["fail"] else "ctrl"
        o = open_ok.get(iid)
        l = lb_ok.get(iid)
        # fallback to exec if bucket missing
        def cell_ok(name):
            preds = cells.get(name) or []
            if j >= len(preds):
                return False
            return eq(db_dir, g["db_id"], preds[j][0], g["SQL"])

        nocol = cell_ok("nocol")
        clar = cell_ok("clarify")
        if o:
            n_ok["open"] += 1
        if l:
            n_ok["lb"] += 1
        if nocol:
            n_ok["nocol"] += 1
        if clar:
            n_ok["clarify"] += 1
        lines.append(
            f"{iid:5d} {g['db_id']:<24} {bkt:<7} {yn(o):<5} {yn(l):<4} {yn(nocol):<5} {yn(clar):<4} {q[:48]}"
        )

    n = len(order)
    lines.append("")
    lines.append(f"n={n} fail={fail_n} control={len(ids['control'])}")
    for k in ("open", "lb", "nocol", "clarify"):
        lines.append(f"  {k:8s} {n_ok[k]}/{n} = {100*n_ok[k]/n:.1f}%")
    text = "\n".join(lines) + "\n"
    print(text, end="")
    (out / "summary.txt").write_text(text)


if __name__ == "__main__":
    main()

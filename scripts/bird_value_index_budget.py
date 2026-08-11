#!/usr/bin/env python3.12
"""BIRD value-index budget scout: NDV / docs / candidate columns."""

import json
import re
import sqlite3
import time
from collections import Counter, defaultdict
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

ROOTS = [
    Path("/root/workspace/ReActSqlExp/benchmarks/bird/train/train_databases"),
    Path("/root/workspace/ReActSqlExp/benchmarks/bird/dev/dev_databases"),
]
OUT = Path("/root/workspace/ReActSqlExp/results/bird/value_index_budget")
OUT.mkdir(parents=True, exist_ok=True)

TEXT_HINT = ("CHAR", "CLOB", "TEXT", "VARCHAR", "NVARCHAR", "STRING", "NCHAR")
SKIP_NAME = re.compile(
    r"(^id$|_id$|uuid|guid|hash|password|passwd|token|secret|email|phone|mobile|"
    r"ssn|url|path|blob|payload|json|xml|content|description|comment|remark|note|body|text$)",
    re.I,
)
ENTITY_NAME = re.compile(
    r"(name|title|brand|company|customer|product|city|country|region|state|genre|"
    r"category|type|status|label|tag|author|artist|album|movie|school|team|player|"
    r"vendor|supplier|client)",
    re.I,
)

EXACT_ROW_CAP = 2_000_000
SAMPLE_SCAN_CAP = 200_000
BUSY_MS = 30_000


def is_text(decl: str) -> bool:
    d = (decl or "").upper().strip()
    if not d:
        return True
    if any(x in d for x in ("INT", "REAL", "FLOA", "DOUB", "NUM", "DEC", "BOOL", "DATE", "TIME", "BLOB")):
        if any(h in d for h in TEXT_HINT):
            return True
        return False
    return any(h in d for h in TEXT_HINT) or d in ("OBJECT", "STRING")


def qident(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def list_dbs():
    out = []
    for root in ROOTS:
        split = "train" if "train" in root.as_posix() else "dev"
        for dbp in sorted(root.rglob("*.sqlite")):
            db_id = dbp.parent.name
            if db_id in ("train_databases", "dev_databases", "test_databases"):
                continue
            out.append((split, db_id, str(dbp)))
    return out


def analyze_db(args):
    split, db_id, db_path = args
    t0 = time.time()
    conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True, timeout=60)
    conn.execute(f"PRAGMA busy_timeout={BUSY_MS}")
    conn.execute("PRAGMA query_only=ON")
    cur = conn.cursor()
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = [r[0] for r in cur.fetchall()]
    cols_out = []
    errors = []
    for t in tables:
        try:
            cur.execute(f"PRAGMA table_info({qident(t)})")
            infos = cur.fetchall()
        except Exception as e:
            errors.append(f"pragma {t}: {e}")
            continue
        try:
            cur.execute(f"SELECT COUNT(*) FROM {qident(t)}")
            nrows = int(cur.fetchone()[0])
        except Exception as e:
            errors.append(f"count {t}: {e}")
            nrows = -1
        for _cid, name, ctype, _notnull, _dflt, pk in infos:
            if not is_text(ctype):
                continue
            if SKIP_NAME.search(name or ""):
                role_hint = "skipish"
            elif ENTITY_NAME.search(name or ""):
                role_hint = "entityish"
            else:
                role_hint = "other_text"
            rec = {
                "split": split,
                "db_id": db_id,
                "table": t,
                "column": name,
                "decl_type": ctype or "",
                "pk": int(pk or 0),
                "nrows": nrows,
                "role_hint": role_hint,
                "ndv": None,
                "ndv_mode": None,
                "nulls": None,
                "avg_len": None,
                "max_len": None,
                "error": None,
            }
            if nrows < 0:
                rec["error"] = "no_nrows"
                cols_out.append(rec)
                continue
            if nrows == 0:
                rec.update(ndv=0, ndv_mode="empty", nulls=0, avg_len=0, max_len=0)
                cols_out.append(rec)
                continue
            colq = qident(name)
            tq = qident(t)
            try:
                if nrows <= EXACT_ROW_CAP:
                    cur.execute(
                        f"SELECT COUNT(DISTINCT {colq}), "
                        f"SUM(CASE WHEN {colq} IS NULL THEN 1 ELSE 0 END), "
                        f"AVG(LENGTH(CAST({colq} AS TEXT))), "
                        f"MAX(LENGTH(CAST({colq} AS TEXT))) FROM {tq}"
                    )
                    ndv, nulls, avglen, maxlen = cur.fetchone()
                    rec.update(
                        ndv=int(ndv or 0),
                        ndv_mode="exact",
                        nulls=int(nulls or 0),
                        avg_len=float(avglen or 0),
                        max_len=int(maxlen or 0),
                    )
                else:
                    cur.execute(
                        f"SELECT COUNT(*) FROM ("
                        f"SELECT DISTINCT {colq} AS v FROM {tq} "
                        f"WHERE {colq} IS NOT NULL LIMIT {SAMPLE_SCAN_CAP + 1})"
                    )
                    c = int(cur.fetchone()[0])
                    capped = c > SAMPLE_SCAN_CAP
                    rec["ndv"] = SAMPLE_SCAN_CAP if capped else c
                    rec["ndv_mode"] = "lower_bound_capped" if capped else "exact_via_limit"
                    cur.execute(
                        f"SELECT SUM(CASE WHEN {colq} IS NULL THEN 1 ELSE 0 END), "
                        f"AVG(LENGTH(CAST({colq} AS TEXT))), "
                        f"MAX(LENGTH(CAST({colq} AS TEXT))) "
                        f"FROM (SELECT {colq} FROM {tq} LIMIT {SAMPLE_SCAN_CAP})"
                    )
                    nulls, avglen, maxlen = cur.fetchone()
                    rec["nulls"] = int(nulls or 0)
                    rec["avg_len"] = float(avglen or 0)
                    rec["max_len"] = int(maxlen or 0)
                    rec["sample_rows"] = min(nrows, SAMPLE_SCAN_CAP)
            except Exception as e:
                rec["error"] = str(e)[:200]
                errors.append(f"{t}.{name}: {e}")
            cols_out.append(rec)
    conn.close()
    return {
        "split": split,
        "db_id": db_id,
        "path": db_path,
        "n_tables": len(tables),
        "n_text_cols": len(cols_out),
        "elapsed_s": round(time.time() - t0, 2),
        "columns": cols_out,
        "errors": errors[:20],
    }


def summarize(all_cols):
    def bucket(ndv):
        if ndv is None:
            return "unknown"
        for thr, name in [
            (1, "0-1"),
            (10, "2-10"),
            (100, "11-100"),
            (1000, "101-1k"),
            (5000, "1k-5k"),
            (50000, "5k-50k"),
            (150000, "50k-150k"),
            (10**18, "150k+"),
        ]:
            if ndv <= thr:
                return name
        return "?"

    cand = [
        c
        for c in all_cols
        if c.get("ndv") is not None and c["pk"] == 0 and c["role_hint"] != "skipish"
    ]
    entityish = [c for c in cand if c["role_hint"] == "entityish"]
    other = [c for c in cand if c["role_hint"] == "other_text"]

    def dist(cols):
        ctr = Counter(bucket(c["ndv"]) for c in cols)
        ndvs = sorted(c["ndv"] for c in cols)

        def pct(p):
            if not ndvs:
                return None
            i = min(len(ndvs) - 1, int(round((p / 100) * (len(ndvs) - 1))))
            return ndvs[i]

        return {
            "n": len(cols),
            "max_ndv": max(ndvs) if ndvs else 0,
            "p50": pct(50),
            "p90": pct(90),
            "p99": pct(99),
            "buckets": dict(ctr),
            "sum_ndv": int(sum(ndvs)),
            "sum_ndv_cap5k": int(sum(min(c["ndv"], 5000) for c in cols)),
            "sum_ndv_cap50k": int(sum(min(c["ndv"], 50000) for c in cols)),
            "sum_ndv_cap150k": int(sum(min(c["ndv"], 150000) for c in cols)),
            "n_under_5k": sum(1 for c in cols if c["ndv"] <= 5000),
            "n_under_50k": sum(1 for c in cols if c["ndv"] <= 50000),
            "n_under_150k": sum(1 for c in cols if c["ndv"] <= 150000),
            "n_capped_lower_bound": sum(1 for c in cols if c.get("ndv_mode") == "lower_bound_capped"),
        }

    def simulate(max_cols, entity_cap, cat_cap, max_docs, entity_ndv_cap, cat_ndv_cap):
        ent = sorted(entityish, key=lambda c: (c["ndv"], c["db_id"], c["table"], c["column"]))
        cat = sorted(other, key=lambda c: (c["ndv"], c["db_id"], c["table"], c["column"]))
        picked = []
        docs = 0
        for lane, pool, ncol_cap, vcap in (
            ("entity", ent, entity_cap, entity_ndv_cap),
            ("category", cat, cat_cap, cat_ndv_cap),
        ):
            n = 0
            for c in pool:
                if len(picked) >= max_cols or n >= ncol_cap:
                    break
                if c["ndv"] > vcap:
                    continue
                take = c["ndv"]
                if docs + take > max_docs:
                    break
                picked.append({**c, "lane": lane, "docs_contributed": take})
                docs += take
                n += 1
        return {
            "columns_indexed": len(picked),
            "documents": docs,
            "entity_cols": sum(1 for p in picked if p["lane"] == "entity"),
            "category_cols": sum(1 for p in picked if p["lane"] == "category"),
            "dbs_touched": len({p["db_id"] for p in picked}),
            "postings_est": int(
                sum(max(1, (c.get("avg_len") or 4) * 2) * c["docs_contributed"] for c in picked)
            ),
        }

    # Per-DB budgets (more relevant than global across 80 DBs)
    per_db_docs = defaultdict(int)
    per_db_entity_docs = defaultdict(int)
    for c in cand:
        key = f"{c['split']}/{c['db_id']}"
        per_db_docs[key] += c["ndv"]
        if c["role_hint"] == "entityish":
            per_db_entity_docs[key] += c["ndv"]
    per_db_vals = sorted(per_db_docs.values())
    per_db_ent = sorted(per_db_entity_docs.values())

    def pct_list(vals, p):
        if not vals:
            return None
        i = min(len(vals) - 1, int(round((p / 100) * (len(vals) - 1))))
        return vals[i]

    scenarios = {
        "global_wisecat_mr90_strict": simulate(64, 40, 24, 100_000, 50_000, 5_000),
        "global_wisecat_code_relaxed": simulate(256, 160, 120, 800_000, 150_000, 5_000),
        "global_all_entityish_cap50k": simulate(10_000, 10_000, 0, 10**12, 50_000, 0),
        "global_all_text_nonpk_cap50k": simulate(10_000, 10_000, 10_000, 10**12, 50_000, 50_000),
        "global_all_text_nonpk_cap5k": simulate(10_000, 10_000, 10_000, 10**12, 5_000, 5_000),
    }

    top = sorted(cand, key=lambda c: -(c["ndv"] or 0))[:40]
    top_fmt = [
        (
            f"{c['split']}/{c['db_id']}.{c['table']}.{c['column']} "
            f"ndv={c['ndv']} mode={c['ndv_mode']} nrows={c['nrows']} "
            f"role={c['role_hint']} avg_len={c.get('avg_len')}"
        )
        for c in top
    ]

    by_db = defaultdict(lambda: {"text_cols": 0, "sum_ndv": 0, "max_ndv": 0, "entityish": 0})
    for c in cand:
        b = by_db[f"{c['split']}/{c['db_id']}"]
        b["text_cols"] += 1
        b["sum_ndv"] += c["ndv"]
        b["max_ndv"] = max(b["max_ndv"], c["ndv"])
        b["entityish"] += int(c["role_hint"] == "entityish")

    heaviest = sorted(by_db.items(), key=lambda kv: -kv[1]["sum_ndv"])[:15]

    return {
        "n_text_cols_total": len(all_cols),
        "n_candidate_nonpk_nonskip": len(cand),
        "entityish": dist(entityish),
        "other_text": dist(other),
        "all_candidates": dist(cand),
        "per_db_sum_ndv": {
            "max": max(per_db_vals) if per_db_vals else 0,
            "p50": pct_list(per_db_vals, 50),
            "p90": pct_list(per_db_vals, 90),
            "p99": pct_list(per_db_vals, 99),
        },
        "per_db_entityish_sum_ndv": {
            "max": max(per_db_ent) if per_db_ent else 0,
            "p50": pct_list(per_db_ent, 50),
            "p90": pct_list(per_db_ent, 90),
            "p99": pct_list(per_db_ent, 99),
        },
        "scenarios": scenarios,
        "top_ndv_columns": top_fmt,
        "heaviest_dbs_by_sum_ndv": [{"db": k, **v} for k, v in heaviest],
        "notes": [
            f"exact DISTINCT for tables with nrows<={EXACT_ROW_CAP}",
            f"larger tables: DISTINCT LIMIT {SAMPLE_SCAN_CAP}+1 lower bound "
            f"(capped reported as {SAMPLE_SCAN_CAP})",
            "role_hint is name-regex only (entityish vs skipish vs other_text); not Agent policy",
            "heldout_v1_smoke DBs == train DBs (symlink)",
            "Prefer per-db budgets: BIRD is multi-DB; WiseCat caps are per datasource",
        ],
    }


def main():
    dbs = list_dbs()
    print(f"scanning {len(dbs)} databases...", flush=True)
    results = []
    with ProcessPoolExecutor(max_workers=4) as ex:
        futs = {ex.submit(analyze_db, a): a for a in dbs}
        done = 0
        for fut in as_completed(futs):
            done += 1
            r = fut.result()
            results.append(r)
            print(
                f"[{done}/{len(dbs)}] {r['split']}/{r['db_id']} "
                f"text_cols={r['n_text_cols']} {r['elapsed_s']}s err={len(r['errors'])}",
                flush=True,
            )
            if done % 10 == 0:
                (OUT / "partial_dbs.json").write_text(
                    json.dumps(
                        [
                            {
                                "split": x["split"],
                                "db_id": x["db_id"],
                                "n_text_cols": x["n_text_cols"],
                                "elapsed_s": x["elapsed_s"],
                                "errors": x["errors"],
                            }
                            for x in results
                        ],
                        indent=2,
                    )
                )

    results.sort(key=lambda r: (r["split"], r["db_id"]))
    all_cols = [c for r in results for c in r["columns"]]
    summary = summarize(all_cols)
    summary["n_dbs"] = len(results)
    summary["splits"] = dict(Counter(r["split"] for r in results))
    summary["elapsed_total_s"] = round(sum(r["elapsed_s"] for r in results), 1)

    (OUT / "columns.jsonl").write_text(
        "\n".join(json.dumps(c, ensure_ascii=False) for c in all_cols) + "\n"
    )
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False))
    (OUT / "per_db.json").write_text(
        json.dumps(
            [
                {k: r[k] for k in ("split", "db_id", "n_tables", "n_text_cols", "elapsed_s", "errors")}
                for r in results
            ],
            indent=2,
            ensure_ascii=False,
        )
    )
    print(json.dumps({k: summary[k] for k in (
        "n_dbs", "splits", "n_text_cols_total", "n_candidate_nonpk_nonskip",
        "entityish", "other_text", "all_candidates", "per_db_sum_ndv",
        "per_db_entityish_sum_ndv", "scenarios", "heaviest_dbs_by_sum_ndv",
        "elapsed_total_s", "notes",
    ) if k in summary}, indent=2, ensure_ascii=False)[:5000])
    print("wrote", OUT)


if __name__ == "__main__":
    main()

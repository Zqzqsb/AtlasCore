#!/usr/bin/env python3
"""
对候选 case 验证 DAIL-SQL 是否做错。
直接用已有的 BIRD 全量预测文件，在数据库上执行比对。
"""
import json
import sqlite3
import signal

# 候选 idx 列表（我们正确 + 步数高的）
CANDIDATES = [860, 595, 935, 24, 77, 936, 944, 616, 871, 943, 1009,
              481, 705, 1525, 32, 86, 88, 271, 411, 689, 861, 870,
              33, 482, 605, 765, 890, 1039, 1350, 1391]

class QueryTimeout(Exception):
    pass

def timeout_handler(signum, frame):
    raise QueryTimeout()

def safe_exec(conn, sql, timeout=5):
    """执行 SQL，带超时保护"""
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(timeout)
    try:
        res = set(conn.execute(sql).fetchall())
        signal.alarm(0)
        return res, None
    except Exception as e:
        signal.alarm(0)
        return None, str(e)

def main():
    # 加载数据
    with open('benchmarks/bird/dev/dev.json') as f:
        bird_dev = json.load(f)

    with open('third_party/DAIL-SQL/results/BIRD_WITH_EVIDENCE-TEST_SQL_9-SHOT_EUCDISMASKPRESKLSIMTHR_QA-EXAMPLE_CTX-150_ANS-4096.txt') as f:
        dail_preds = [l.strip() for l in f.readlines()]

    print(f"BIRD dev: {len(bird_dev)} items, DAIL preds: {len(dail_preds)} lines\n")

    results = []
    for idx in CANDIDATES:
        item = bird_dev[idx]
        db_id = item['db_id']
        db_path = f"benchmarks/bird/dev/dev_databases/{db_id}/{db_id}.sqlite"
        gold_sql = item['SQL']
        dail_sql = dail_preds[idx]
        question = item['question']

        conn = sqlite3.connect(db_path)

        gold_res, gold_err = safe_exec(conn, gold_sql)
        if gold_err:
            conn.close()
            print(f"#{idx:4d} [{db_id}] SKIP (gold error: {gold_err[:50]})")
            continue

        dail_res, dail_err = safe_exec(conn, dail_sql)
        conn.close()

        if dail_err:
            dail_correct = False
            reason = f"execution error: {dail_err[:80]}"
        elif gold_res == dail_res:
            dail_correct = True
            reason = "match"
        else:
            dail_correct = False
            reason = f"wrong result (gold {len(gold_res)} rows vs dail {len(dail_res)} rows)"

        status = "✅ DAIL correct" if dail_correct else "❌ DAIL wrong"
        print(f"#{idx:4d} [{db_id:28s}] {status} | {reason[:60]}")

        results.append({
            'idx': idx,
            'db_id': db_id,
            'question': question,
            'dail_correct': dail_correct,
            'dail_sql': dail_sql,
            'gold_sql': gold_sql,
            'reason': reason,
        })

    # 汇总
    wrong = [r for r in results if not r['dail_correct']]
    print(f"\n{'='*60}")
    print(f"总计验证: {len(results)} 个候选")
    print(f"DAIL-SQL 做错: {len(wrong)} 个（我们做对、DAIL做错 → 可用于 case study）")
    print(f"{'='*60}")
    for r in wrong:
        print(f"  #{r['idx']:4d} [{r['db_id']}] {r['question'][:80]}")
        print(f"         reason: {r['reason'][:80]}")
        print()

if __name__ == '__main__':
    main()

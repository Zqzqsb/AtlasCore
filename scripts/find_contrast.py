#!/usr/bin/env python3
"""Find cases where our method is correct but DAIL-SQL is wrong (BIRD dev set)."""
import json, sqlite3, os

BASE = '/home/zq/Projects/ReActSqlExp'

with open(f'{BASE}/results/bird/20260301_180516_react+rich_context+clarify/results.json') as f:
    our_bird = json.load(f)

with open(f'{BASE}/third_party/DAIL-SQL/results/DAIL-SQL+GPT-4.txt') as f:
    dail_preds = [l.strip() for l in f.readlines()]

with open(f'{BASE}/benchmarks/bird/dev/dev.json') as f:
    bird_dev = json.load(f)

import signal

class TimeoutError(Exception):
    pass

def timeout_handler(signum, frame):
    raise TimeoutError("query timeout")

def exec_and_compare(db_path, gold_sql, pred_sql, timeout=5):
    """Return (pred_result, is_correct, error)"""
    conn = None
    try:
        conn = sqlite3.connect(db_path)
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(timeout)
        gold_res = set(conn.execute(gold_sql).fetchall())
    except Exception as e:
        signal.alarm(0)
        if conn: conn.close()
        return None, None, f"gold error: {e}"
    try:
        pred_res = set(conn.execute(pred_sql).fetchall())
        signal.alarm(0)
        correct = (gold_res == pred_res)
        conn.close()
        return pred_res, correct, None
    except Exception as e:
        signal.alarm(0)
        if conn: conn.close()
        return None, False, str(e)

import sys
contrast = []
total = min(len(our_bird), len(dail_preds), len(bird_dev))
for i in range(total):
    if i % 100 == 0:
        print(f"Processing {i}/{total}...", flush=True)
    bird_item = bird_dev[i]
    our = our_bird[i]
    dail_sql = dail_preds[i]
    
    db_id = bird_item['db_id']
    db_path = f"{BASE}/benchmarks/bird/dev/dev_databases/{db_id}/{db_id}.sqlite"
    gold_sql = bird_item.get('SQL', '')
    our_sql = our.get('generated_sql', '')
    
    if not our_sql or our.get('status') == 'error':
        continue

    # Check our result
    _, our_correct, our_err = exec_and_compare(db_path, gold_sql, our_sql)
    if not our_correct:
        continue
    
    # Check DAIL-SQL result
    _, dail_correct, dail_err = exec_and_compare(db_path, gold_sql, dail_sql)
    if dail_correct:
        continue
    
    contrast.append({
        'idx': i,
        'db_id': db_id,
        'question': bird_item['question'],
        'evidence': bird_item.get('evidence', ''),
        'difficulty': bird_item.get('difficulty', ''),
        'gold_sql': gold_sql,
        'dail_sql': dail_sql,
        'dail_err': dail_err,
        'our_sql': our_sql,
        'react_steps': our.get('react_steps', 0),
    })

print(f"Found {len(contrast)} contrast cases (us correct, DAIL-SQL wrong)")
print()
for c in contrast:
    err_tag = " [SQL_ERR]" if c['dail_err'] else ""
    print(f"#{c['idx']:4d} [{c['difficulty']:12s}] steps={c['react_steps']:2d} {c['db_id']:30s}{err_tag} | Q: {c['question'][:85]}")

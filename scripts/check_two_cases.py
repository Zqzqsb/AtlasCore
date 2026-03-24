#!/usr/bin/env python3
import sqlite3, json

BASE = '/home/zq/Projects/ReActSqlExp'

with open(f'{BASE}/benchmarks/bird/dev/dev.json') as f:
    bird = json.load(f)

# DAIL-SQL BIRD predictions (9-shot best variant)
with open(f'{BASE}/third_party/DAIL-SQL/results/BIRD_WITH_EVIDENCE-TEST_SQL_9-SHOT_EUCDISMASKPRESKLSIMTHR_QA-EXAMPLE_CTX-150_ANS-4096.txt') as f:
    dail_lines = [l.strip() for l in f.readlines()]

for idx in [32, 1525]:
    item = bird[idx]
    db_id = item['db_id']
    db = f'{BASE}/benchmarks/bird/dev/dev_databases/{db_id}/{db_id}.sqlite'
    conn = sqlite3.connect(db)
    
    print(f"=== BIRD #{idx+1} ({db_id}) ===")
    print(f"Q: {item['question'][:100]}")
    print(f"Gold SQL: {item['SQL'][:150]}")
    
    gold = conn.execute(item['SQL']).fetchall()
    print(f"Gold result ({len(gold)} rows): {gold[:3]}")
    
    dail_sql = dail_lines[idx]
    print(f"\nDAIL-SQL: {dail_sql[:150]}")
    try:
        dail_res = conn.execute(dail_sql).fetchall()
        print(f"DAIL result ({len(dail_res)} rows): {dail_res[:3]}")
        print(f"Match: {set(gold) == set(dail_res)}")
    except Exception as e:
        print(f"DAIL error: {e}")
    
    conn.close()
    print()

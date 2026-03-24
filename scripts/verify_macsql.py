#!/usr/bin/env python3
"""Verify MAC-SQL predictions for 3 completed cases."""
import json, sqlite3

with open('benchmarks/bird/dev/dev.json') as f:
    bird = json.load(f)

# MAC-SQL predicted SQLs (extracted from logs)
mac_preds = {
    33: """SELECT T1.`School Name`, T2.`Website`
  FROM frpm AS T1
  INNER JOIN schools AS T2
  ON T1.`CDSCode` = T2.`CDSCode`
  WHERE T1.`Free Meal Count (Ages 5-17)` BETWEEN 1900 AND 2000
  AND T2.`Website` IS NOT NULL""",

    32: """SELECT T1.`School Name`, (CAST(T1.`FRPM Count (K-12)` AS REAL) / T1.`Enrollment (K-12)`) AS `Eligible Rate`
  FROM frpm AS T1
  INNER JOIN schools AS T2
  ON T1.`CDSCode` = T2.`CDSCode`
  WHERE T2.`SOC` = '66'
  ORDER BY T1.`FRPM Count (K-12)` DESC
  LIMIT 5""",

    860: """SELECT d.nationality
FROM drivers d
JOIN qualifying q ON d.driverId = q.driverId
WHERE q.raceId = 355
AND q.q2 LIKE '1:40%%'"""
}

for idx, pred_sql in mac_preds.items():
    item = bird[idx]
    db_id = item['db_id']
    db_path = f"benchmarks/bird/dev/dev_databases/{db_id}/{db_id}.sqlite"
    gold_sql = item['SQL']

    conn = sqlite3.connect(db_path)
    try:
        gold_res = set(conn.execute(gold_sql).fetchall())
    except Exception as e:
        print(f"#{idx} gold error: {e}")
        conn.close()
        continue

    try:
        pred_res = set(conn.execute(pred_sql).fetchall())
        match = (gold_res == pred_res)
        status = "✅ correct" if match else "❌ wrong"
        print(f"#{idx} [{db_id}] {status}")
        print(f"  Q: {item['question'][:100]}")
        print(f"  Gold SQL: {gold_sql[:120]}")
        print(f"  MAC  SQL: {pred_sql.strip()[:120]}")
        print(f"  Gold: {len(gold_res)} rows, sample: {list(gold_res)[:3]}")
        print(f"  Pred: {len(pred_res)} rows, sample: {list(pred_res)[:3]}")
        print()
    except Exception as e:
        print(f"#{idx} [{db_id}] ❌ execution error: {e}")
        print()

    conn.close()

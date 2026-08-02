# ProjAligner label v2

## Target JSON
```json
{"shape":"scalar","fields":[{"name":"user_id","kind":"count"}]}
```

## name rules
1. Prefer SELECT alias if human-readable
2. Else bare column name (strip `T1.` / `table.`)
3. Aggregates: name=column (or `*` for COUNT(*)), kind=agg
4. Never put `COUNT(...)` / `AVG(...)` into name

## shape rules (unchanged, from gold SQL)
- scalar: agg without GROUP BY
- table: agg with GROUP BY
- entity: no agg + LIMIT 1
- list: otherwise

## Train tips
- max_seq_length ≥ 1024 recommended (schema still shorter than v1 full DB)
- LoRA: consider attn+mlp, r=16~32, epochs 2~3
- Eval metric: fields order exact + shape; EX cares about fields more than entity/list

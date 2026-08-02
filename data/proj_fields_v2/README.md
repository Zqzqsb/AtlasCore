# proj_fields SFT pack (v2)

- **label_version**: `v2`
- **schema_mode**: `gold_fk`

### v2 changes vs v1
- `fields[].name`: short labels (alias / bare column / `*` for COUNT(*)); **no** `COUNT(T2.x)` expressions
- `kind` carries agg type (`count|avg|sum|max|min|col|star`)
- Input schema: gold SQL tables + one FK hop (less noise than full DB)
- Held-out smoke/standard questions excluded from train

Upload **`taiji_sft_train.jsonl`** for SFT; **`taiji_sft_train_preview100.jsonl`** for format smoke; **`taiji_sft_dev.jsonl`** for eval.

Train rows: 7619
Dev rows: 1534

See `probe_report.md`.

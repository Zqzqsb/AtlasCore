# BIRD hidden-test 复现说明

英文版：[BIRD_HIDDEN_TEST.md](BIRD_HIDDEN_TEST.md)

仓库：https://github.com/Zqzqsb/AtlasCore  
分支：`prepare_for_bird_test`（latest）

需要 Go 1.24+。下面命令里的路径请改成你们的实际路径。

---

## 1. Clone

```bash
git clone https://github.com/Zqzqsb/AtlasCore.git
cd AtlasCore
```

## 2. 切换分支

```bash
git checkout prepare_for_bird_test
```

## 3. 填入 key

```bash
cp llm_config.json.example llm_config.json
```

把两把 key 分别填进 `llm_config.json` 对应块的 `"token"`。跑的时候用 `--model` 选一把，后面每步用同一个。

| `--model` | `llm_config.json` 块 |
| --------- | -------------------- |
| `deepseek-v4-pro` | `deepseek_v4_pro` |
| `deepseek-v4-pro-official` | `deepseek_v4_pro_official` |

## 4. 生成 RC 和 index

对每个数据库生成 Rich Context，再构建 value index。

把 `/path/to/test_databases` 换成你们的 sqlite 根目录，`--model` 换成第 3 步选的那个。

```bash
go run ./cmd/gen_all_dev \
  --benchmark bird \
  --model deepseek-v4-pro \
  --db-dir /path/to/test_databases \
  --output-dir contexts/sqlite/bird_official_test \
  --workers 2

go run ./cmd/enrich_rc \
  --context-dir contexts/sqlite/bird_official_test \
  --db-dir /path/to/test_databases \
  --value-index \
  --value-index-label heuristic
```

## 5. 准备并确认数据集

题目 JSON 必须是数组，字段如下（`SQL` 留空）。多余字段会忽略。

```json
[
  {
    "question_id": 0,
    "db_id": "california_schools",
    "question": "What is the highest eligible free rate for K-12 students in schools in Alameda County?",
    "evidence": "Eligible free rate for K-12 = `Free Meal Count (K-12)` / `Enrollment (K-12)`",
    "SQL": ""
  }
]
```

sqlite 目录结构（官方 BIRD 布局；有 `database_description/*.csv` 时 RC / 索引会自动读）：

```text
/path/to/test_databases/
  california_schools/california_schools.sqlite
  california_schools/database_description/*.csv
  <db_id>/<db_id>.sqlite
```

确认：每个 `db_id` 都有对应 sqlite；`test.json` 里的库都已在第 4 步生成 `contexts/sqlite/bird_official_test/<db_id>.json`。

## 6. Smoke test

先跑 3 题检查接线。推理默认单线程；全量参数见文末「参考」。

把 `--data`、`--db-dir` 换成第 5 步确认过的路径。

```bash
go run ./cmd/eval \
  --benchmark bird \
  --mode leaderboard \
  --model deepseek-v4-pro \
  --data /path/to/test.json \
  --db-dir /path/to/test_databases \
  --context-dir contexts/sqlite/bird_official_test \
  --grounding-mode off \
  --limit 3 \
  --output-dir results/bird/official_test_smoke
```

成功应看到 `results/bird/official_test_smoke/predict.sql`（每行 `SQL<TAB>db_id`）。

## 7. 全量测试

换一个空的 `--output-dir`（已有 `predict.sql` 的目录不会被覆盖）。`--limit 0` 表示全部。第 4 步和第 7 步耗时长，请放在 tmux 里跑。

```bash
tmux new -s bird_eval
# 粘贴下面的 go run … 命令
# 断开：Ctrl-b d    回来：tmux attach -t bird_eval
```

```bash
go run ./cmd/eval \
  --benchmark bird \
  --mode leaderboard \
  --model deepseek-v4-pro \
  --data /path/to/test.json \
  --db-dir /path/to/test_databases \
  --context-dir contexts/sqlite/bird_official_test \
  --grounding-mode off \
  --limit 0 \
  --parallel 4 \
  --tpm-control none \
  --output-dir results/bird/official_test
```

产出（与 `test.json` 同序）：

- `results/bird/official_test/predict.sql` — `SQL<TAB>db_id`
- 需要官方 `predict.json` 时：

```bash
python3 - <<'PY'
import json
from pathlib import Path
lines = Path("results/bird/official_test/predict.sql").read_text().splitlines()
obj = {}
for i, line in enumerate(lines):
    line = line.strip()
    if not line:
        continue
    sql, _, db = line.partition("\t")
    obj[str(i)] = f"{sql}\t----- bird -----\t{db}"
Path("results/bird/official_test/predict.json").write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n")
print(len(obj), "preds")
PY
```

用你们的 gold 和官方 `evaluation.py` 打分。

---

## 参考

### 官方 `database_description/*.csv`

放在每个库目录下（官方 train/dev/test 都是这个布局）。`gen_all_dev` 和 `enrich_rc` **自动读取**，不需要另给 `column_meaning.json`。有描述也仍会生成 RC，只当参考。

| csv 字段 | 用途 |
| --- | --- |
| `column_description` | RC 生成时参考，写入列含义 |
| 值编码 / 闭集枚举（`0: N; 1: Y`，`"commander"` 列表） | 写入 value index 对应 value 的别名，推理时由 linker 召回 |
| NULL / commonsense 规则 | 写入该表 `business_rules` |

csv 文件名 = 表名。列名对 `original_column_name`。

### 推理参数

| 参数 | 取值 | 说明 |
| --- | --- | --- |
| `--parallel` | 正整数，默认 `1` | `N` 把题目切成 N 段，写到 `output-dir/p0`…`p{N-1}`，再合成 `predict.sql` / `results.json` / `logs/` |
| `--tpm-control` | `50` / `100` / `none`，默认 `100` | 内部 TPM 闸：默认预算 20M tokens/分钟的 50% 或 100%；`none` 关掉闸（429 退避仍在） |

### tmux 与日志

第 4 步 RC 和第 7 步全量推理都请挂在 tmux（`tmux new -s bird_eval`），避免 SSH 断开把进程带走。

| 看什么 | 命令 |
| --- | --- |
| 是否还在跑 | `tmux ls` / `tmux attach -t bird_eval` |
| 已写出多少题（并发进行中看分片） | `wc -l results/bird/official_test/p0/predict.sql` |
| 跑完后的总预测 | `wc -l results/bird/official_test/predict.sql` |
| 压缩进度 | `tail -f results/bird/official_test/inference.log`（并发进行中用 `p0/inference.log`） |
| 单题详情 | `results/bird/official_test/logs/0001_*.log` |

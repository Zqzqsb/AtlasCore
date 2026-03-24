## 候选 Case Study 案例（我们正确 + ReAct 步数 ≥ 5）

共约 70 个候选，以下是步数最高的 Top 30：

| 排名 | idx  | steps | db_id                    | question                                                                                   |
|------|------|-------|--------------------------|--------------------------------------------------------------------------------------------|
| 1    | 860  | 14    | formula_1                | For the driver who had the Q2 time as 0:01:40 in qualifying race No. 355...                |
| 2    | 595  | 13    | codebase_community       | Which user have only one post history per post and having at least 1000 views?              |
| 3    | 935  | 11    | formula_1                | How many drivers managed to finish the race in the 2008 Australian Grand Prix?              |
| 4    | 24   | 10    | california_schools       | Give the names of the schools with percent eligible for free meals in K-12 > ...            |
| 5    | 77   | 10    | california_schools       | Which schools served a grade span of K-9 in the county of Los Angeles...                    |
| 6    | 936  | 10    | formula_1                | Which was the fastest lap for Lewis Hamilton in the 2008 Australian Grand Prix?              |
| 7    | 944  | 10    | formula_1                | How much faster in percentage is the champion than the driver who finished last...           |
| 8    | 616  | 9     | codebase_community       | What is the comment's rating score of the post created on 7/19/2010 7:19:56 PM              |
| 9    | 871  | 9     | formula_1                | For the driver who had Q2 time as 0:01:15 in race No. 347, where is he from?                |
| 10   | 943  | 9     | formula_1                | What is the rate of drivers completing all laps in the 2008 Australian Grand Prix?           |
| 11   | 1009 | 9     | formula_1                | Please list the time each driver spent at pit stop during 2011 Australian Grand Prix        |
| 12   | 481  | 8     | card_games               | Please list all the foreign languages in which "Ancestor's Chosen" has a flavor text        |
| 13   | 705  | 8     | codebase_community       | Give the user's reputation and up vote number of "fine, you win :)" commenter               |
| 14   | 1525 | 8     | debit_card_specializing  | What is the percentage of the customers who used EUR in 2012/8/25?                          |
| 15   | 32   | 7     | california_schools       | What is the eligible free or reduced price meal rate for top 5 schools grades 1-12?         |
| 16   | 86   | 7     | california_schools       | What is the administrator's last name that oversees the school with Charter number 40?      |
| 17   | 88   | 7     | california_schools       | What is the administrator's email for the school with highest number of test takers?         |
| 18   | 271  | 7     | toxicology               | Does bond id TR001_1_8 have both element of chlorine and carbon?                            |
| 19   | 411  | 7     | card_games               | To which artist does the card with text "Das perfekte Gegenmittel..." belong?                |
| 20   | 689  | 7     | codebase_community       | Identify the display name and location of the user who...                                   |
| 21   | 861  | 7     | formula_1                | What is the average fastest lap speed of the...                                             |
| 22   | 870  | 7     | formula_1                | For the driver who had Q2 time as 0:01:40 in qualifying race No. 355...                     |
| 23   | 33   | 6     | california_schools       | What are the names of the top schools with ownership code 66?                               |
| 24   | 482  | 6     | card_games               | Among the cards with multiverse id 135193...                                                |
| 25   | 605  | 6     | codebase_community       | What is the percentage of answers that got a score of more than 40...                       |
| 26   | 765  | 5     | superhero                | How many heroes have stealth power?                                                        |
| 27   | 890  | 5     | formula_1                | How many seasons has Silverstone Circuit hosted the UK grand prix?                           |
| 28   | 1039 | 5     | european_football_2      | Find the average number of long-shot done by Ahmed Samir Farag.                             |
| 29   | 1350 | 5     | student_club             | What is the status of the event which bought "Post Cards, Posters" on 2019/8/20?            |
| 30   | 1391 | 5     | student_club             | What is the ratio between students majored in finance and physics?                          |

## DAIL-SQL 对比验证结果

对 30 个候选在数据库上实际执行 DAIL-SQL 预测 SQL 与 gold SQL 比对：

### ❌ DAIL-SQL 做错的（20 个）— 可用于 case study

| idx  | steps | db_id                   | DAIL-SQL 错误原因                                    |
|------|-------|-------------------------|------------------------------------------------------|
| 860  | 14    | formula_1               | wrong result (gold 8 rows vs dail 0 rows)            |
| 595  | 13    | codebase_community      | wrong result (gold 94 rows vs dail 46 rows)          |
| 24   | 10    | california_schools      | wrong result (gold 1085 rows vs dail 0 rows)         |
| 77   | 10    | california_schools      | wrong result (gold 2 rows vs dail 0 rows)            |
| 936  | 10    | formula_1               | wrong result (gold 0 rows vs dail 1 rows)            |
| 944  | 10    | formula_1               | wrong result (gold 1 rows vs dail 0 rows)            |
| 616  | 9     | codebase_community      | execution error: no such column: T1.CreationDate     |
| 871  | 9     | formula_1               | wrong result (gold 5 rows vs dail 0 rows)            |
| 1009 | 9     | formula_1               | execution error: no such column: T1.driverId         |
| 32   | 7     | california_schools      | wrong result (gold 5 rows vs dail 5 rows)            |
| 86   | 7     | california_schools      | wrong result (gold 1 rows vs dail 0 rows)            |
| 88   | 7     | california_schools      | wrong result (gold 1 rows vs dail 1 rows)            |
| 271  | 7     | toxicology              | wrong result (gold 2 rows vs dail 1 rows)            |
| 411  | 7     | card_games              | wrong result (gold 1 rows vs dail 0 rows)            |
| 689  | 7     | codebase_community      | wrong result (gold 1 rows vs dail 0 rows)            |
| 861  | 7     | formula_1               | wrong result (gold 2 rows vs dail 0 rows)            |
| 33   | 6     | california_schools      | wrong result (gold 2 rows vs dail 3 rows)            |
| 482  | 6     | card_games              | wrong result (gold 1 rows vs dail 2 rows)            |
| 765  | 5     | superhero               | wrong result (gold 1 rows vs dail 1 rows)            |
| 1350 | 5     | student_club            | wrong result (gold 1 rows vs dail 0 rows)            |

### ✅ DAIL-SQL 也做对的（10 个）— 不可用

| idx  | steps | db_id                   |
|------|-------|-------------------------|
| 935  | 11    | formula_1               |
| 943  | 9     | formula_1               |
| 481  | 8     | card_games              |
| 705  | 8     | codebase_community      |
| 1525 | 8     | debit_card_specializing |
| 870  | 7     | formula_1               |
| 605  | 6     | codebase_community      |
| 890  | 5     | formula_1               |
| 1039 | 5     | european_football_2     |
| 1391 | 5     | student_club            |

## MAC-SQL 对比验证结果

在 MAC-SQL 上真实跑了 8 个候选（使用 deepseek-v3 作为后端 LLM）：

| idx  | db_id                   | MAC-SQL  | DAIL-SQL |
|------|-------------------------|----------|----------|
| 33   | california_schools      | ❌ wrong  | ❌ wrong  |
| 32   | california_schools      | ❌ wrong  | ❌ wrong  |
| 860  | formula_1               | ✅ correct| ❌ wrong  |
| 271  | toxicology              | ❌ wrong  | ❌ wrong  |
| 411  | card_games              | ❌ wrong  | ❌ wrong  |
| 1350 | student_club            | ✅ correct| ❌ wrong  |
| 765  | superhero               | ❌ wrong  | ❌ wrong  |
| 86   | california_schools      | ✅ correct| ❌ wrong  |

## ✅ 最终选定的两个案例

### 案例 1（我们对、MAC-SQL 错）：BIRD #33 — california_schools

**Question**: What is the eligible free or reduced price meal rate for the top 5 schools in grades 1-12 with the highest free or reduced price meal count of the schools with the ownership code 66?

**Evidence**: grades 1-12 means K-12; Eligible free or reduced price meal rate for K-12 = `FRPM Count (K-12)` / `Enrollment (K-12)`

**Gold SQL**:
```sql
SELECT CAST(T1.`FRPM Count (K-12)` AS REAL) / T1.`Enrollment (K-12)`
FROM frpm AS T1 INNER JOIN schools AS T2 ON T1.CDSCode = T2.CDSCode
WHERE T2.SOC = 66 ORDER BY T1.`FRPM Count (K-12)` DESC LIMIT 5
```

**我们的 SQL（正确 ✅）**:
```sql
SELECT CAST(T1.`FRPM Count (K-12)` AS REAL) / T1.`Enrollment (K-12)`
FROM frpm AS T1 JOIN schools AS T2 ON T1.CDSCode = T2.CDSCode
WHERE T2.SOC = '66' ORDER BY T1.`FRPM Count (K-12)` DESC LIMIT 5
```

**MAC-SQL 的 SQL（错误 ❌）**:
```sql
SELECT T1.`School Name`, (CAST(T1.`FRPM Count (K-12)` AS REAL) / T1.`Enrollment (K-12)`) AS `Eligible Rate`
FROM frpm AS T1 INNER JOIN schools AS T2 ON T1.`CDSCode` = T2.`CDSCode`
WHERE T2.`SOC` = '66'
ORDER BY T1.`FRPM Count (K-12)` DESC LIMIT 5
```
MAC-SQL 错误原因：**多选了 School Name 列**，导致返回结果包含额外字段，与 gold 不匹配。

<details>
<summary>MAC-SQL 完整推理日志（来自 bird_32.log，对应此问题）</summary>

**Step 1: Schema Linking（列/表筛选）**

MAC-SQL 正确识别了 frpm 和 schools 表，保留了相关列（包括 SOC、FRPM Count (K-12) 等），丢弃了 satscores。输出：

```json
{
  "frpm": ["CDSCode", "Enrollment (K-12)", "Free Meal Count (K-12)", "FRPM Count (K-12)", "Percent (%) Eligible FRPM (K-12)", "School Name"],
  "satscores": "drop_all",
  "schools": ["CDSCode", "SOC", "SOCType", "GSoffered", "GSserved", "School"]
}
```

**Step 2: SQL Generation（分解子问题生成 SQL）**

MAC-SQL 将问题分解为 3 个子问题：

Sub question 1: 找到 ownership code 66 的学校
```sql
SELECT `CDSCode` FROM schools WHERE `SOC` = '66'
```

Sub question 2: 找到这些学校中 FRPM Count (K-12) 最高的 Top 5
```sql
SELECT T1.`CDSCode`, T1.`FRPM Count (K-12)`
  FROM frpm AS T1 INNER JOIN schools AS T2 ON T1.`CDSCode` = T2.`CDSCode`
  WHERE T2.`SOC` = '66'
  ORDER BY T1.`FRPM Count (K-12)` DESC LIMIT 5
```

Sub question 3: 计算这 5 所学校的 eligible rate
```sql
SELECT T1.`School Name`, (CAST(T1.`FRPM Count (K-12)` AS REAL) / T1.`Enrollment (K-12)`) AS `Eligible Rate`
  FROM frpm AS T1 INNER JOIN schools AS T2 ON T1.`CDSCode` = T2.`CDSCode`
  WHERE T2.`SOC` = '66'
  ORDER BY T1.`FRPM Count (K-12)` DESC LIMIT 5
```

⚠️ **错误**：MAC-SQL 在最终 SQL 中多选了 `School Name` 列，而 gold SQL 只要求返回 eligible rate 数值。

**Step 3: 无 Refinement**

MAC-SQL 的 Refine 阶段未触发（日志中出现 `Hello world!` 测试消息），最终直接使用了 Step 2 的 SQL。由于执行本身不报错（返回了 5 行数据），MAC-SQL 的 Refine 机制只在"无结果"或"执行报错"时才触发，无法发现"多选列"这种语义错误。

</details>

**为什么我们能做对——RC + ReAct 优势**:

1. **Rich Context 提供了 SOC 列的实际值分布**：RC 明确展示 `DOC` 和 `SOC` 列的值分布（如 `DOC: 54=10190, 52=4378...`），让 LLM 知道这两列都存在且含义不同。
2. **ReAct 自我纠错发现了 DOC→SOC 的错误映射**：
   - Step 1：LLM 先猜 "ownership code" → `DOC = '66'`，执行后**返回 0 行**
   - Step 2：探查 `DOC = '66'`，确认不存在
   - Step 3：探查 `County Code = '66'`，也不存在
   - Step 4：探查 `SOC = '66'`，**找到了！**
   - Step 5：用 SOC 重写 SQL，返回 5 行正确结果
   - Step 6：确认并提交
3. **MAC-SQL 没有这两个能力**：一次性生成 SQL，无法验证中间结果；也不知道 DOC vs SOC 的实际值分布。

---

### 案例 2（我们对、DAIL-SQL 错）：BIRD #860 — formula_1

**Question**: For the driver who had the Q2 time as 0:01:40 in the qualifying race No. 355, what is his nationality and which team did he play for?

**Evidence**: (time format hints)

**Gold SQL**:
```sql
SELECT DISTINCT T2.nationality FROM qualifying AS T1
INNER JOIN drivers AS T2 ON T2.driverId = T1.driverId
WHERE T1.raceId = 355 AND T1.q2 LIKE '1:40%'
```

**DAIL-SQL 的 SQL（错误 ❌，返回 0 行）**:
```sql
SELECT T2.nationality FROM qualifying AS T1
INNER JOIN drivers AS T2 ON T1.driverId = T2.driverId
WHERE T1.q2 = '0:01:40' AND T1.raceId = 355
```
DAIL-SQL 错误原因：**时间格式不匹配**。数据库中 q2 存储为 `'1:40.xxx'` 格式（分:秒.毫秒），但 DAIL-SQL 用了问题原文的 `'0:01:40'`（时:分:秒格式），精确匹配失败返回 0 行。

**我们的 SQL（正确 ✅）**:
（ReAct 通过执行验证发现精确匹配返回 0 行，然后探查数据库中的实际时间格式，最终用 LIKE 模式匹配成功）

**MAC-SQL 在此 case 的表现（✅ 最终做对了，但过程曲折）**:

<details>
<summary>MAC-SQL #860 完整推理日志</summary>

**Step 1: Schema Linking**

MAC-SQL 正确识别了 qualifying 和 drivers 表，保留了关键列（driverId, nationality, q2, raceId 等），丢弃了不相关的表：

```json
{
  "circuits": "drop_all",
  "constructors": "drop_all",
  "drivers": ["driverId", "nationality", "forename", "surname", "dob", "driverRef"],
  "seasons": "drop_all",
  "races": ["raceId", "year", "name", "date", "time", "circuitId"],
  "constructorResults": "drop_all",
  "constructorStandings": "drop_all",
  "driverStandings": "drop_all",
  "lapTimes": "drop_all",
  "pitStops": "drop_all",
  "qualifying": ["qualifyId", "raceId", "driverId", "q2", "q1", "q3"],
  "status": "drop_all",
  "results": "drop_all"
}
```

**Step 2: SQL Generation（第一次尝试）**

MAC-SQL 分解为 2 个子问题，最终生成：
```sql
SELECT `nationality`
  FROM drivers
  WHERE `driverId` = (
    SELECT `driverId` FROM qualifying WHERE `raceId` = 355 AND `q2` = '0:01:40'
  )
```
⚠️ **犯了和 DAIL-SQL 一样的错**：直接用问题原文的 `'0:01:40'` 格式做精确匹配。

**Step 3: Refine #1（第一次修正）**

执行后返回 "no data selected"。MAC-SQL 的 Refine 模块被触发，LLM 分析了错误原因：
> "The Q2 time in the question is '0:01:40' but in the query it's '1:40.000' — these formats don't match"
> "The qualifying table's q2 column examples show times in format '1:46.328' (minutes:seconds.milliseconds)"

修正为：
```sql
SELECT d.nationality
FROM drivers d JOIN qualifying q ON d.driverId = q.driverId
WHERE q.raceId = 355 AND q.q2 = '1:40.000'
```
⚠️ **还是错**：虽然意识到了格式问题，但猜测的 `'1:40.000'` 仍然不匹配实际数据中的 `'1:40.xxx'`。

**Step 4: Refine #2（第二次修正）**

再次返回 "no data selected"。LLM 进一步分析，决定用 LIKE 模糊匹配：
```sql
SELECT d.nationality
FROM drivers d JOIN qualifying q ON d.driverId = q.driverId
WHERE q.raceId = 355 AND q.q2 LIKE '1:40%'
```
✅ **终于成功**！通过 `LIKE '1:40%'` 匹配到了数据。

**关键观察**：MAC-SQL 在这个 case 上也遇到了和 DAIL-SQL 完全一样的时间格式问题，但因为有 **Refine 机制**（执行→报错→重试），经过 **2 轮修正** 最终做对了。这说明执行反馈是解决此类问题的关键能力。

</details>

**为什么我们能做对——RC + ReAct 优势**:

1. **Rich Context 提供了 q2 列的数据质量警告**：RC 明确指出 `q2` 是 TEXT 类型存储数值，且有空值/空字符串问题，提醒 LLM 注意格式陷阱。
2. **ReAct 多步推理修正了格式**：
   - 先用精确匹配 `q2 = '1:40.000'` → 0 行
   - 探查实际数据格式
   - 改用 `q2 LIKE '1:40%'` → 成功匹配 8 行
3. **DAIL-SQL 是一次性生成**：没有执行验证能力，无法发现格式不匹配问题。
4. **MAC-SQL 虽然最终做对了，但花了 2 轮 Refine**：说明没有 Rich Context 提供的数据格式提示，即使有执行反馈也需要更多试错。我们的方法通过 RC 预先告知格式陷阱，减少了试错成本。

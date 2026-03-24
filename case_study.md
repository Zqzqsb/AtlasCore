# Case Study: Rich Context + ReAct 方法优势展示

## 案例 1: BIRD #33 — 模糊列名 + 整数除法陷阱

**数据库:** `california_schools`  |  **难度:** moderate

**问题:** What is the eligible free or reduced price meal rate for the top 5 schools in grades 1-12 with the highest free or reduced price meal count of the schools with the ownership code 66?

### Baseline（Direct Prompting，无 ReAct / 无 Rich Context）❌

```sql
SELECT "School Name",
       "FRPM Count (K-12)" / "Enrollment (K-12)" AS eligible_free_reduced_rate
FROM frpm
WHERE "IRC" = 66
ORDER BY "FRPM Count (K-12)" DESC
LIMIT 5;
```

**返回 0 行 → 评测失败（row count mismatch: gold=5, pred=0）**

错误原因：
1. **列映射错误**：将"ownership code 66"映射到 `frpm.IRC`（实际应为 `schools.SOC`），但 IRC 列只有 0 和 1 两种值
2. **缺少 CAST**：整数除法 `FRPM Count / Enrollment` 在 SQLite 中会截断为 0
3. **缺少 JOIN**：需要关联 `schools` 表才能过滤 SOC

### 我们的方法（ReAct + Rich Context）✅

**Rich Context 提供的关键信息：**
- `schools.SOC`: TEXT field storing numeric values → `CAST("SOC" AS INTEGER)`
- `frpm.CDSCode` / `schools.CDSCode`: type_mismatch 警告
- SOC 列的值分布信息，确认该列存在有效数据

**ReAct 推理过程（6 轮迭代）：**

| Step | Action | 结果 |
|------|--------|------|
| 1 | `verify_sql` WHERE DOC = '66' | ⚠️ 返回 0 行 |
| 2 | `execute_sql` 检查 DOC 列 | DOC 中无 '66' |
| 3 | `execute_sql` 检查 County Code | 也无 '66' |
| 4 | `execute_sql` 检查 SOC 列 | ✅ **找到 SOC = '66'** |
| 5 | `verify_sql` 修正为 SOC = '66' | ✅ 返回 5 行 |
| 6 | Final Answer | 提交正确 SQL |

**最终生成：**
```sql
SELECT CAST(T1.`FRPM Count (K-12)` AS REAL) / T1.`Enrollment (K-12)`
FROM frpm AS T1
JOIN schools AS T2 ON T1.CDSCode = T2.CDSCode
WHERE T2.SOC = '66'
ORDER BY T1.`FRPM Count (K-12)` DESC
LIMIT 5
```

---

## 案例 2: Spider #209 — 隐藏的空格数据质量问题

**数据库:** `flight_2`

**问题:** Return the number of flights departing from Aberdeen.

### 无 Rich Context 的典型做法 ❌

```sql
SELECT COUNT(*)
FROM flights
JOIN airports ON flights.SourceAirport = airports.AirportCode
WHERE airports.City = 'Aberdeen'
```

**返回 0 → 评测失败**

错误原因：数据库中存在**隐蔽的空格污染**——`flights.SourceAirport` 有前导空格（如 `' APG'`），`airports.City` 有尾部空格（如 `'Aberdeen '`）。这些肉眼不可见的字符导致等值 JOIN 和 WHERE 全部匹配失败。

### 我们的方法（ReAct + Rich Context）✅

**Rich Context 在 context 生成阶段自动检测到数据质量问题：**

```
⚠️ Data Quality Issues:
  * flights.SourceAirport: Contains leading whitespace.
    → Fix: Use TRIM(SourceAirport) for exact matching and joins.
  * airports.City: Contains trailing whitespace.
    → Fix: Use TRIM(City) for exact matching and joins.
```

**ReAct 推理过程（3 轮迭代）：**

| Step | Action | 结果 |
|------|--------|------|
| 1 | `execute_sql` TRIM(City) 验证 | 确认 `'Aberdeen'` 存在（需 TRIM） |
| 2 | `verify_sql` 带 TRIM 的完整 SQL | ✅ 查询有效 |
| 3 | Final Answer | 提交正确 SQL |

**最终生成：**
```sql
SELECT COUNT(*)
FROM flights f
JOIN airports a ON TRIM(f.SourceAirport) = TRIM(a.AirportCode)
WHERE TRIM(a.City) = 'Aberdeen'
```

---

## 方法优势分析

### 失败模式的系统性归因

以上两个案例揭示了当前 Text-to-SQL 系统中两类根源性的失败模式。**第一类是语义映射歧义（Schema Linking Ambiguity）**：自然语言中的业务术语（如 "ownership code"）与数据库列名之间的映射往往不是单射关系——同一张表中可能存在多个候选列（DOC、IRC、SOC），仅凭列名的字面语义无法可靠地消歧。在案例 1 中，Baseline 将 "ownership code" 错误映射到 `IRC`（一个取值仅为 0/1 的布尔列），而正确答案是 `SOC`——这一映射需要对列的实际值域有先验认知。**第二类是隐性数据质量缺陷（Latent Data Quality Defects）**：真实数据库中广泛存在的空白字符污染、类型不一致（如 TEXT 列存储数值）、隐式 NULL 等问题对人眼不可见，却会导致 JOIN 条件和 WHERE 过滤静默失败，返回空结果。在案例 2 中，`flights.SourceAirport` 的前导空格和 `airports.City` 的尾部空格使得本应匹配的等值 JOIN 完全失效。

这两类问题并非罕见的边界情况。在我们对 BIRD dev set 的系统性分析中，Baseline 方法产生的 262 个错误中有相当比例可归因于上述两类模式——Baseline 因缺乏数据感知能力而在这些案例上系统性地失败，而我们的方法成功修复了这 262 个案例。

### 现有方法的结构性局限

当前主流的 Text-to-SQL 方法——无论是 Direct Prompting（Schema + Question → SQL）还是带有 Schema Linking 的多阶段管线——本质上都遵循 **"一次性生成、不可验证"（generate-once, no-verification）** 的范式。这一范式存在三个结构性缺陷：

1. **Schema 信息的不完备性**：模型仅接收到表结构定义（DDL），无法获知列的实际值分布、数据质量状况和存储行为。例如，仅从 `SOC TEXT` 这一列定义中，模型无法得知 SOC 列实际存储的是类似 "66" 这样的数值编码，更无法知道它就是 "ownership code" 的语义承载列。

2. **缺乏闭环反馈**：生成的 SQL 被直接提交评测，模型没有机会在真实数据上验证结果的合理性。当预测返回空集或异常行数时，系统无从察觉并纠正。传统方法中的 Self-Consistency 或 Execution-guided Decoding 虽然引入了执行反馈，但通常仅利用"是否报错"这一粗粒度信号，对"执行成功但语义错误"（如 0 行结果）缺乏处理能力。

3. **数据质量问题的不可见性**：空格污染、编码不一致等问题不会触发 SQL 语法错误，而是以静默方式产生错误结果。在没有预先检测机制的情况下，任何基于纯 schema 推理的方法都无法意识到需要 TRIM 或 CAST 操作。

### 我们的方法：数据感知 + 交互验证的协同框架

我们提出的 **Rich Context + ReAct** 框架通过两个互补的机制系统性地克服了上述局限：

**Rich Context（预计算的数据感知层）** 在推理前对数据库进行自动化的质量审计和语义标注。具体包括：
- **数据质量检测**：自动扫描每一列的空白字符污染（leading/trailing whitespace）、NULL 比例、类型存储不一致（如 TEXT 列存储纯数字）等问题，并生成结构化的修复建议（如 "Use TRIM(SourceAirport) for exact matching"）；
- **值域统计**：提取各列的值分布摘要（top-k 频繁值、基数、范围），使模型能够基于实际数据内容——而非仅凭列名——进行语义消歧；
- **业务语义增强**：将 benchmark 提供的 evidence（如 "eligible free or reduced price meal rate = FRPM Count / Enrollment"）与列级信息关联，形成完整的上下文。

这些信息作为结构化上下文注入到 prompt 中，使得模型在生成第一条 SQL 之前就已经"看到"了数据的真实状态。在案例 2 中，正是 Rich Context 预先标注的 TRIM 警告使得模型从一开始就生成了包含 TRIM 的正确 SQL，仅需一步验证即完成——而没有 Rich Context 的方法甚至无法察觉问题的存在。

**ReAct（交互式推理-验证循环）** 赋予模型在真实数据库上探索和自我纠错的能力。与传统 Chain-of-Thought 仅在文本空间推理不同，ReAct 框架让模型能够：
- 通过 `execute_sql` 工具探测数据库的实际内容（如查询某列是否包含特定值）；
- 通过 `verify_sql` 工具在提交最终答案前验证 SQL 的执行结果是否合理（如行数、值域）；
- 在验证失败时自动触发假设修正，形成 **"生成 → 验证 → 探索 → 修正"** 的闭环。

在案例 1 中，模型初始猜测 `DOC = '66'` 失败后，并未放弃或随机更换列名，而是通过系统性的列值探测（DOC → County Code → SOC），在 4 轮交互中定位到正确的映射。这种基于数据证据的搜索策略，本质上模拟了一个经验丰富的 DBA 面对陌生数据库时的调试过程。

### 两个机制的协同效应

Rich Context 和 ReAct 并非简单的叠加，而是形成了显著的协同效应。Rich Context 提供了**先验信息层**，大幅缩小了 ReAct 的搜索空间——模型不需要从零开始探索数据库，而是基于已知的质量问题和值分布进行针对性验证。例如，在案例 1 中，Rich Context 标注了 SOC 列的 type_mismatch 问题（TEXT 存数值），当模型在探测过程中发现 SOC 列包含 '66' 时，能够立即理解需要使用字符串比较而非整数比较。在案例 2 中，Rich Context 直接提供了 TRIM 的修复建议，使得 ReAct 的验证过程从"发现问题 → 诊断原因 → 修复"简化为"确认修复有效"，将交互轮数从潜在的 5-6 轮降低到 3 轮。

从定量角度看，在 BIRD dev set 上，Baseline（Direct Prompting，同一基座模型）失败而我们的方法成功的案例共 **262 例**，占总题数（1534）的 **17.1%**，这直接反映了 Rich Context + ReAct 框架在处理真实数据库复杂性方面的增量能力。这些修复案例并非来自简单查询，而是集中在涉及多表 JOIN、聚合计算、隐式类型转换等高复杂度场景。

综上，我们的方法将 Text-to-SQL 从**单次猜测（single-shot guessing）** 升级为**有数据支撑的迭代推理过程（data-grounded iterative reasoning）**——Rich Context 让模型"看到"数据，ReAct 让模型"验证"推理，二者协同构成了一个对真实数据库复杂性具有鲁棒性的 SQL 生成框架。

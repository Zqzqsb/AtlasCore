## 案例: BIRD #689 — NULL 数据下的自适应探索 vs 盲目修复的崩溃

**数据库:** `codebase_community`  |  **难度:** simple

**问题:** Identify the display name and location of the user, who was the last to edit the post with ID 183.

**Evidence:** last to edit refers to MAX(LastEditDate);

**Gold SQL:**
```sql
SELECT T2.DisplayName, T2.Location
FROM posts AS T1
INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id
WHERE T1.Id = 183
ORDER BY T1.LastEditDate DESC LIMIT 1
```

**Gold Answer:** `Vitor De Mario`, `Rio de Janeiro`

**关键陷阱：** 帖子 #183 的 `LastEditorUserId` 和 `LastEditDate` 均为 **NULL**——该帖从未被编辑过。Gold SQL 实际上通过 `OwnerUserId`（帖子原始作者）来获取答案，绕过了 NULL 问题。任何试图使用 `LastEditorUserId` 进行 JOIN 的方法都会得到空结果。

---

### MAC-SQL（Decompose → Refine 管线）❌

**Decomposer 阶段**——思路本身是正确的：

```sql
-- Sub question 1: 获取帖子 183 的 LastEditorUserId
SELECT `LastEditorUserId` FROM posts WHERE `Id` = 183

-- Sub question 2: 用 LastEditorUserId JOIN users
SELECT `DisplayName`, `Location`
  FROM users
  WHERE `Id` = (SELECT `LastEditorUserId` FROM posts WHERE `Id` = 183)
```

→ **执行返回空结果**（因为 `LastEditorUserId` 是 NULL）

**Refiner 第 1 轮**——尝试加 NULL 检查和 JOIN 改写：

```sql
SELECT u.`DisplayName`, u.`Location`
FROM users u
JOIN posts p ON u.`Id` = p.`LastEditorUserId`
WHERE p.`Id` = 183 AND p.`LastEditDate` IS NOT NULL
ORDER BY p.`LastEditDate` DESC LIMIT 1;
```

→ **仍然返回空结果**（`LastEditDate` 也是 NULL）

**Refiner 第 2 轮**——尝试合并 postHistory 表：

```sql
SELECT u.`DisplayName`, u.`Location`
FROM users u
JOIN (
    SELECT `LastEditorUserId` AS UserId, `LastEditDate` AS EditDate
    FROM posts WHERE `Id` = 183 AND `LastEditDate` IS NOT NULL
    UNION ALL
    SELECT `UserId`, `CreationDate` AS EditDate
    FROM postHistory
    WHERE `PostId` = 183 AND `PostHistoryTypeId` = 5
) AS edits ON u.`Id` = edits.`UserId`
GROUP BY u.`Id`, u.`DisplayName`, u.`Location`
ORDER BY MAX(edits.`EditDate`) DESC LIMIT 1;
```

→ **仍然返回空结果**（`PostHistoryTypeId = 5` 猜错了——该帖的 postHistory 只有 type 1/2/3 即初始创建记录）

**Refiner 第 3 轮**——尝试 COALESCE 兜底：

```sql
SELECT u.`DisplayName`, u.`Location`
FROM users u
WHERE u.`Id` = (
    SELECT COALESCE(
        (SELECT `LastEditorUserId` FROM posts
         WHERE `Id` = 183 AND `LastEditDate` IS NOT NULL
         ORDER BY `LastEditDate` DESC LIMIT 1),
        (SELECT `UserId` FROM postHistory
         WHERE `PostId` = 183 ORDER BY `CreationDate` DESC LIMIT 1)
    )
) LIMIT 1;
```

→ **仍然返回空结果**（`LastEditDate IS NOT NULL` 过滤掉了帖子，第二个子查询中 postHistory 的 UserId 虽然存在但 COALESCE 逻辑实际上被第一个分支短路——因为该分支返回 NULL 而非"无行"，COALESCE(NULL, ...) 才能 fallback，但子查询在有结果行时返回的 NULL 和无结果行的处理不同，导致最终仍为 NULL）

**最终放弃原始意图，输出：**

```sql
SELECT COUNT(*) FROM posts WHERE `Id` = 183;
```

🔥 **完全答非所问**——问的是 display name 和 location，返回了 COUNT(*)。经过 3 轮 Refine，MAC-SQL 从一个语义正确但遇到 NULL 的查询，退化成了一个完全无关的计数查询。

---

### 我们的方法（ReAct + Rich Context）✅

**ReAct 推理过程（6 轮迭代）：**

| Step | Action | 输入 | 结果 |
|------|--------|------|------|
| 1 | `execute_sql` | `SELECT Id, LastEditorUserId, LastEditDate FROM posts WHERE Id = 183;` | ⚠️ LastEditorUserId=**NULL**, LastEditDate=**NULL** |
| 2 | `verify_sql` | 从 postHistory 查编辑记录（PostHistoryTypeId IN (4,5,6)） | ⚠️ 返回 **0 行**（无编辑记录） |
| 3 | `execute_sql` | `SELECT PostHistoryTypeId, UserId, CreationDate FROM postHistory WHERE PostId = 183 ORDER BY CreationDate DESC;` | 发现 3 条记录，全部是 type 1/2/3（Initial Title/Body/Tags），UserId=**166** |
| 4 | `execute_sql` | `SELECT OwnerUserId FROM posts WHERE Id = 183;` | OwnerUserId=**166** |
| 5 | `verify_sql` | `SELECT u.DisplayName, u.Location FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.Id = 183;` | ✅ 返回 1 行：**Vitor De Mario**, **Rio de Janeiro** |
| 6 | Final Answer | 提交上述 SQL | ✅ 正确 |

**关键推理链：**

> *"The post with ID 183 exists but has NULL values for both LastEditorUserId and LastEditDate. This means the post hasn't been edited yet... I should look at post history records instead."*
>
> → 查 postHistory，发现只有初始创建记录（type 1/2/3），没有编辑记录（type 4/5/6）
>
> *"Since there are no actual edits, but the question assumes there is a 'last editor', the most reasonable interpretation is to return the user who created the post (OwnerUserId)."*
>
> → 用 OwnerUserId JOIN users → 得到正确答案

**最终生成：**
```sql
SELECT u.DisplayName, u.Location
FROM posts p
JOIN users u ON p.OwnerUserId = u.Id
WHERE p.Id = 183;
```

---

### 对比分析

这个案例揭示了 **"盲目修复" vs "数据驱动探索"** 两种范式在遇到数据缺失（NULL）时的本质差异。

**MAC-SQL 的失败根因——无法观察数据，只能猜测修复方向：**

MAC-SQL 的 Refine 机制只知道"上一轮 SQL 返回了空结果"，但**无法观察到空结果的具体原因**。它不知道是 `LastEditorUserId` 为 NULL、还是 JOIN 条件写错了、还是 WHERE 过滤太严。因此每一轮 Refine 都在"盲猜"修复方向：第 1 轮加 NULL 检查（但检查的是 `LastEditDate` 而非 `LastEditorUserId`）、第 2 轮引入 `postHistory`（但猜错了 `PostHistoryTypeId`）、第 3 轮用 COALESCE 兜底（但 SQL 子查询的 NULL 语义导致逻辑不生效）。**三轮猜测全部失败后，系统彻底迷失，退化为完全无关的 `SELECT COUNT(*)`**。

**ReAct 的成功关键——每一步都有数据反馈驱动下一步决策：**

ReAct 的优势不在于"更聪明"，而在于**每一步探索都能看到真实数据**。第 1 步直接查 `LastEditorUserId`，看到 NULL 后立即知道此路不通；第 2 步查 postHistory 的编辑记录，0 行结果后立即知道没有编辑过；第 3 步放宽条件查所有 postHistory，看到 type 1/2/3 和 UserId=166 后，建立起"该帖只有初始创建、从未被编辑"的完整认知；第 4 步确认 OwnerUserId=166，第 5 步验证最终 SQL 返回正确结果。**每一步的数据反馈直接驱动了下一步的推理方向，形成了一条从"发现问题"到"诊断原因"到"合理 fallback"的完整推理链。**

这种差异并非个案。在真实数据库中，NULL 值、缺失记录、数据不一致等问题无处不在。**能否在遇到异常时基于真实数据证据进行自适应调整，而非盲目重试**，是决定 Text-to-SQL 系统鲁棒性的关键因素。

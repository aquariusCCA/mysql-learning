# 第八章_聚合函数

这一章开始把“单行数据怎么处理”推进到“多行数据怎么汇总、分组、筛选与排序”。重点不只是记住 `AVG()`、`SUM()`、`COUNT()` 这些函数名称，而是建立一套完整的聚合查询思维：

1. 什么是聚合函数？
2. 聚合函数如何处理 `NULL`？
3. 如何使用 `GROUP BY` 决定统计维度？
4. 如何使用 `HAVING` 筛选分组后的统计结果？
5. `SELECT` 查询在逻辑上到底按什么顺序处理？
6. 逻辑执行顺序和 MySQL 优化器的真实执行计划有什么差异？

目前这一章整理出 `4` 个小节，内容从聚合函数基础一路推进到 `GROUP BY`、`HAVING` 和 `SELECT` 的执行过程。适合按顺序学习，也适合在写统计查询、报表 SQL、分组分析或排查 SQL 错误时快速回查。

> 说明：本 README 对应新版笔记内容。如果你把 9.5 分版本文件覆盖回原本文件名，可以直接使用下面的链接；如果你保留了 `9.5分版本` 这类新文件名，请同步调整链接。

## 本章在整体学习地图中的位置

- 前七章已经建立了数据库概念、MySQL 环境、基础查询、运算符、排序分页、多表查询与单行函数。
- 这一章开始正式进入“多行数据汇总”的阶段，是从基础查询过渡到统计查询、报表查询、分组分析的关键节点。
- 如果这一章没有建立好，后面在写报表、分组统计、关联统计、筛选聚合结果或理解 SQL 执行顺序时会很容易混淆。
- 本章也是后续学习子查询、复杂查询、窗口函数、执行计划与 SQL 优化的重要基础。

## 本章学习目标

学完本章后，应该能够做到：

1. 看懂并正确使用 `AVG()`、`SUM()`、`MIN()`、`MAX()`、`COUNT()`。
2. 分清 `COUNT(*)`、`COUNT(1)`、`COUNT(列名)`、`COUNT(DISTINCT 列名)` 的差异。
3. 理解聚合函数通常会忽略 `NULL`，但 `COUNT(*)` 是统计行数，不受某个列是否为 `NULL` 影响。
4. 使用 `GROUP BY` 按单个字段或多个字段进行分组统计。
5. 理解 `SELECT` 中非聚合字段和 `GROUP BY` 字段之间的规则，尤其是 `ONLY_FULL_GROUP_BY`。
6. 正确区分 `WHERE` 和 `HAVING`：前者筛选原始行，后者筛选分组后的统计结果。
7. 看懂 `SELECT` 的书写顺序、逻辑执行顺序与真实执行计划之间的差异。
8. 理解 `LEFT JOIN` 中条件写在 `ON` 和写在 `WHERE` 的差异。
9. 写出结构清楚、可维护、较不容易出错的聚合查询 SQL。

## 建议阅读顺序

1. [1 聚合函数](./1%20聚合函数.md)
2. [2 GROUP BY](./2%20GROUP%20BY.md)
3. [3 HAVING](./3%20HAVING.md)
4. [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md)

建议不要跳过前两篇。`HAVING` 和 `SELECT` 执行过程都建立在聚合函数与分组查询的基础上，如果直接看后面两篇，容易只记住语法顺序，却不理解为什么 SQL 要这样写。

## 先读哪几篇不容易卡住

- 第一次进入本章时，先读 [1 聚合函数](./1%20聚合函数.md)，先建立“多行汇总”和“单行处理”的区别。
- 接着读 [2 GROUP BY](./2%20GROUP%20BY.md) 和 [3 HAVING](./3%20HAVING.md)，把“怎么分组”和“怎么筛选分组结果”连起来理解。
- 如果你常常分不清 SQL 是按什么顺序执行的，再读 [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md)，把 `FROM`、`WHERE`、`GROUP BY`、`HAVING`、`SELECT`、`ORDER BY`、`LIMIT` 的关系串起来。
- 如果你写 `LEFT JOIN` 聚合查询时经常出现结果少掉、`NULL` 被过滤掉、外连接变得像内连接的问题，优先回查 [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md) 中关于 `LEFT JOIN`、`ON`、`WHERE` 的内容。

## 本章小节

- [1 聚合函数](./1%20聚合函数.md)：建立聚合函数的概念，整理 `AVG()`、`SUM()`、`MIN()`、`MAX()`、`COUNT()` 的适用场景；补充没有 `GROUP BY` 时的隐含分组、聚合函数对 `NULL` 的处理、`DISTINCT` 聚合、`COUNT(*)` / `COUNT(1)` / `COUNT(列名)` / `COUNT(DISTINCT)` 的差异，以及 MyISAM 与 InnoDB 下 `COUNT` 的基本理解。

- [2 GROUP BY](./2%20GROUP%20BY.md)：整理分组查询的基本写法、单列分组、多列分组、`NULL` 分组、`WHERE` / `HAVING` / `ORDER BY` 与 `GROUP BY` 的关系；补充 `ONLY_FULL_GROUP_BY`、函数依赖、`ANY_VALUE()`、`WITH ROLLUP`、`GROUPING()` 与 `ROLLUP` 在不同 MySQL 版本中的注意点。

- [3 HAVING](./3%20HAVING.md)：整理如何对分组后的统计结果继续筛选，并系统对比 `WHERE` 与 `HAVING` 的执行阶段、可用条件、结果差异与效率原则；补充没有明确 `GROUP BY` 时的隐含聚合组、`HAVING` 中使用 `SELECT` 别名、常见错误与推荐写法。

- [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md)：从查询结构、子句职责、书写顺序、逻辑执行顺序一路整理到虚拟表演变；补充逻辑执行顺序与 MySQL 优化器真实执行计划的差异、别名可见范围、`ONLY_FULL_GROUP_BY`、`LEFT JOIN` 中 `ON` 与 `WHERE` 的差异、`DISTINCT` / `ORDER BY` / `LIMIT` 的关系，以及用 `EXPLAIN` 查看真实执行计划的观念。

## 本章核心观念总整理

### 1. 聚合函数是“多行输入，一行输出”

聚合函数会对一组数据做汇总计算，例如：

```sql
SELECT AVG(salary), SUM(salary), COUNT(*)
FROM employees;
```

如果没有写 `GROUP BY`，整个查询结果会被视为一个隐含的分组，因此最终通常只返回一行统计结果。

### 2. `COUNT(*)` 是统计行数，`COUNT(列名)` 是统计非 `NULL` 值

常见判断原则：

```sql
COUNT(*)                -- 统计行数，最适合表示“有几笔记录”
COUNT(1)                -- 统计常数 1，通常结果与 COUNT(*) 相同
COUNT(column_name)      -- 统计该列不为 NULL 的行数
COUNT(DISTINCT column)  -- 统计该列不重复且非 NULL 的值数量
```

实际开发中，如果目的是统计总行数，优先使用 `COUNT(*)`。

### 3. `GROUP BY` 决定统计维度

`GROUP BY` 不是单纯为了去重，而是决定“按照什么维度产生统计结果”。

```sql
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id;
```

这条 SQL 的含义是：每个部门产生一组统计结果。

### 4. 多列分组统计的是“字段组合”

```sql
SELECT department_id, job_id, SUM(salary)
FROM employees
GROUP BY department_id, job_id;
```

这不是分别按 `department_id` 和 `job_id` 各统计一次，而是按照 `(department_id, job_id)` 这个组合分组。

### 5. `WHERE` 和 `HAVING` 的分工不同

```sql
WHERE   -- 分组前，过滤原始数据行
HAVING  -- 分组后，过滤聚合统计结果
```

推荐思路：

- 普通行条件优先写在 `WHERE`。
- 聚合函数条件写在 `HAVING`。
- 能先过滤的数据，不要拖到分组后才过滤。

### 6. `SELECT` 的书写顺序不等于逻辑执行顺序

常见书写顺序：

```sql
SELECT ...
FROM ...
WHERE ...
GROUP BY ...
HAVING ...
ORDER BY ...
LIMIT ...;
```

常见逻辑执行顺序：

```text
FROM / JOIN / ON
-> WHERE
-> GROUP BY
-> 聚合函数
-> HAVING
-> SELECT
-> DISTINCT
-> ORDER BY
-> LIMIT
```

但要注意：这是帮助理解 SQL 的逻辑模型，不代表 MySQL 底层一定按照这个方式逐步物理执行。真实执行方式要看优化器和 `EXPLAIN`。

### 7. `LEFT JOIN` 的右表条件放错位置，会改变查询结果

在 `LEFT JOIN` 中：

- 连接匹配条件通常写在 `ON`。
- 如果把右表条件写在 `WHERE`，可能会把外连接补出来的 `NULL` 行过滤掉，使结果看起来像 `INNER JOIN`。

这在“查询所有客户及其订单统计”、“查询所有部门及员工人数”这类 SQL 中特别常见。

## 本章适合快速回查的主题

### 聚合函数相关

- 想确认聚合函数和单行函数的差别：看 [1 聚合函数](./1%20聚合函数.md)
- 忘记 `AVG()`、`SUM()`、`MIN()`、`MAX()`、`COUNT()` 各自适合什么场景：看 [1 聚合函数](./1%20聚合函数.md)
- 想确认聚合函数如何处理 `NULL`：看 [1 聚合函数](./1%20聚合函数.md)
- 想确认没有 `GROUP BY` 时聚合函数会怎样计算：看 [1 聚合函数](./1%20聚合函数.md)
- 想确认 `COUNT(*)`、`COUNT(1)`、`COUNT(列名)`、`COUNT(DISTINCT)` 的差异：看 [1 聚合函数](./1%20聚合函数.md)
- 想确认为什么 `COUNT(列名)` 不适合直接替代 `COUNT(*)`：看 [1 聚合函数](./1%20聚合函数.md)

### GROUP BY 相关

- 想确认 `GROUP BY` 的书写位置与基本规则：看 [2 GROUP BY](./2%20GROUP%20BY.md)
- 想比较单列分组和多列分组：看 [2 GROUP BY](./2%20GROUP%20BY.md)
- 想确认多列分组到底是“分别分组”还是“组合分组”：看 [2 GROUP BY](./2%20GROUP%20BY.md)
- 想确认 `GROUP BY` 如何处理 `NULL`：看 [2 GROUP BY](./2%20GROUP%20BY.md)
- 想确认 `SELECT` 中哪些字段必须写进 `GROUP BY`：看 [2 GROUP BY](./2%20GROUP%20BY.md)
- 想确认 `ONLY_FULL_GROUP_BY` 为什么会报错：看 [2 GROUP BY](./2%20GROUP%20BY.md)
- 想回查 `WITH ROLLUP` 的小计、总计列：看 [2 GROUP BY](./2%20GROUP%20BY.md)
- 想确认 `GROUPING()` 用来解决什么问题：看 [2 GROUP BY](./2%20GROUP%20BY.md)

### HAVING 相关

- 想确认为什么聚合函数不能写在 `WHERE` 中：看 [3 HAVING](./3%20HAVING.md)
- 想比较 `WHERE` 与 `HAVING` 的区别：看 [3 HAVING](./3%20HAVING.md)
- 想知道普通条件应该写在 `WHERE` 还是 `HAVING`：看 [3 HAVING](./3%20HAVING.md)
- 想确认聚合条件应该写在哪里：看 [3 HAVING](./3%20HAVING.md)
- 想确认 `HAVING` 是否一定要搭配 `GROUP BY`：看 [3 HAVING](./3%20HAVING.md)
- 想确认 `HAVING` 中能不能使用 `SELECT` 别名：看 [3 HAVING](./3%20HAVING.md)

### SELECT 执行过程相关

- 想回查 `SELECT` 的书写顺序和逻辑执行顺序：看 [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md)
- 想理解 `FROM`、`JOIN`、`ON`、`WHERE`、`GROUP BY`、`HAVING`、`ORDER BY` 的处理关系：看 [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md)
- 想理解为什么某些别名可以在 `ORDER BY` 使用，却不能在 `WHERE` 使用：看 [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md)
- 想确认 `LEFT JOIN` 中条件放在 `ON` 和 `WHERE` 的差异：看 [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md)
- 想理解虚拟表 `VT` 在多表连接或外连接中的演变：看 [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md)
- 想确认 `EXPLAIN` 是用来看真实执行计划，而不是逻辑顺序：看 [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md)

### 练习相关

- 想直接开始按难度练第八章：看 [第八章_聚合函数练习题](./練習題/第八章_聚合函数练习题.md)

## 哪几篇最常当速查页

- [1 聚合函数](./1%20聚合函数.md)：适合快速回查 `COUNT(*)`、`COUNT(列名)`、`COUNT(DISTINCT)`、`AVG()`、`SUM()`、`NULL` 处理等常用聚合函数问题。
- [2 GROUP BY](./2%20GROUP%20BY.md)：适合确认分组规则、分组字段、多列分组、`ONLY_FULL_GROUP_BY`、`WITH ROLLUP` 与 `GROUPING()`。
- [3 HAVING](./3%20HAVING.md)：适合快速区分 `WHERE` 和 `HAVING` 的写法、适用场景、效率原则与常见错误。
- [4 SELECT 的执行过程](./4%20SELECT%20的执行过程.md)：适合理解复杂查询为什么这样写，尤其是排查执行顺序、别名可见性、外连接条件位置与真实执行计划问题。

## 常用 SQL 模板

### 1. 基础聚合查询

```sql
SELECT
    COUNT(*) AS total_count,
    AVG(amount) AS avg_amount,
    SUM(amount) AS total_amount,
    MAX(amount) AS max_amount,
    MIN(amount) AS min_amount
FROM orders
WHERE status = 'SUCCESS';
```

### 2. 分组统计查询

```sql
SELECT
    group_column,
    COUNT(*) AS total_count,
    SUM(amount) AS total_amount
FROM table_name
WHERE 分组前条件
GROUP BY group_column;
```

### 3. 分组后筛选查询

```sql
SELECT
    group_column,
    COUNT(*) AS total_count,
    SUM(amount) AS total_amount
FROM table_name
WHERE 分组前条件
GROUP BY group_column
HAVING SUM(amount) > 10000;
```

### 4. 多列分组查询

```sql
SELECT
    department_id,
    job_id,
    COUNT(*) AS employee_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id, job_id;
```

### 5. LEFT JOIN 聚合查询

```sql
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_price) AS total_spent
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;
```

## 学习与练习建议

学习本章时，不建议只背语法。更好的练习方式是每看到一个 SQL，都问自己四个问题：

1. 原始数据来自哪几张表？
2. 哪些条件应该在分组前过滤？
3. 分组维度是什么？
4. 哪些条件必须等聚合结果出来后才能过滤？

建议练习顺序：

1. 先写不分组的聚合查询。
2. 再写单列 `GROUP BY`。
3. 再写多列 `GROUP BY`。
4. 再加入 `HAVING`。
5. 最后加入 `JOIN`、`LEFT JOIN`、`ORDER BY`、`LIMIT`。

当 SQL 变复杂时，不要一开始就从 `SELECT` 写起，可以先按逻辑拆解：

```text
先确定 FROM / JOIN
再确定 WHERE
再确定 GROUP BY
再确定聚合函数
再确定 HAVING
最后确定 SELECT / ORDER BY / LIMIT
```

这样比较不容易把条件放错位置。

## 本章最终掌握标准

如果你能独立回答下面这些问题，代表本章已经掌握得比较稳：

1. `COUNT(*)` 和 `COUNT(列名)` 差在哪里？
2. 为什么 `AVG(column)` 会受到 `NULL` 的影响？
3. 为什么聚合函数不能直接写在 `WHERE` 中？
4. `WHERE` 和 `HAVING` 的执行阶段有什么不同？
5. 多列 `GROUP BY a, b` 是什么意思？
6. `SELECT` 中为什么不能随便放非分组字段？
7. `ONLY_FULL_GROUP_BY` 主要是在限制什么？
8. `WITH ROLLUP` 会多产生什么结果？
9. 为什么 `LEFT JOIN` 的右表条件写在 `WHERE` 可能会让结果变少？
10. 逻辑执行顺序和 `EXPLAIN` 看到的真实执行计划有什么关系？

## 返回导航

- [回到 README](../../README.md)
- [上一章：第七章_单行函数](../第七章_单行函数/README.md)

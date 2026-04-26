# 2 GROUP BY

> - 所属章节：MySQL 基础篇 / 第 08 章 聚合函数

## 本节导读

本节介绍 `GROUP BY` 的基本用途：把查询结果按照一个或多个字段划分成若干组，再配合聚合函数对每一组数据做统计。

学习 `GROUP BY` 时，不只要记住语法位置，更要理解下面三个问题：

1. **为什么要分组**：因为我们通常不是只想统计整张表，而是想按部门、岗位、日期、客户等维度分别统计。
2. **分组后每一行代表什么**：分组前一行通常代表一笔原始记录；分组后一行通常代表一个分组的统计结果。
3. **`SELECT` 中能写哪些字段**：分组查询中，普通字段和聚合函数不能随便混用，否则会出现不确定结果或直接报错。

建议阅读顺序：

1. 先掌握 `GROUP BY` 的基本语法与书写位置。
2. 再理解 `SELECT` 列表与 `GROUP BY` 字段之间的约束关系。
3. 接着掌握单列分组、多列分组与 `NULL` 分组规则。
4. 最后复习 `WITH ROLLUP` 的用途、限制与 MySQL 版本差异。

## 前置知识

- 建议先读：[1 聚合函数](./1%20聚合函数.md)

## 关键字

`GROUP BY` `分组查询` `聚合函数` `分组字段` `多列分组` `ONLY_FULL_GROUP_BY` `函数依赖` `ANY_VALUE()` `WITH ROLLUP` `GROUPING()`

## 建议回查情境

- 想确认 `GROUP BY` 应该写在 SQL 语句哪个位置时。
- 忘记 `SELECT` 中哪些字段必须写进 `GROUP BY` 时。
- 想快速比较单列分组与多列分组的差异时。
- 不确定 `GROUP BY` 遇到 `NULL` 会怎么分组时。
- 写分组查询时遇到 `ONLY_FULL_GROUP_BY` 报错时。
- 需要回查 `WITH ROLLUP` 的用途、结果含义与版本限制时。

## 内容导航

- [2.1 GROUP BY 的核心概念](#21-group-by-的核心概念)
- [2.2 基本语法与书写位置](#22-基本语法与书写位置)
- [2.3 单列分组](#23-单列分组)
- [2.4 SELECT 字段与 GROUP BY 字段的关系](#24-select-字段与-group-by-字段的关系)
- [2.5 多列分组](#25-多列分组)
- [2.6 GROUP BY 与 NULL](#26-group-by-与-null)
- [2.7 GROUP BY 与 WHERE、HAVING、ORDER BY 的关系](#27-group-by-与-wherehavingorder-by-的关系)
- [2.8 GROUP BY 中使用 WITH ROLLUP](#28-group-by-中使用-with-rollup)
- [2.9 常见错误与推荐写法](#29-常见错误与推荐写法)
- [2.10 速查总结](#210-速查总结)

## 2.1 GROUP BY 的核心概念

`GROUP BY` 用来把查询出来的数据按照指定字段分成若干组，再对每一组分别执行聚合计算。

没有 `GROUP BY` 时，聚合函数通常会把整个查询结果当成一组：

```sql
SELECT AVG(salary)
FROM employees;
```

这条 SQL 的含义是：统计所有员工的平均工资，最终通常只返回一行结果。

有 `GROUP BY` 时，聚合函数会对每个分组分别计算：

```sql
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id;
```

这条 SQL 的含义是：先按照 `department_id` 分组，再统计每个部门的平均工资。最终通常是每个部门返回一行结果。

可以把 `GROUP BY` 理解成下面这个过程：

```text
原始记录
  ↓
按照指定字段分组
  ↓
每组各自执行聚合函数
  ↓
每组产生一行统计结果
```

## 2.2 基本语法与书写位置

`GROUP BY` 的基本语法如下：

```sql
SELECT
    分组字段,
    聚合函数(字段)
FROM 表名
WHERE 分组前过滤条件
GROUP BY 分组字段
HAVING 分组后过滤条件
ORDER BY 排序字段
LIMIT 返回笔数;
```

完整的书写顺序可以先记成：

```text
SELECT -> FROM -> WHERE -> GROUP BY -> HAVING -> ORDER BY -> LIMIT
```

其中，`GROUP BY` 的位置是：

- 在 `WHERE` 后面。
- 在 `HAVING` 前面。
- 在 `ORDER BY` 前面。
- 在 `LIMIT` 前面。

示例：

```sql
SELECT department_id, AVG(salary)
FROM employees
WHERE salary > 3000
GROUP BY department_id
HAVING AVG(salary) > 6000
ORDER BY AVG(salary) DESC;
```

这条 SQL 的含义是：

1. 先从 `employees` 表取数据。
2. 先用 `WHERE salary > 3000` 排除工资小于等于 3000 的员工。
3. 再按照 `department_id` 分组。
4. 对每个部门计算平均工资。
5. 再用 `HAVING AVG(salary) > 6000` 保留平均工资大于 6000 的部门。
6. 最后按照平均工资降序排序。

## 2.3 单列分组

单列分组指的是只按照一个字段分组。

```sql
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id;
```

执行逻辑：

```text
按照 department_id 分组
每个 department_id 形成一个分组
每个分组各自计算 AVG(salary)
```

示意结果：

| department_id | AVG(salary) |
| --- | --- |
| 10 | 4400.00 |
| 20 | 9500.00 |
| 30 | 4150.00 |
| 50 | 3475.56 |

上面的每一行都不再代表某一个员工，而是代表某一个部门的平均工资。

如果只想看每组的统计值，也可以不把分组字段写在 `SELECT` 中：

```sql
SELECT AVG(salary)
FROM employees
GROUP BY department_id;
```

这条 SQL 是合法的，但可读性较差。因为结果只会显示多个平均工资，却看不出每个平均工资对应哪个部门。

实务上更推荐写成：

```sql
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id;
```

## 2.4 SELECT 字段与 GROUP BY 字段的关系

这是 `GROUP BY` 最容易出错的地方。

### 2.4.1 推荐先记住的规则

初学阶段可以先记住一句话：

> 在分组查询中，`SELECT` 中出现的普通字段，通常应该写进 `GROUP BY`；没有写进 `GROUP BY` 的字段，应该放进聚合函数中。

推荐写法：

```sql
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id;
```

原因是：

- `department_id` 是分组字段，所以可以直接出现在 `SELECT` 中。
- `salary` 不是分组字段，所以不能直接显示单个 `salary`，而是要通过 `AVG(salary)` 这类聚合函数汇总。

### 2.4.2 错误或不推荐的写法

```sql
SELECT department_id, employee_name, AVG(salary)
FROM employees
GROUP BY department_id;
```

这条 SQL 的问题是：

- 查询按照 `department_id` 分组。
- 一个部门中可能有很多员工。
- 每组只会产生一行结果。
- 但 `employee_name` 不是分组字段，也不是聚合结果。
- 数据库无法确定应该从该部门中取哪一个员工姓名。

如果开启 `ONLY_FULL_GROUP_BY`，这种写法通常会直接报错。

如果关闭 `ONLY_FULL_GROUP_BY`，MySQL 可能允许这种写法，但会从每组中任意取一个 `employee_name`，结果具有不确定性，不建议依赖。

### 2.4.3 更精确的规则：ONLY_FULL_GROUP_BY 与函数依赖

MySQL 默认通常会开启 `ONLY_FULL_GROUP_BY` 模式。在这个模式下，`SELECT`、`HAVING` 或 `ORDER BY` 中引用的非聚合字段，必须满足下面任一条件：

1. 字段出现在 `GROUP BY` 中。
2. 字段可以由 `GROUP BY` 字段唯一决定，也就是存在函数依赖。
3. 字段被聚合函数包住，例如 `MAX(column)`、`MIN(column)`、`COUNT(column)`。
4. 明确使用 `ANY_VALUE(column)` 表示接受任意值。

例如：

```sql
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id;
```

这是合法且推荐的写法。

如果 `department_id` 不是唯一字段，下面这种写法通常不推荐：

```sql
SELECT department_id, employee_name, AVG(salary)
FROM employees
GROUP BY department_id;
```

因为 `employee_name` 不能由 `department_id` 唯一决定。

但如果按照主键分组，例如：

```sql
SELECT employee_id, employee_name, salary
FROM employees
GROUP BY employee_id;
```

如果 `employee_id` 是主键，那么 `employee_name` 和 `salary` 都可以由 `employee_id` 唯一决定，因此在 MySQL 的函数依赖判断下可能是合法的。

不过初学和实务报表中，仍建议优先写成规则清楚的版本：

```sql
SELECT employee_id, employee_name, salary
FROM employees;
```

如果没有聚合需求，就不需要硬加 `GROUP BY`。

### 2.4.4 ANY_VALUE() 的用途

如果你明确知道某个非分组字段在每组中虽然没有写进 `GROUP BY`，但取任意值都可以，可以使用 `ANY_VALUE()` 表达这个意图。

```sql
SELECT
    department_id,
    ANY_VALUE(employee_name) AS sample_employee_name,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id;
```

这条 SQL 的含义是：

- 按部门分组。
- 每个部门计算平均工资。
- 每个部门随便取一个员工姓名当作示例。

但要注意：`ANY_VALUE()` 不是用来找最大、最小、最新或最早的那一笔数据，它只是告诉 MySQL：这个字段从组内任意取一个值即可。

如果你想找每个部门最高薪员工，不能用 `ANY_VALUE()` 随便取，应该改用子查询、窗口函数或连接查询。

## 2.5 多列分组

多列分组指的是按照多个字段共同决定分组。

```sql
SELECT
    department_id,
    job_id,
    SUM(salary) AS total_salary
FROM employees
GROUP BY department_id, job_id;
```

这条 SQL 的含义是：

```text
按照 department_id + job_id 的组合分组
每一种组合形成一个分组
每个分组分别计算 SUM(salary)
```

示意结果：

| department_id | job_id | total_salary |
| --- | --- | --- |
| 30 | PU_CLERK | 13900 |
| 50 | ST_CLERK | 55700 |
| 50 | ST_MAN | 36400 |
| 80 | SA_REP | 243500 |

需要注意的是，多列分组不是简单理解成「先按第一个字段分组，再按第二个字段分组」就结束，而是要理解成：

> `GROUP BY department_id, job_id` 会把 `department_id` 和 `job_id` 的每一种组合当成一个分组键。

例如：

```text
department_id = 50 且 job_id = ST_CLERK 是一组
部门 50 且 job_id = ST_MAN 是另一组
部门 80 且 job_id = SA_REP 又是另一组
```

### 多列分组的字段顺序

从「分组结果」来看：

```sql
GROUP BY department_id, job_id
```

和：

```sql
GROUP BY job_id, department_id
```

在大多数普通统计场景下，分组组合本身相同，只是表达顺序不同。

但字段顺序仍然可能影响：

- 结果阅读习惯。
- `WITH ROLLUP` 产生汇总层级的顺序。
- 是否能有效利用某些索引。
- 执行计划与排序方式。

因此实务上建议把「较大的分类维度」放前面，把「较细的分类维度」放后面，例如：

```sql
GROUP BY department_id, job_id
```

这比下面写法更符合阅读习惯：

```sql
GROUP BY job_id, department_id
```

因为通常我们会先看部门，再看部门中的岗位。

## 2.6 GROUP BY 与 NULL

`GROUP BY` 会把 `NULL` 当成一个可分组的值处理。

如果多笔记录的 `department_id` 都是 `NULL`，它们会被分到同一组。

```sql
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id;
```

如果存在 `department_id IS NULL` 的员工，结果中可能出现：

| department_id | COUNT(*) |
| --- | --- |
| NULL | 3 |
| 10 | 1 |
| 20 | 2 |

如果不想统计 `NULL` 分组，可以先用 `WHERE` 排除：

```sql
SELECT department_id, COUNT(*)
FROM employees
WHERE department_id IS NOT NULL
GROUP BY department_id;
```

如果想把 `NULL` 显示成更容易理解的文字，可以使用 `IFNULL()` 或 `COALESCE()`：

```sql
SELECT
    IFNULL(CAST(department_id AS CHAR), '未分配部门') AS department_name,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id;
```

## 2.7 GROUP BY 与 WHERE、HAVING、ORDER BY 的关系

### 2.7.1 GROUP BY 与 WHERE

`WHERE` 用来过滤分组前的原始记录。

```sql
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
WHERE salary > 3000
GROUP BY department_id;
```

这条 SQL 的含义是：

1. 先排除工资小于等于 3000 的员工。
2. 再按照部门分组。
3. 最后计算每个部门剩余员工的平均工资。

注意：被 `WHERE` 排除的记录，不会参与后续分组和聚合计算。

### 2.7.2 GROUP BY 与 HAVING

`HAVING` 用来过滤分组后的统计结果。

```sql
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 6000;
```

这条 SQL 的含义是：

1. 先按照部门分组。
2. 计算每个部门的平均工资。
3. 只保留平均工资大于 6000 的部门。

聚合函数条件通常不能写在 `WHERE` 中：

```sql
-- 错误示例
SELECT department_id, AVG(salary)
FROM employees
WHERE AVG(salary) > 6000
GROUP BY department_id;
```

原因是 `WHERE` 执行时还没有完成分组，也还没有计算出 `AVG(salary)`。

### 2.7.3 WHERE 与 HAVING 可以同时使用

```sql
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
WHERE salary > 3000
GROUP BY department_id
HAVING AVG(salary) > 6000;
```

这条 SQL 的执行逻辑是：

```text
先用 WHERE 过滤员工记录
再用 GROUP BY 按部门分组
再用 HAVING 过滤分组后的平均工资
```

实务原则：

- 普通行条件优先放 `WHERE`。
- 聚合结果条件放 `HAVING`。
- 能在 `WHERE` 先过滤的数据，不要拖到 `HAVING` 才过滤。

### 2.7.4 GROUP BY 与 ORDER BY

`GROUP BY` 是分组，`ORDER BY` 是排序，两者职责不同。

```sql
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
ORDER BY avg_salary DESC;
```

这条 SQL 的含义是：

1. 先按照部门分组。
2. 计算每个部门的平均工资。
3. 再按照平均工资从高到低排序。

需要注意：不要依赖 `GROUP BY` 的结果自然排序。

如果你需要稳定排序，应该明确写 `ORDER BY`：

```sql
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
ORDER BY department_id;
```

## 2.8 GROUP BY 中使用 WITH ROLLUP

`WITH ROLLUP` 是 `GROUP BY` 的修饰语，用来在普通分组统计结果之外，额外产生更高层级的汇总行。

### 2.8.1 单列 ROLLUP

```sql
SELECT
    department_id,
    SUM(salary) AS total_salary
FROM employees
GROUP BY department_id WITH ROLLUP;
```

普通 `GROUP BY` 只会得到每个部门的工资总和。

加上 `WITH ROLLUP` 后，会额外增加一行总计，表示所有部门的工资总和。

示意结果：

| department_id | total_salary |
| --- | --- |
| 10 | 4400 |
| 20 | 19000 |
| 30 | 24900 |
| NULL | 48300 |

这里最后一行的 `department_id = NULL` 代表汇总行，不一定代表真实的 `department_id IS NULL`。

### 2.8.2 多列 ROLLUP

```sql
SELECT
    department_id,
    job_id,
    SUM(salary) AS total_salary
FROM employees
GROUP BY department_id, job_id WITH ROLLUP;
```

如果使用多列分组，`ROLLUP` 会按照分组字段顺序产生多层汇总。

示意结果：

| department_id | job_id | total_salary | 含义 |
| --- | --- | --- | --- |
| 50 | ST_CLERK | 55700 | 部门 50 中 ST_CLERK 的工资总和 |
| 50 | ST_MAN | 36400 | 部门 50 中 ST_MAN 的工资总和 |
| 50 | NULL | 92100 | 部门 50 的工资总和 |
| 80 | SA_REP | 243500 | 部门 80 中 SA_REP 的工资总和 |
| 80 | NULL | 243500 | 部门 80 的工资总和 |
| NULL | NULL | 335600 | 全部部门的工资总和 |

对于：

```sql
GROUP BY department_id, job_id WITH ROLLUP
```

汇总层级可以理解成：

```text
department_id + job_id 明细层
 department_id 小计层
 全表总计层
```

所以多列 `ROLLUP` 中，`GROUP BY` 字段顺序非常重要。

### 2.8.3 ROLLUP 中的 NULL 问题

`ROLLUP` 产生的汇总行会用 `NULL` 表示「全部值」。这会带来一个问题：

> 结果中的 `NULL` 到底是真实数据中的 `NULL`，还是 `ROLLUP` 产生的汇总行？

MySQL 可以使用 `GROUPING()` 区分这两种情况。

```sql
SELECT
    department_id,
    GROUPING(department_id) AS is_total,
    SUM(salary) AS total_salary
FROM employees
GROUP BY department_id WITH ROLLUP;
```

`GROUPING(department_id)` 的含义是：

- 返回 `0`：表示这是普通分组行。
- 返回 `1`：表示这是 `ROLLUP` 产生的汇总行。

也可以配合 `IF()` 把汇总行显示成更清楚的文字：

```sql
SELECT
    IF(GROUPING(department_id) = 1, '总计', CAST(department_id AS CHAR)) AS department_group,
    SUM(salary) AS total_salary
FROM employees
GROUP BY department_id WITH ROLLUP;
```

### 2.8.4 ROLLUP 与 ORDER BY 的版本差异

旧版教材或笔记中常会说：

> `WITH ROLLUP` 不能和 `ORDER BY` 一起使用。

这句话要加上版本条件。

在 MySQL 8.0.12 之前，`GROUP BY ... WITH ROLLUP` 不能和 `ORDER BY` 同时使用。

从 MySQL 8.0.12 开始，`ROLLUP` 可以搭配 `ORDER BY` 使用，也可以配合 `GROUPING()` 控制汇总行排序。

因此更精确的记法是：

> 如果使用的是较新的 MySQL 8.0 版本，`ROLLUP` 可以和 `ORDER BY` 搭配；如果使用旧版 MySQL 或旧教材，要注意两者可能被视为互斥。

## 2.9 常见错误与推荐写法

### 错误 1：SELECT 中随便放非分组字段

错误或不推荐：

```sql
SELECT department_id, employee_name, COUNT(*)
FROM employees
GROUP BY department_id;
```

问题：一个部门可能有多个员工，数据库无法确定应该显示哪一个 `employee_name`。

推荐：

```sql
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id;
```

如果真的要显示员工姓名，需要重新明确需求，例如「每个部门员工列表」、「每个部门最高薪员工」或「每个部门任意一个示例员工」。不同需求对应不同 SQL。

### 错误 2：把聚合条件写在 WHERE

错误：

```sql
SELECT department_id, AVG(salary)
FROM employees
WHERE AVG(salary) > 6000
GROUP BY department_id;
```

推荐：

```sql
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 6000;
```

### 错误 3：GROUP BY 之后以为结果一定有排序

不推荐依赖自然顺序：

```sql
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id;
```

如果需要按照部门编号排序，应该明确写：

```sql
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
ORDER BY department_id;
```

如果需要按照人数排序，应该写：

```sql
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
ORDER BY employee_count DESC;
```

### 错误 4：用 GROUP BY 去重但没有聚合需求

有些人会这样写：

```sql
SELECT department_id
FROM employees
GROUP BY department_id;
```

这条 SQL 可以得到不重复的 `department_id`，但如果只是想去重，语义上更推荐：

```sql
SELECT DISTINCT department_id
FROM employees;
```

`GROUP BY` 更适合用于「分组后统计」，`DISTINCT` 更适合用于「单纯去重」。

### 错误 5：误解多列分组

```sql
SELECT department_id, job_id, COUNT(*)
FROM employees
GROUP BY department_id, job_id;
```

这不是分别统计每个部门和每个岗位，而是统计每个「部门 + 岗位」组合。

如果你想分别统计每个部门人数和每个岗位人数，应该写两条 SQL，或使用其他报表设计方式。

## 2.10 速查总结

### 2.10.1 GROUP BY 的核心作用

| 问题 | 说明 |
| --- | --- |
| `GROUP BY` 是什么 | 按指定字段把数据分成若干组 |
| 常搭配什么使用 | 聚合函数，例如 `COUNT()`、`SUM()`、`AVG()`、`MAX()`、`MIN()` |
| 没有 `GROUP BY` 时 | 聚合函数通常把整个查询结果当成一组 |
| 有 `GROUP BY` 时 | 聚合函数会对每个分组分别计算 |

### 2.10.2 SELECT 与 GROUP BY 的关系

| `SELECT` 中的内容 | 是否通常允许 | 说明 |
| --- | --- | --- |
| 分组字段 | 允许 | 例如 `department_id` |
| 聚合函数 | 允许 | 例如 `AVG(salary)` |
| 非分组、非聚合字段 | 通常不允许或不推荐 | 可能违反 `ONLY_FULL_GROUP_BY`，或导致不确定结果 |
| 能被分组字段唯一决定的字段 | 可能允许 | 依赖 MySQL 的函数依赖判断 |
| `ANY_VALUE(column)` | 允许 | 表示接受组内任意值 |

### 2.10.3 WHERE、GROUP BY、HAVING 的分工

| 子句 | 作用阶段 | 是否能使用聚合函数条件 | 示例 |
| --- | --- | --- | --- |
| `WHERE` | 分组前 | 通常不能 | `WHERE salary > 3000` |
| `GROUP BY` | 分组阶段 | 不负责过滤 | `GROUP BY department_id` |
| `HAVING` | 分组后 | 可以 | `HAVING AVG(salary) > 6000` |

### 2.10.4 单列分组与多列分组

| 类型 | 示例 | 分组依据 |
| --- | --- | --- |
| 单列分组 | `GROUP BY department_id` | 每个部门一组 |
| 多列分组 | `GROUP BY department_id, job_id` | 每个「部门 + 岗位」组合一组 |

### 2.10.5 WITH ROLLUP

| 用法 | 作用 |
| --- | --- |
| `GROUP BY department_id WITH ROLLUP` | 统计每个部门，并额外产生总计行 |
| `GROUP BY department_id, job_id WITH ROLLUP` | 统计明细组合、部门小计、全表总计 |
| `GROUPING(column)` | 判断某个 `NULL` 是否为 `ROLLUP` 汇总行产生 |

### 2.10.6 推荐模板

```sql
SELECT
    分组字段,
    聚合函数(统计字段) AS 统计别名
FROM 表名
WHERE 分组前过滤条件
GROUP BY 分组字段
HAVING 分组后过滤条件
ORDER BY 排序字段;
```

例如：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count,
    AVG(salary) AS avg_salary,
    MAX(salary) AS max_salary
FROM employees
WHERE department_id IS NOT NULL
GROUP BY department_id
HAVING AVG(salary) > 6000
ORDER BY avg_salary DESC;
```

这条 SQL 是一个典型的分组统计查询：

1. 先排除没有部门的员工。
2. 再按部门分组。
3. 每个部门统计人数、平均工资、最高工资。
4. 只保留平均工资大于 6000 的部门。
5. 最后按照平均工资从高到低排序。

## 本节结论

- `GROUP BY` 用来把数据按照一个或多个字段分组。
- 分组后，聚合函数会对每个分组分别计算。
- `SELECT` 中的普通字段通常应该出现在 `GROUP BY` 中；否则要放入聚合函数，或确保它能被分组字段唯一决定。
- `WHERE` 负责分组前过滤，`HAVING` 负责分组后过滤。
- 多列分组是按照多个字段的组合分组，不是分别独立统计每个字段。
- `GROUP BY` 不等于排序；需要稳定顺序时，要明确写 `ORDER BY`。
- `WITH ROLLUP` 可以产生小计与总计行，多列分组时字段顺序会影响汇总层级。
- 在较新的 MySQL 8.0 版本中，`ROLLUP` 可以搭配 `ORDER BY` 使用；旧版教材中的互斥说法需要加上版本条件。

---
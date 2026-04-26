# 3 HAVING

> - 所属章节：MySQL 基础篇 / 第 08 章 聚合函数

## 本节导读

本节说明 `HAVING` 的用途：**对分组后的结果进行筛选**。

学习 `HAVING` 时，不要把它理解成 `WHERE` 的替代品。更准确地说：

- `WHERE` 负责在分组前筛选「原始数据行」。
- `GROUP BY` 负责把筛选后的数据按指定字段分组。
- 聚合函数负责对每一组数据做统计。
- `HAVING` 负责在分组和聚合之后，筛选符合条件的「分组结果」。

也就是说，`HAVING` 处理的对象不是单笔记录，而是已经分组后的统计结果。

建议阅读顺序：

1. 先理解 `HAVING` 为什么是「分组后过滤」。
2. 再比较 `WHERE` 与 `HAVING` 的执行阶段和适用条件。
3. 接着掌握 `HAVING` 中可以写哪些条件。
4. 最后复习常见错误、推荐写法，以及 MySQL 对 `HAVING` 的一些扩展特性。

## 前置知识

- 建议先读：[1 聚合函数](./1%20聚合函数.md)
- 建议先读：[2 GROUP BY](./2%20GROUP%20BY.md)

## 关键字

`HAVING` `WHERE` `GROUP BY` `分组过滤` `聚合函数` `聚合条件` `隐式单组` `SELECT 别名`

## 建议回查情境

- 想确认为什么聚合函数不能写在 `WHERE` 中时。
- 忘记 `HAVING` 和 `WHERE` 分别作用在哪个阶段时。
- 想判断某个筛选条件应该写在 `WHERE` 还是 `HAVING` 时。
- 想筛选 `COUNT()`、`SUM()`、`AVG()`、`MAX()`、`MIN()` 的统计结果时。
- 想确认没有 `GROUP BY` 时，`HAVING` 是否还能使用时。
- 想确认 MySQL 中 `HAVING` 能不能使用 `SELECT` 别名时。

## 内容导航

- [3.1 一句话理解 HAVING](#31-一句话理解-having)
- [3.2 HAVING 的基本语法](#32-having-的基本语法)
- [3.3 HAVING 的执行位置](#33-having-的执行位置)
- [3.4 HAVING 和 WHERE 的核心差异](#34-having-和-where-的核心差异)
- [3.5 HAVING 可以写哪些条件](#35-having-可以写哪些条件)
- [3.6 HAVING 的常见写法](#36-having-的常见写法)
- [3.7 没有 GROUP BY 时能不能使用 HAVING](#37-没有-group-by-时能不能使用-having)
- [3.8 HAVING 中使用 SELECT 别名](#38-having-中使用-select-别名)
- [3.9 WHERE 和 HAVING 的效率与选择原则](#39-where-和-having-的效率与选择原则)
- [3.10 常见错误](#310-常见错误)
- [3.11 开发中的推荐写法](#311-开发中的推荐写法)
- [3.12 速查表](#312-速查表)
- [3.13 结论](#313-结论)

---

## 3.1 一句话理解 HAVING

`HAVING` 用来筛选**分组后的统计结果**。

可以把聚合查询理解成下面这条流程：

```text
原始数据
    ↓
WHERE 先过滤不需要参与统计的行
    ↓
GROUP BY 分组
    ↓
聚合函数对每一组做统计
    ↓
HAVING 筛选符合条件的分组
    ↓
SELECT 显示最终结果
```

例如：

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 8000;
```

这条 SQL 的意思是：

1. 先按照 `department_id` 分组。
2. 对每个部门计算平均薪资。
3. 只显示平均薪资大于 `8000` 的部门。

重点是：`HAVING AVG(salary) > 8000` 不是在判断单个员工的薪资，而是在判断「每个部门的平均薪资」。

---

## 3.2 HAVING 的基本语法

`HAVING` 通常出现在 `GROUP BY` 后面，用来筛选分组后的结果。

标准结构如下：

```sql
SELECT
    分组字段,
    聚合函数
FROM 表名
WHERE 分组前条件
GROUP BY 分组字段
HAVING 分组后条件
ORDER BY 排序字段;
```

例如，查询最高薪资大于 `10000` 的部门：

```sql
SELECT
    department_id,
    MAX(salary) AS max_salary
FROM employees
GROUP BY department_id
HAVING MAX(salary) > 10000;
```

执行逻辑可以理解成：

1. 先按 `department_id` 分组。
2. 每个部门计算 `MAX(salary)`。
3. 只保留最高薪资大于 `10000` 的部门。

---

## 3.3 HAVING 的执行位置

在常见的 `SELECT` 查询中，可以先用下面的逻辑顺序理解：

```text
FROM
    ↓
WHERE
    ↓
GROUP BY
    ↓
HAVING
    ↓
SELECT
    ↓
ORDER BY
    ↓
LIMIT
```

所以：

- `WHERE` 比 `GROUP BY` 早执行。
- `HAVING` 比 `GROUP BY` 晚执行。
- 聚合函数的结果是在分组后才产生的。
- 因此，筛选聚合函数结果时，应该使用 `HAVING`，不能使用 `WHERE`。

错误写法：

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
WHERE AVG(salary) > 8000
GROUP BY department_id;
```

错误原因：

- `WHERE` 执行时还没有分组。
- `AVG(salary)` 的结果还没有产生。
- 所以 `WHERE` 不能使用聚合函数作为筛选条件。

正确写法：

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 8000;
```

---

## 3.4 HAVING 和 WHERE 的核心差异

### 3.4.1 WHERE：分组前过滤原始数据行

`WHERE` 处理的是表中的原始记录。

例如：

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
WHERE salary > 5000
GROUP BY department_id;
```

这条 SQL 的意思是：

1. 先筛选出 `salary > 5000` 的员工。
2. 再按照 `department_id` 分组。
3. 最后计算每个部门中「薪资大于 5000 的员工」的平均薪资。

也就是说，`WHERE` 会影响哪些数据参与后续分组和统计。

### 3.4.2 HAVING：分组后过滤统计结果

`HAVING` 处理的是分组后的结果。

例如：

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 5000;
```

这条 SQL 的意思是：

1. 先把所有员工按部门分组。
2. 计算每个部门所有员工的平均薪资。
3. 只显示平均薪资大于 `5000` 的部门。

### 3.4.3 同样是 `salary > 5000`，位置不同，意义不同

下面两条 SQL 的意义不同。

写在 `WHERE`：

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
WHERE salary > 5000
GROUP BY department_id;
```

意思是：只拿薪资大于 `5000` 的员工参与平均薪资计算。

写在 `HAVING`：

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 5000;
```

意思是：先计算每个部门所有员工的平均薪资，再筛选平均薪资大于 `5000` 的部门。

---

## 3.5 HAVING 可以写哪些条件

`HAVING` 常见可以使用下面几类条件。

### 3.5.1 聚合函数条件

这是 `HAVING` 最典型的用途。

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) >= 5;
```

意思是：查询员工人数大于等于 `5` 的部门。

常见聚合条件包括：

```sql
HAVING COUNT(*) > 10
HAVING SUM(amount) > 100000
HAVING AVG(score) >= 80
HAVING MAX(salary) > 10000
HAVING MIN(hire_date) < '2020-01-01'
```

### 3.5.2 分组字段条件

`HAVING` 也可以筛选分组字段。

例如：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING department_id IS NOT NULL;
```

这条 SQL 可以执行，但如果只是过滤原始数据中的 `department_id IS NOT NULL`，更推荐写在 `WHERE`：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
WHERE department_id IS NOT NULL
GROUP BY department_id;
```

原因是：

- `WHERE` 可以在分组前先减少参与统计的数据量。
- `HAVING` 更适合处理分组后的聚合条件。
- 普通行条件优先写在 `WHERE`，聚合条件才写在 `HAVING`。

### 3.5.3 多个聚合条件

`HAVING` 可以搭配 `AND`、`OR` 使用多个条件。

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING COUNT(*) >= 5
   AND AVG(salary) > 8000;
```

意思是：查询员工人数至少 `5` 人，并且平均薪资大于 `8000` 的部门。

---

## 3.6 HAVING 的常见写法

### 写法 1：筛选人数达到指定数量的分组

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) >= 3;
```

适合场景：

- 查询员工人数超过指定数量的部门。
- 查询订单数超过指定数量的客户。
- 查询发文数超过指定数量的作者。

### 写法 2：筛选总金额达到门槛的分组

```sql
SELECT
    customer_id,
    SUM(total_price) AS total_spent
FROM orders
GROUP BY customer_id
HAVING SUM(total_price) > 10000;
```

适合场景：

- 查询累计消费超过指定金额的客户。
- 查询销售额超过目标值的业务员。
- 查询库存总量低于安全库存的商品分类。

### 写法 3：筛选平均值达到门槛的分组

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 8000;
```

适合场景：

- 查询平均薪资超过指定金额的部门。
- 查询平均分数超过指定分数的班级。
- 查询平均订单金额超过指定金额的客户。

### 写法 4：WHERE 和 HAVING 搭配使用

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count,
    AVG(salary) AS avg_salary
FROM employees
WHERE department_id IS NOT NULL
  AND salary > 0
GROUP BY department_id
HAVING COUNT(*) >= 3
   AND AVG(salary) > 8000;
```

这条 SQL 的意思是：

1. `WHERE department_id IS NOT NULL AND salary > 0`：先过滤不需要参与统计的原始数据。
2. `GROUP BY department_id`：再按部门分组。
3. `HAVING COUNT(*) >= 3 AND AVG(salary) > 8000`：最后筛选符合统计条件的部门。

这是开发中最常见、也最推荐的组合写法。

---

## 3.7 没有 GROUP BY 时能不能使用 HAVING

一般学习时，可以先记成：

> `HAVING` 通常搭配 `GROUP BY` 使用。

但更精确地说：

> 如果查询中使用了聚合函数，但没有写 `GROUP BY`，MySQL 会把所有符合条件的行视为同一组。

例如：

```sql
SELECT
    COUNT(*) AS employee_count
FROM employees
HAVING COUNT(*) > 100;
```

这条 SQL 没有写 `GROUP BY`，但可以理解成：

1. 把 `employees` 中的所有行视为一个整体分组。
2. 计算总行数。
3. 如果总行数大于 `100`，就返回结果。
4. 如果总行数不大于 `100`，就不返回结果。

所以，不能简单地说「`HAVING` 一定必须和 `GROUP BY` 一起出现」。

更精确的说法是：

- 有明确分组需求时，`HAVING` 通常搭配 `GROUP BY` 使用。
- 没有 `GROUP BY` 但有聚合函数时，整张结果集会被视为一个隐式分组。
- 如果只是普通行条件，不应该为了使用 `HAVING` 而省略 `WHERE`。

不推荐写法：

```sql
SELECT
    employee_id,
    salary
FROM employees
HAVING salary > 5000;
```

推荐写法：

```sql
SELECT
    employee_id,
    salary
FROM employees
WHERE salary > 5000;
```

---

## 3.8 HAVING 中使用 SELECT 别名

MySQL 允许在 `HAVING` 中使用 `SELECT` 中定义的别名。

例如：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING employee_count >= 5;
```

这在 MySQL 中是合法写法，意思等同于：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) >= 5;
```

不过，为了提升跨数据库兼容性，也可以优先写成：

```sql
HAVING COUNT(*) >= 5
```

### 注意别名冲突

如果别名和表中原本的字段名称相同，可能造成阅读困难或解析歧义。

不推荐：

```sql
SELECT
    COUNT(*) AS department_id
FROM employees
GROUP BY department_id
HAVING department_id > 5;
```

推荐：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING employee_count > 5;
```

原则是：

- 聚合结果的别名要取清楚。
- 不要让别名和原始字段名冲突。
- 常见命名可以用 `xxx_count`、`total_xxx`、`avg_xxx`、`max_xxx`、`min_xxx`。

---

## 3.9 WHERE 和 HAVING 的效率与选择原则

### 3.9.1 普通条件优先写 WHERE

如果条件可以在分组前判断，就优先写在 `WHERE`。

推荐：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
WHERE department_id IS NOT NULL
GROUP BY department_id;
```

不推荐：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING department_id IS NOT NULL;
```

原因是：

- `WHERE` 可以先减少要参与分组的数据。
- `HAVING` 通常要等分组结果产生后再筛选。
- 数据量越大，提前过滤越重要。

### 3.9.2 聚合条件必须写 HAVING

如果条件使用了聚合函数，就写在 `HAVING`。

推荐：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) >= 5;
```

错误：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
WHERE COUNT(*) >= 5
GROUP BY department_id;
```

### 3.9.3 不要把 HAVING 当成万能 WHERE

`HAVING` 虽然也能写筛选条件，但它的主要职责是筛选分组后的结果。

判断原则：

| 问题 | 应该写在哪里 |
| --- | --- |
| 条件是否针对单笔原始数据？ | `WHERE` |
| 条件是否针对分组后的统计结果？ | `HAVING` |
| 条件中是否使用 `COUNT()`、`SUM()`、`AVG()` 等聚合函数？ | `HAVING` |
| 条件是否可以先过滤掉不需要参与统计的数据？ | `WHERE` |
| 是否同时有原始数据条件和聚合条件？ | `WHERE` + `HAVING` |

---

## 3.10 常见错误

### 错误 1：在 WHERE 中使用聚合函数

错误：

```sql
SELECT
    department_id,
    AVG(salary)
FROM employees
WHERE AVG(salary) > 8000
GROUP BY department_id;
```

正确：

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 8000;
```

原因：

- `WHERE` 执行时还没有分组。
- 聚合函数结果还没有产生。
- 所以聚合函数条件必须写在 `HAVING`。

### 错误 2：把普通行条件写到 HAVING

不推荐：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING department_id = 50;
```

推荐：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
WHERE department_id = 50
GROUP BY department_id;
```

原因：

- `department_id = 50` 是原始数据行条件。
- 它可以在分组前判断。
- 写在 `WHERE` 更符合语义，也更有利于提前减少数据量。

### 错误 3：误以为 HAVING 只能写聚合函数

`HAVING` 最典型的用途是筛选聚合函数结果，但它并不是只能写聚合函数。

可以：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING department_id IS NOT NULL;
```

但如果这个条件可以在分组前判断，更推荐写在 `WHERE`：

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
WHERE department_id IS NOT NULL
GROUP BY department_id;
```

### 错误 4：误以为 HAVING 一定必须搭配 GROUP BY

更精确的理解是：

- `HAVING` 通常搭配 `GROUP BY` 使用。
- 但如果查询中使用聚合函数且没有 `GROUP BY`，MySQL 会把所有行当成一个隐式分组。

例如：

```sql
SELECT
    COUNT(*) AS total_count
FROM employees
HAVING COUNT(*) > 0;
```

这条 SQL 可以执行。

### 错误 5：分不清 WHERE 和 HAVING 对结果的影响

比较下面两条 SQL。

SQL 1：

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
WHERE salary > 5000
GROUP BY department_id;
```

意义：只统计薪资大于 `5000` 的员工。

SQL 2：

```sql
SELECT
    department_id,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 5000;
```

意义：统计每个部门所有员工的平均薪资，再筛选平均薪资大于 `5000` 的部门。

两者结果可能完全不同。

---

## 3.11 开发中的推荐写法

### 推荐模板

```sql
SELECT
    分组字段,
    聚合函数 AS 聚合结果别名
FROM 表名
WHERE 分组前条件
GROUP BY 分组字段
HAVING 聚合函数条件
ORDER BY 排序字段;
```

例如：

```sql
SELECT
    customer_id,
    COUNT(*) AS order_count,
    SUM(total_price) AS total_spent
FROM orders
WHERE order_status = 'PAID'
GROUP BY customer_id
HAVING COUNT(*) >= 3
   AND SUM(total_price) > 10000
ORDER BY total_spent DESC;
```

这条 SQL 的意思是：

1. `WHERE order_status = 'PAID'`：只统计已付款订单。
2. `GROUP BY customer_id`：按客户分组。
3. `COUNT(*)`：统计每个客户的已付款订单数。
4. `SUM(total_price)`：统计每个客户的已付款总金额。
5. `HAVING COUNT(*) >= 3 AND SUM(total_price) > 10000`：筛选订单数至少 `3` 笔，且总消费超过 `10000` 的客户。
6. `ORDER BY total_spent DESC`：按消费金额从高到低排序。

### 推荐原则

- 普通字段条件写在 `WHERE`。
- 聚合函数条件写在 `HAVING`。
- 如果两种条件都有，就同时使用 `WHERE` 和 `HAVING`。
- `HAVING` 中可以使用聚合函数，也可以使用 MySQL 允许的 `SELECT` 别名。
- 为了减少歧义，聚合结果别名要清楚，不要和原始字段名冲突。
- 写聚合查询时，优先保证语义清楚，再考虑性能优化。

---

## 3.12 速查表

### 3.12.1 WHERE vs HAVING

| 比较点 | WHERE | HAVING |
| --- | --- | --- |
| 执行阶段 | `GROUP BY` 之前 | `GROUP BY` 之后 |
| 筛选对象 | 原始数据行 | 分组后的结果 |
| 能否使用聚合函数 | 不能 | 可以 |
| 是否影响参与分组的数据 | 会 | 不会影响已经参与分组的数据 |
| 常见用途 | 过滤原始记录 | 过滤聚合结果 |
| 推荐使用场景 | 普通字段条件 | `COUNT()`、`SUM()`、`AVG()` 等聚合条件 |

### 3.12.2 条件应该写在哪里

| 条件 | 推荐位置 | 示例 |
| --- | --- | --- |
| `salary > 5000` | `WHERE` | `WHERE salary > 5000` |
| `department_id IS NOT NULL` | `WHERE` | `WHERE department_id IS NOT NULL` |
| `COUNT(*) > 5` | `HAVING` | `HAVING COUNT(*) > 5` |
| `AVG(salary) > 8000` | `HAVING` | `HAVING AVG(salary) > 8000` |
| `SUM(total_price) > 10000` | `HAVING` | `HAVING SUM(total_price) > 10000` |
| 先筛选已付款订单，再筛选消费总额 | `WHERE` + `HAVING` | `WHERE status = 'PAID' GROUP BY customer_id HAVING SUM(total_price) > 10000` |

### 3.12.3 常见聚合筛选模板

统计数量：

```sql
HAVING COUNT(*) >= n
```

统计总和：

```sql
HAVING SUM(column_name) > n
```

统计平均值：

```sql
HAVING AVG(column_name) >= n
```

统计最大值：

```sql
HAVING MAX(column_name) > n
```

统计最小值：

```sql
HAVING MIN(column_name) < n
```

多个条件：

```sql
HAVING COUNT(*) >= n
   AND SUM(column_name) > m
```

---

## 3.13 结论

- `HAVING` 的核心作用是：**筛选分组后的统计结果**。
- `WHERE` 发生在 `GROUP BY` 之前，负责筛选原始数据行。
- `HAVING` 发生在 `GROUP BY` 之后，负责筛选分组结果。
- `WHERE` 不能使用聚合函数，`HAVING` 可以使用聚合函数。
- 普通字段条件优先写在 `WHERE`，聚合函数条件写在 `HAVING`。
- `WHERE` 和 `HAVING` 可以同时使用，而且这是实际开发中很常见的写法。
- `HAVING` 通常搭配 `GROUP BY`，但在有聚合函数且没有 `GROUP BY` 时，MySQL 会把所有行视为一个隐式分组。
- MySQL 允许在 `HAVING` 中使用 `SELECT` 中定义的别名，但要避免别名和原始字段名冲突。

---
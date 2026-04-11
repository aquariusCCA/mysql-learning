# 4 SELECT 的执行过程

> 所属章节：MySQL 基础篇 / 第 08 章 聚合函数

## 本节导读

本节整理 `SELECT` 查询从书写结构到实际执行顺序的全过程。重点不是只记住语法顺序，而是理解 SQL 在执行时会先做什么、后做什么，以及每个阶段如何基于前一个阶段生成的结果继续处理数据。

建议阅读顺序：

1. 先看 `SELECT` 查询的标准结构，建立整体框架。
2. 再区分书写顺序与实际执行顺序。
3. 最后结合虚拟表（VT）示例，理解多表连接、分组、筛选与排序是怎样一步步发生的。

## 前置知识

- 建议先读：[2 GROUP BY](./2%20GROUP%20BY.md)
- 建议先读：[3 HAVING](./3%20HAVING.md)

## 关键字

`SELECT` `执行顺序` `书写顺序` `虚拟表` `FROM` `WHERE` `GROUP BY` `HAVING` `ORDER BY` `LIMIT`

## 建议回查情境

- 想确认 SQL 的书写顺序和实际执行顺序为什么不同。
- 忘记 `WHERE`、`GROUP BY`、`HAVING`、`ORDER BY` 的先后关系时。
- 想理解为什么某些别名可以在 `ORDER BY` 中使用、却不能在 `WHERE` 中使用时。
- 需要复习多表连接或外连接在执行过程中各阶段如何形成虚拟表时。

## 内容导航

- [4.1 查询的结构](#41-查询的结构)
- [4.2 SELECT 执行顺序](#42-select-执行顺序)
- [4.3 SQL 查询的执行顺序与虚拟表演变](#43-sql-查询的执行顺序与虚拟表演变)
- [4.3.1 SQL 查询的执行顺序](#431-sql-查询的执行顺序)
- [4.3.2 SQL 查询各阶段的执行细节](#432-sql-查询各阶段的执行细节)
- [4.3.3 SQL 执行示例](#433-sql-执行示例)
- [4.3.4 外连接（OUTER JOIN）SQL 执行顺序示例](#434-外连接outer-joinsql-执行顺序示例)

## 4.1 查询的结构

`SELECT` 查询常见有两种写法，本质上都遵循相同的处理流程。

```sql
# 方式 1
SELECT ..., ...., ...
FROM ..., ..., ....
WHERE 多表的连接条件
AND 不包含组函数的过滤条件
GROUP BY ..., ...
HAVING 包含组函数的过滤条件
ORDER BY ... ASC/DESC
LIMIT ..., ...;

# 方式 2
SELECT ..., ...., ...
FROM ... JOIN ...
ON 多表的连接条件
JOIN ...
ON ...
WHERE 不包含组函数的过滤条件
AND/OR 不包含组函数的过滤条件
GROUP BY ..., ...
HAVING 包含组函数的过滤条件
ORDER BY ... ASC/DESC
LIMIT ..., ...;
```

各子句的职责可以先记成下面这样：

- `FROM`：决定从哪些表中取数据。
- `ON`：多表关联时，用来消除无效的笛卡尔积匹配。
- `WHERE`：对原始数据行进行筛选。
- `GROUP BY`：决定按什么维度分组。
- `HAVING`：对分组后的结果再次筛选。
- `ORDER BY`：对最终结果排序。
- `LIMIT`：限制返回记录数，常用于分页。

## 4.2 SELECT 执行顺序

你需要同时记住 `SELECT` 查询的两个顺序：**书写顺序**和**执行顺序**。

### 4.2.1 关键字的书写顺序不能颠倒

```sql
SELECT ... FROM ... WHERE ... GROUP BY ... HAVING ... ORDER BY ... LIMIT ...
```

### 4.2.2 SELECT 语句的实际执行顺序

```sql
FROM -> WHERE -> GROUP BY -> HAVING -> SELECT 的字段 -> DISTINCT -> ORDER BY -> LIMIT
```

下面这个例子同时展示了书写顺序和执行顺序：

```sql
SELECT
    DISTINCT player_id,
    player_name,
    COUNT(*) AS num          -- 执行顺序 5
FROM player
JOIN team ON player.team_id = team.team_id  -- 执行顺序 1
WHERE height > 1.80                         -- 执行顺序 2
GROUP BY player.team_id                     -- 执行顺序 3
HAVING num > 2                              -- 执行顺序 4
ORDER BY num DESC                           -- 执行顺序 6
LIMIT 2;                                    -- 执行顺序 7
```

> 在 `SELECT` 语句执行这些步骤时，每一步都会生成一个中间结果，可以理解成一个“虚拟表”。这个虚拟表会作为下一步的输入，直到最终得到查询结果。

## 4.3 SQL 查询的执行顺序与虚拟表演变

在 MySQL 查询执行过程中，SQL 语句的**书写顺序**与**执行顺序**并不相同。每个阶段都会生成一个虚拟表（Virtual Table，简称 `VT`），这个虚拟表会在后续阶段继续被修改、筛选或转换，直到最终得到结果集。

### 4.3.1 SQL 查询的执行顺序

| 执行顺序 | SQL 关键字 | 作用 | 产生的虚拟表 |
| --- | --- | --- | --- |
| 1 | `FROM` | 确定主表，获取原始数据 | `VT1` |
| 2 | `JOIN (ON)` | 计算笛卡尔积，并按 `ON` 条件过滤；外连接时还会补外部行 | `VT1-1`、`VT1-2`、`VT1-3` |
| 3 | `WHERE` | 过滤不符合条件的行 | `VT2` |
| 4 | `GROUP BY` | 按指定字段分组 | `VT3` |
| 5 | `HAVING` | 对分组后的数据进行筛选 | `VT4` |
| 6 | `SELECT` | 选取需要返回的字段 | `VT5-1` |
| 7 | `DISTINCT` | 去除重复数据 | `VT5-2` |
| 8 | `ORDER BY` | 对结果集排序 | `VT6` |
| 9 | `LIMIT` | 限制返回行数，得到最终结果 | `VT7` |

### 4.3.2 SQL 查询各阶段的执行细节

#### 1. `FROM` 阶段：获取初始数据

- 从指定表中获取所有数据，形成初始虚拟表 `VT1`。
- 如果是多表查询，会继续执行 `JOIN`：
- 先计算笛卡尔积，形成 `VT1-1`。
- 再按照 `ON` 条件筛选，形成 `VT1-2`。
- 如果是外连接，还会补上未匹配的外部行，形成 `VT1-3`。
- 多表联查时，上述过程会重复，直到得到最终的 `VT1`。

#### 2. `WHERE` 阶段：行过滤

- 在 `VT1` 的基础上按照 `WHERE` 条件筛选数据，得到 `VT2`。
- 这个阶段只处理单行数据，不处理分组后的结果。

#### 3. `GROUP BY` 阶段：数据分组

- 将 `VT2` 按照 `GROUP BY` 指定的字段分组，形成 `VT3`。
- 这个阶段的重点是“分组”，不是“筛选”。
- 分组完成后，可以理解为每个分组对应一行聚合结果。

#### 4. `HAVING` 阶段：分组后筛选

- 在 `VT3` 的基础上执行 `HAVING` 过滤，得到 `VT4`。
- `WHERE` 过滤的是原始数据行，发生在分组之前。
- `HAVING` 过滤的是分组后的结果，发生在分组之后。

#### 5. `SELECT` 阶段：字段提取

- 从 `VT4` 中提取最终需要显示的字段，得到 `VT5-1`。

#### 6. `DISTINCT` 阶段：去重

- 如果使用了 `DISTINCT`，就会对 `VT5-1` 去重，形成 `VT5-2`。

#### 7. `ORDER BY` 阶段：排序

- 对 `VT5-2` 进行排序，形成 `VT6`。

#### 8. `LIMIT` 阶段：限制返回行数

- 在 `VT6` 的基础上截取指定数量的记录，最终得到 `VT7`。

### 4.3.3 SQL 执行示例

假设有一个 `orders` 表：

| order_id | customer_id | total_price | order_date |
| --- | --- | --- | --- |
| 1 | 101 | 1000 | 2024-01-01 |
| 2 | 102 | 1500 | 2024-01-02 |
| 3 | 101 | 500 | 2024-01-03 |
| 4 | 103 | 2000 | 2024-01-04 |

示例查询：

```sql
SELECT customer_id, SUM(total_price) AS total_spent
FROM orders
WHERE total_price > 800
GROUP BY customer_id
HAVING SUM(total_price) > 2000
ORDER BY total_spent DESC
LIMIT 2;
```

#### 执行顺序与虚拟表变化

1. `FROM orders`

形成 `VT1`，也就是 `orders` 表的全部数据。

2. `WHERE total_price > 800`

只保留 `total_price > 800` 的记录，形成 `VT2`：

| order_id | customer_id | total_price |
| --- | --- | --- |
| 1 | 101 | 1000 |
| 2 | 102 | 1500 |
| 4 | 103 | 2000 |

3. `GROUP BY customer_id`

按 `customer_id` 分组，形成 `VT3`：

| customer_id | SUM(total_price) |
| --- | --- |
| 101 | 1000 |
| 102 | 1500 |
| 103 | 2000 |

4. `HAVING SUM(total_price) > 2000`

过滤掉 `SUM(total_price) <= 2000` 的分组，形成 `VT4`：

| customer_id | total_spent |
| --- | --- |
| 无匹配数据 | 无匹配数据 |

5. `SELECT customer_id, SUM(total_price) AS total_spent`

形成 `VT5-1`，与 `VT4` 对应。

6. `DISTINCT`

本例未使用 `DISTINCT`，跳过。

7. `ORDER BY total_spent DESC`

由于没有匹配数据，因此没有实际排序结果。

8. `LIMIT 2`

由于没有匹配数据，因此最终仍为空结果集。

> 最终结果为空，因为没有任何分组满足 `HAVING SUM(total_price) > 2000`。

### 4.3.4 外连接（OUTER JOIN）SQL 执行顺序示例

外连接（`LEFT JOIN`、`RIGHT JOIN`、`FULL JOIN`）的执行顺序与普通 `INNER JOIN` 略有不同，关键差异在于**外部行的补充**。

#### 4.3.4.1 示例数据

假设有两张表：`customers`（客户表）和 `orders`（订单表）。

`customers` 表：

| customer_id | customer_name |
| --- | --- |
| 1 | Alice |
| 2 | Bob |
| 3 | Charlie |
| 4 | David |

`orders` 表：

| order_id | customer_id | total_price |
| --- | --- | --- |
| 101 | 1 | 1000 |
| 102 | 1 | 500 |
| 103 | 2 | 1500 |
| 104 | 5 | 2000 |

#### 4.3.4.2 示例 SQL

假设我们要查询**所有客户的信息**，包括他们的订单总金额。如果某个客户没有订单，也应该显示出来，此时订单金额会显示为 `NULL`。

```sql
SELECT c.customer_id, c.customer_name, SUM(o.total_price) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;
```

#### 4.3.4.3 SQL 执行顺序解析

以下是这条 SQL 的实际执行顺序，以及每一步的虚拟表变化。

**1. `FROM customers`**

首先查询 `customers` 表，形成 `VT1`：

| customer_id | customer_name |
| --- | --- |
| 1 | Alice |
| 2 | Bob |
| 3 | Charlie |
| 4 | David |

**2. `LEFT JOIN`（`ON` 连接）**

- 先计算 `customers` 和 `orders` 的所有可能组合，形成 `VT1-1`。
- 再应用 `ON c.customer_id = o.customer_id` 条件，形成 `VT1-2`。
- 因为是 `LEFT JOIN`，还要保留左表中没有匹配成功的记录，并把右表字段补成 `NULL`，形成最终的 `VT1-3`。

| customer_id | customer_name | order_id | total_price |
| --- | --- | --- | --- |
| 1 | Alice | 101 | 1000 |
| 1 | Alice | 102 | 500 |
| 2 | Bob | 103 | 1500 |
| 3 | Charlie | NULL | NULL |
| 4 | David | NULL | NULL |

**3. `GROUP BY customer_id, customer_name`**

按照 `customer_id` 和 `customer_name` 分组，形成 `VT3`：

| customer_id | customer_name | SUM(total_price) |
| --- | --- | --- |
| 1 | Alice | 1500 |
| 2 | Bob | 1500 |
| 3 | Charlie | NULL |
| 4 | David | NULL |

**4. `SELECT` 选取字段**

提取 `customer_id`、`customer_name` 和 `SUM(o.total_price) AS total_spent`，形成 `VT5-1`：

| customer_id | customer_name | total_spent |
| --- | --- | --- |
| 1 | Alice | 1500 |
| 2 | Bob | 1500 |
| 3 | Charlie | NULL |
| 4 | David | NULL |

**5. `ORDER BY total_spent DESC`**

按照 `total_spent` 降序排序，`NULL` 默认排在最后：

| customer_id | customer_name | total_spent |
| --- | --- | --- |
| 1 | Alice | 1500 |
| 2 | Bob | 1500 |
| 3 | Charlie | NULL |
| 4 | David | NULL |

#### 4.3.4.4 关键点

1. `LEFT JOIN` 会保留左表中的所有记录，即使右表没有匹配数据。
2. `GROUP BY` 发生在 `LEFT JOIN` 之后，因此会基于连接后的结果继续分组。
3. `ORDER BY` 发生在最后，因此可以直接按聚合得到的别名 `total_spent` 排序。

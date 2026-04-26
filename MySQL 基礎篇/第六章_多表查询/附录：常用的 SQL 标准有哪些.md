# 附录：常用的 SQL 标准有哪些

> - 所属章节：第六章_多表查询  
> - 关键字：SQL 标准、SQL92、SQL99、SQL-2、SQL-3、JOIN、连接查询、数据库方言  
> - 建议回查情境：忘记为什么多表查询会同时出现 SQL92 和 SQL99 写法、不清楚 `FROM A, B WHERE ...` 与 `JOIN ... ON ...` 的来源差异，或想判断学习多表查询时应该优先掌握哪些 SQL 标准时

## 本节导读

这一节是学习多表查询前的背景说明。

学习 SQL 时，经常会看到同一个查询需求有不同写法。例如，查询员工姓名和部门名称，可以写成 SQL92 风格：

```sql
SELECT
    e.last_name,
    d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id;
````

也可以写成 SQL99 风格：

```sql
SELECT
    e.last_name,
    d.department_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;
```

这两种写法都可以完成多表查询，但语法风格不同。
要理解这种差异，就需要先知道：SQL 并不是只有一种固定写法，它经历过多个标准版本，不同标准对连接查询的表达方式有所不同。

本节不要求你背完整的 SQL 标准历史，而是帮助你建立一个学习前提：

> 学习多表查询时，最重要的是理解 SQL92 和 SQL99 两种常见连接写法的差异。

## 你会在这篇学到什么

* SQL 是一套有标准规范的数据库语言，不是某一个数据库产品独有的语法。
* SQL 标准经历过多个版本，例如 SQL-86、SQL-89、SQL-92、SQL:1999、SQL:2003、SQL:2011、SQL:2016、SQL:2023 等。
* 学习 MySQL 多表查询时，最常需要掌握的是 SQL92 和 SQL99 两种连接写法。
* SQL92 常见写法是把多个表写在 `FROM` 中，再把连接条件写在 `WHERE` 中。
* SQL99 更推荐使用 `JOIN ... ON`，把连接关系和筛选条件分得更清楚。
* 实际开发中，不需要完整掌握所有 SQL 标准，但要知道数据库产品可能会有自己的方言差异。

## 快速定位

* `为什么先了解 SQL 标准`：看多表查询为什么会牵涉不同写法。
* `SQL 标准是什么`：看 SQL 标准和数据库产品之间的关系。
* `常见 SQL 标准版本`：看 SQL 大致经历过哪些重要版本。
* `本章重点：SQL92 与 SQL99`：看为什么学习多表查询时主要关注这两个版本。
* `SQL92 与 SQL99 的连接写法差异`：看两者在多表查询中的核心区别。
* `学习建议`：看初学者该掌握到什么程度。

## 快速回查表

| 标准 / 写法         | 常见称呼                          | 多表查询中的典型特征                     | 学习重点         |
| --------------- | ----------------------------- | ------------------------------ | ------------ |
| SQL-86 / SQL-89 | 早期 SQL 标准                     | 奠定 SQL 基础语法                    | 了解即可         |
| SQL-92          | SQL92、SQL-2                   | 常见逗号连接写法：`FROM A, B WHERE ...` | 需要看懂         |
| SQL:1999        | SQL99、SQL-3                   | 引入更清晰的 `JOIN ... ON` 写法        | 需要重点掌握       |
| SQL:2003 以后     | 后续 SQL 标准                     | 持续扩展窗口函数、XML、JSON、递归查询等能力      | 按需求学习        |
| 数据库方言           | MySQL / Oracle / PostgreSQL 等 | 各数据库在标准 SQL 基础上扩展自己的语法         | 实务中要查对应数据库文档 |

## 为什么先了解 SQL 标准

在学习多表查询时，你会看到不同教材或项目代码使用不同写法。

有些代码会这样写：

```sql
SELECT
    e.last_name,
    d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id;
```

有些代码会这样写：

```sql
SELECT
    e.last_name,
    d.department_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;
```

如果只从语法表面看，可能会误以为这是两种完全不同的查询方式。
但本质上，它们都是在表达同一件事：

> 把员工表和部门表按照 `department_id` 连接起来。

差别在于：

* 第一种更接近 SQL92 风格。
* 第二种更接近 SQL99 风格。
* SQL99 把连接关系写得更明确，因此在复杂多表查询中通常更容易阅读和维护。

所以，学习 SQL 标准不是为了背历史，而是为了看懂不同写法背后的来源与设计意图。

## SQL 标准是什么

SQL 是结构化查询语言，用来操作关系型数据库。

不过，不同数据库产品并不是完全凭空设计自己的 SQL 语法，而是大多以 SQL 标准为基础，再加入各自的扩展功能。

常见数据库包括：

* MySQL
* Oracle
* PostgreSQL
* SQL Server
* DB2
* SQLite

这些数据库大多支持标准 SQL 的核心语法，但也会有自己的差异。

例如：

* MySQL 不支持直接使用 `FULL OUTER JOIN`。
* Oracle 早期常见外连接写法中会出现 `(+)`。
* PostgreSQL 对标准 SQL 的支持较完整，但也有自己的扩展能力。
* SQL Server 有自己的 T-SQL 语法扩展。

因此，学习 SQL 时要同时有两个观念：

1. 先掌握标准 SQL 的核心思想。
2. 再注意具体数据库产品的语法差异。

## 常见 SQL 标准版本

SQL 标准经历过多个版本，常见版本包括：

| 标准版本     | 常见名称        | 简要说明                          |
| -------- | ----------- | ----------------------------- |
| SQL-86   | SQL 最早期标准之一 | 奠定 SQL 标准化基础                  |
| SQL-89   | SQL-89      | 对早期 SQL 标准进行扩充                |
| SQL-92   | SQL92、SQL-2 | 经典 SQL 标准，很多基础语法来自这里          |
| SQL:1999 | SQL99、SQL-3 | 引入更多现代 SQL 能力，连接写法更清晰         |
| SQL:2003 | SQL2003     | 扩展 XML、窗口函数等能力                |
| SQL:2006 | SQL2006     | 继续强化 XML 相关能力                 |
| SQL:2008 | SQL2008     | 继续扩充查询与数据处理能力                 |
| SQL:2011 | SQL2011     | 加入或强化时间相关特性                   |
| SQL:2016 | SQL2016     | 加强 JSON 等相关能力                 |
| SQL:2023 | SQL2023     | 继续扩展现代数据处理能力，例如 JSON 和图查询相关内容 |

这些标准内容非常庞大，实际学习时不需要一开始全部掌握。

对 MySQL 初学者来说，尤其是在学习多表查询这一章时，最重要的是先理解 SQL92 和 SQL99。

## 本章重点：SQL92 与 SQL99

本章学习多表查询时，最常遇到的是两种写法：

1. SQL92 风格
2. SQL99 风格

### SQL92 风格

SQL92 风格的多表查询，常见写法是：

```sql
SELECT
    表1.字段,
    表2.字段
FROM 表1, 表2
WHERE 表1.关联字段 = 表2.关联字段;
```

它的特点是：

* 多张表用逗号写在 `FROM` 后面。
* 连接条件写在 `WHERE` 子句中。
* 写法比较传统。
* 简单查询中容易理解。
* 复杂查询中，连接条件和普通筛选条件容易混在一起。

例如：

```sql
SELECT
    e.last_name,
    d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id;
```

这里的：

```sql
e.department_id = d.department_id
```

就是连接条件。

### SQL99 风格

SQL99 风格的多表查询，常见写法是：

```sql
SELECT
    表1.字段,
    表2.字段
FROM 表1
JOIN 表2
    ON 表1.关联字段 = 表2.关联字段;
```

它的特点是：

* 使用 `JOIN` 明确表示表与表之间的连接。
* 使用 `ON` 明确表示连接条件。
* 连接条件和普通筛选条件更容易分开。
* 多表查询时结构更清楚。
* 更适合实际开发中的复杂 SQL。

例如：

```sql
SELECT
    e.last_name,
    d.department_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;
```

这里的：

```sql
JOIN departments d
    ON e.department_id = d.department_id
```

清楚表达了两件事：

1. `employees` 要和 `departments` 连接。
2. 连接依据是两张表的 `department_id` 相等。

## SQL92 与 SQL99 的核心区别

如果只看多表查询，可以这样理解两者差异：

| 比较点       | SQL92 风格             | SQL99 风格       |
| --------- | -------------------- | -------------- |
| 表的连接方式    | 多张表写在 `FROM` 中，用逗号分隔 | 使用 `JOIN` 明确连接 |
| 连接条件位置    | 通常写在 `WHERE` 中       | 通常写在 `ON` 中    |
| 可读性       | 简单查询尚可，复杂查询较容易混乱     | 多表查询时更清楚       |
| 连接条件与筛选条件 | 容易混在一起               | 可以明显分开         |
| 实务建议      | 需要能看懂旧代码             | 建议优先掌握并使用      |

例如，SQL92 写法：

```sql
SELECT
    e.last_name,
    d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id
  AND d.department_name = 'IT';
```

这条 SQL 中，`WHERE` 同时放了：

1. 连接条件：`e.department_id = d.department_id`
2. 筛选条件：`d.department_name = 'IT'`

SQL99 写法：

```sql
SELECT
    e.last_name,
    d.department_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
WHERE d.department_name = 'IT';
```

这条 SQL 把两种条件分开了：

* `ON`：负责说明表怎么连接。
* `WHERE`：负责说明连接完成后要筛选哪些数据。

这也是 SQL99 写法在实际开发中更推荐的原因。

## 学习建议

面对 SQL 标准，不需要试图一次掌握全部内容。

对当前阶段来说，建议按下面顺序学习：

### 第一阶段：先掌握核心查询能力

优先掌握：

* `SELECT`
* `FROM`
* `WHERE`
* `GROUP BY`
* `HAVING`
* `ORDER BY`
* `LIMIT`
* 单表查询
* 多表查询
* 子查询

### 第二阶段：掌握 SQL92 与 SQL99 的多表查询写法

你需要做到：

* 看得懂 SQL92 的逗号连接写法。
* 能判断 SQL92 写法中的连接条件在哪里。
* 熟练使用 SQL99 的 `JOIN ... ON` 写法。
* 知道 `JOIN`、`LEFT JOIN`、`RIGHT JOIN` 的结果差异。
* 知道 MySQL 不直接支持 `FULL OUTER JOIN`，需要用其他方式模拟。

### 第三阶段：再根据工作需求学习后续标准能力

后续可以再逐步学习：

* 窗口函数
* 公用表表达式 CTE
* 递归查询
* JSON 相关函数
* 数据库特定函数
* 执行计划与性能优化

这些内容很重要，但不需要在刚学习多表查询时一次全部展开。

## 初学者应该记住什么

如果你现在只是为了学好 MySQL 多表查询，可以先记住下面几点：

1. SQL 有标准，不同标准下写法可能不同。
2. SQL92 常见写法是 `FROM A, B WHERE A.id = B.id`。
3. SQL99 常见写法是 `FROM A JOIN B ON A.id = B.id`。
4. 两种写法都能表达多表连接，但 SQL99 更清楚。
5. 实际开发中建议优先使用 `JOIN ... ON`。
6. 旧项目中仍然可能看到 SQL92 写法，所以也要能读懂。
7. 不同数据库产品会有自己的语法差异，不能把 MySQL 的写法直接套到所有数据库上。

## 常见混淆点

* SQL92 和 SQL99 不是两个数据库，而是 SQL 标准的不同版本。
* SQL 标准不是某一个数据库产品的说明书，而是数据库语言的通用规范。
* MySQL、Oracle、PostgreSQL、SQL Server 都会支持标准 SQL 的一部分，同时也会有自己的扩展语法。
* SQL92 写法不是错误写法，只是复杂查询中可读性通常不如 SQL99。
* `JOIN ... ON` 不是只能写内连接，也可以配合左外连接、右外连接等使用。
* 学习 SQL 标准不是为了背版本年份，而是为了理解不同 SQL 写法为什么会同时存在。

## 常见回查问题

* SQL92 和 SQL99 是什么？
* 为什么多表查询有两种不同写法？
* `FROM A, B WHERE ...` 是什么风格？
* `JOIN ... ON ...` 是什么风格？
* 为什么更推荐 SQL99 的 `JOIN ... ON`？
* 学 MySQL 是否需要掌握所有 SQL 标准？
* SQL 标准和 MySQL 语法有什么关系？
* 为什么不同数据库的 SQL 写法有时不一样？

## 一句话抓核心

学习 SQL 标准不是为了背历史，而是为了理解多表查询中不同写法的来源；对本章来说，最重要的是看懂 SQL92 的传统连接写法，并熟练掌握 SQL99 的 `JOIN ... ON` 写法。

---
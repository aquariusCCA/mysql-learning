# 4 UNION 的使用

> - 所属章节：第六章_多表查询  
> - 关键字：UNION、UNION ALL、合并查询结果、去重、并集、结果集、SELECT 结构对齐  
> - 建议回查情境：忘记 `UNION` 和 `UNION ALL` 的区别、不确定多个 `SELECT` 合并时有哪些限制、分不清 `UNION` 和 `JOIN` 的差别，或想快速判断什么时候应该优先使用 `UNION ALL` 时

## 本节导读

前面几节学习的是表连接，例如：

```sql
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
```

这类写法的重点是：

> 把不同表中彼此相关的数据横向连接起来。

而这一节学习的 `UNION`，重点不是“表怎么连接”，而是：

> 把多条 `SELECT` 查询出来的结果纵向合并成一个结果集。

例如，下面两条查询分别查出两批员工：

```sql
SELECT *
FROM employees
WHERE email LIKE '%a%';

SELECT *
FROM employees
WHERE department_id > 90;
```

如果希望把这两批结果合并成一个结果集，就可以使用 `UNION` 或 `UNION ALL`。

第一次阅读时，建议先抓住三个问题：

1. `UNION` 到底解决什么问题？
2. `UNION` 和 `UNION ALL` 差在哪里？
3. 多个 `SELECT` 能不能合并，取决于什么条件？

只要理解这三个问题，后面看到用 `UNION` 模拟满外连接时，也会更容易理解。

## 你会在这篇学到什么

* `UNION` 和 `UNION ALL` 都可以把多条 `SELECT` 的结果合并成一个结果集。
* `UNION` 是纵向合并结果集，不是横向连接表。
* `JOIN` 关注的是“表和表怎么连”，`UNION` 关注的是“查询结果怎么合并”。
* 多个 `SELECT` 使用 `UNION` 合并时，返回的列数必须相同。
* 多个 `SELECT` 对应位置的字段类型需要相同或兼容。
* `UNION` 会去除重复记录。
* `UNION ALL` 不会去除重复记录。
* 如果明确不需要去重，通常优先考虑 `UNION ALL`，因为它少了去重成本。
* `UNION` 和 `OR` 有时可以表达相近需求，但不代表任何场景都完全等价。

## 快速定位

* `4.1 UNION 解决什么问题`：看它为什么不是表连接，而是结果集合并。
* `4.2 UNION 和 JOIN 的区别`：看纵向合并与横向连接的差异。
* `4.3 使用 UNION 的前提`：看多个 `SELECT` 合并前必须满足什么规则。
* `4.4 UNION 基本语法`：看多条 `SELECT` 如何拼接。
* `4.5 UNION 操作符`：看为什么它会去重。
* `4.6 UNION ALL 操作符`：看为什么它会保留重复记录。
* `4.7 UNION vs UNION ALL 怎么选`：看什么时候应该优先用 `UNION ALL`。
* `4.8 UNION 与 OR 的关系`：看两个写法为什么有时相近，但不总是完全等价。
* `4.9 跨表合并结果`：看不同表的查询结果如何合并。
* `4.10 ORDER BY 与 UNION`：看合并结果排序时要注意什么。
* `4.11 与后续 JOIN 图示的关系`：看为什么模拟满外连接会用到 `UNION`。

## 快速回查表

| 场景          | 写法                                                        | 说明                     |
| ----------- | --------------------------------------------------------- | ---------------------- |
| 合并并去重       | `SELECT ... UNION SELECT ...`                             | 合并多个结果集，并去除重复记录        |
| 合并但不去重      | `SELECT ... UNION ALL SELECT ...`                         | 合并多个结果集，保留重复记录         |
| 明确不需要去重     | 优先用 `UNION ALL`                                           | 通常比 `UNION` 少一步去重成本    |
| 多个结果集合并     | 多段 `SELECT` 用 `UNION` 或 `UNION ALL` 连接                    | 每段 `SELECT` 的列数和类型要能对应 |
| 同一张表不同条件合并  | `SELECT ... WHERE 条件1 UNION SELECT ... WHERE 条件2`         | 类似把两批查询结果放在一起          |
| 不同表结构相近数据合并 | `SELECT id, name FROM A UNION ALL SELECT id, name FROM B` | 只要输出结构能对齐，就可以合并        |
| 与 JOIN 的差异  | `JOIN` 是横向补字段，`UNION` 是纵向追加行                              | 两者解决的问题不同              |

## 建议阅读顺序

* 第一次学习时，建议按 `4.1 -> 4.2 -> 4.3 -> 4.5 -> 4.6` 的顺序阅读，先理解用途，再理解差异。
* 如果你只是忘记 `UNION` 和 `UNION ALL` 的区别，直接看 `4.5`、`4.6` 和 `4.7`。
* 如果你分不清 `JOIN` 和 `UNION`，重点看 `4.2 UNION 和 JOIN 的区别`。
* 如果你不确定为什么两个查询不能合并，重点看 `4.3 使用 UNION 的前提`。
* 如果你正在看后面的 7 种 JOIN 图示，重点看 `4.11 与后续 JOIN 图示的关系`。

## 4.1 UNION 解决什么问题

`UNION` 用来把多条 `SELECT` 语句的查询结果合并成一个结果集。

它适合处理这样的场景：

* 两个查询逻辑彼此独立，但最后希望放在同一个结果集中。
* 不同表中结构相近的数据，需要统一输出。
* 某些条件写成一条复杂查询不直观，拆成多条 `SELECT` 再合并更清楚。
* MySQL 中需要模拟 `FULL OUTER JOIN` 这类结果时，要把左右两边的查询结果合并起来。

例如：

```sql id="xg07om"
SELECT *
FROM employees
WHERE email LIKE '%a%'

UNION

SELECT *
FROM employees
WHERE department_id > 90;
```

这条 SQL 的意思是：

1. 先查出邮箱包含 `a` 的员工。
2. 再查出部门编号大于 `90` 的员工。
3. 最后把两批员工资料合并成一个结果集。
4. 如果两批结果中有重复员工，`UNION` 会自动去重。

所以，`UNION` 关注的是：

```text id="rhjdcx"
结果集 + 结果集
```

而不是：

```text id="uzkmuq"
表 + 表如何连接
```

## 4.2 UNION 和 JOIN 的区别

`UNION` 和 `JOIN` 都可能出现在多表查询章节中，但它们解决的问题完全不同。

### 4.2.1 JOIN：横向连接字段

`JOIN` 的重点是：根据连接条件，把不同表中的字段组合到同一行。

例如：

```sql id="uzmd3r"
SELECT
    e.last_name,
    d.department_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;
```

结果大致像这样：

| last_name | department_name |
| --------- | --------------- |
| King      | Executive       |
| Hunold    | IT              |

这里是把员工表和部门表横向连接起来。

可以理解为：

```text id="ke10g1"
员工资料 + 部门资料 = 同一行结果
```

### 4.2.2 UNION：纵向合并行

`UNION` 的重点是：把多个查询结果上下拼接起来。

例如：

```sql id="id93ft"
SELECT employee_id, last_name
FROM employees
WHERE department_id = 60

UNION ALL

SELECT employee_id, last_name
FROM employees
WHERE department_id = 90;
```

结果大致像这样：

| employee_id | last_name |
| ----------- | --------- |
| 103         | Hunold    |
| 104         | Ernst     |
| 100         | King      |
| 101         | Kochhar   |

这里是把两批员工资料纵向合并。

可以理解为：

```text id="yr7lyu"
第一批结果
+
第二批结果
=
一个更大的结果集
```

### 4.2.3 一句话区分

| 比较点  | JOIN     | UNION       |
| ---- | -------- | ----------- |
| 处理对象 | 表与表之间的关系 | 多个查询结果      |
| 合并方向 | 横向补字段    | 纵向追加行       |
| 关键要求 | 要有连接条件   | 输出列结构要对齐    |
| 常见用途 | 员工 + 部门  | 中国用户 + 美国用户 |
| 结果变化 | 列可能变多    | 行可能变多       |

所以：

> `JOIN` 是把相关资料接到同一行；`UNION` 是把多批查询结果合并成同一张结果表。

## 4.3 使用 UNION 的前提

`UNION` 不是随便把两条 SQL 拼在一起就可以。

多个 `SELECT` 要能合并，至少要满足下面几个条件。

### 4.3.1 返回列数必须相同

错误示例：

```sql id="g5ps7c"
SELECT employee_id, last_name
FROM employees

UNION

SELECT department_id
FROM departments;
```

第一段查询返回两列：

```text id="zx7rie"
employee_id, last_name
```

第二段查询只返回一列：

```text id="emzfqx"
department_id
```

列数不同，不能直接合并。

正确做法是让两段查询返回相同列数：

```sql id="aa4kdd"
SELECT employee_id AS id, last_name AS name
FROM employees

UNION

SELECT department_id AS id, department_name AS name
FROM departments;
```

### 4.3.2 对应位置的数据类型要相同或兼容

`UNION` 合并时，数据库会按“位置”对齐字段，而不是按字段名对齐。

例如：

```sql id="oqwnxd"
SELECT employee_id, last_name
FROM employees

UNION

SELECT department_id, department_name
FROM departments;
```

它会这样对齐：

| 第几列   | 第一段 SELECT    | 第二段 SELECT        |
| ----- | ------------- | ----------------- |
| 第 1 列 | `employee_id` | `department_id`   |
| 第 2 列 | `last_name`   | `department_name` |

这通常是合理的，因为：

* 第 1 列都是编号。
* 第 2 列都是名称。

但如果写成：

```sql id="vywe2p"
SELECT employee_id, last_name
FROM employees

UNION

SELECT department_name, department_id
FROM departments;
```

虽然列数相同，但语义对不上：

| 第几列   | 第一段 SELECT | 第二段 SELECT |
| ----- | ---------- | ---------- |
| 第 1 列 | 员工编号       | 部门名称       |
| 第 2 列 | 员工姓名       | 部门编号       |

这种写法即使数据库能做类型转换，结果语义也会很混乱。

所以使用 `UNION` 时，不只要看列数，还要看对应位置的业务含义是否一致。

### 4.3.3 最终字段名通常来自第一段 SELECT

例如：

```sql id="uf5d2v"
SELECT employee_id AS id, last_name AS name
FROM employees

UNION ALL

SELECT department_id AS dept_id, department_name AS dept_name
FROM departments;
```

最终结果集的字段名通常会采用第一段 `SELECT` 的别名：

```text id="kczjd8"
id, name
```

而不是第二段的：

```text id="t7mzpk"
dept_id, dept_name
```

所以如果你希望最终结果字段名称清楚，应该在第一段 `SELECT` 中把别名取好。

### 4.3.4 每段 SELECT 的列顺序要认真设计

推荐写法：

```sql id="dmpvbz"
SELECT
    employee_id AS id,
    last_name AS name,
    'EMPLOYEE' AS source_type
FROM employees

UNION ALL

SELECT
    department_id AS id,
    department_name AS name,
    'DEPARTMENT' AS source_type
FROM departments;
```

这里额外加了 `source_type`，用来区分这笔资料来自员工表还是部门表。

结果大致如下：

| id  | name | source_type |
| --- | ---- | ----------- |
| 100 | King | EMPLOYEE    |
| 60  | IT   | DEPARTMENT  |

这种写法在跨表合并时很常用。

## 4.4 UNION 基本语法

基本格式如下：

```sql id="exry2v"
SELECT 字段列表
FROM 表1
WHERE 条件1

UNION [ALL]

SELECT 字段列表
FROM 表2
WHERE 条件2;
```

其中：

* `UNION`：合并结果并去重。
* `UNION ALL`：合并结果但不去重。
* 每段 `SELECT` 的字段数量必须相同。
* 每段 `SELECT` 对应位置的数据类型需要相同或兼容。

也可以合并三段或更多段查询：

```sql id="lk84qc"
SELECT id, name
FROM table_a

UNION ALL

SELECT id, name
FROM table_b

UNION ALL

SELECT id, name
FROM table_c;
```

这表示把 `table_a`、`table_b`、`table_c` 查询出的结果统一合并。

## 4.5 UNION 操作符

`UNION` 会把多个查询结果合并，并去除重复记录。

例如：

```sql id="zh9kc3"
SELECT employee_id, last_name
FROM employees
WHERE department_id = 60

UNION

SELECT employee_id, last_name
FROM employees
WHERE last_name LIKE '%u%';
```

如果某个员工同时满足：

```text id="pja8yr"
department_id = 60
```

以及：

```text id="zb5dqm"
last_name LIKE '%u%'
```

那么这个员工可能会被两段 `SELECT` 同时查出来。

但因为使用的是 `UNION`，最终结果只会保留一份。

### 4.5.1 UNION 去重的是最终结果行

需要注意：

> `UNION` 去重的是最终结果集中的“整行记录”，不是只看某一个字段，也不是直接对原表去重。

例如：

```sql id="gnsehv"
SELECT 1 AS id, 'A' AS name
UNION
SELECT 1 AS id, 'A' AS name;
```

最终只会有一行：

| id | name |
| -- | ---- |
| 1  | A    |

但如果是：

```sql id="vunvgc"
SELECT 1 AS id, 'A' AS name
UNION
SELECT 1 AS id, 'B' AS name;
```

结果会有两行：

| id | name |
| -- | ---- |
| 1  | A    |
| 1  | B    |

因为两行并不完全相同。

### 4.5.2 UNION 的特点

`UNION` 的特点可以总结为：

* 会合并多个结果集。
* 会去除重复行。
* 结果通常更干净。
* 但因为需要判断重复，通常会有额外成本。

所以，如果业务上确实需要去重，就使用 `UNION`。

## 4.6 UNION ALL 操作符

`UNION ALL` 也会把多个查询结果合并，但不会去除重复记录。

例如：

```sql id="q2hg79"
SELECT 1 AS id, 'A' AS name
UNION ALL
SELECT 1 AS id, 'A' AS name;
```

结果会保留两行：

| id | name |
| -- | ---- |
| 1  | A    |
| 1  | A    |

这表示：

> 两段查询查出来多少行，合并后就尽量保留多少行。

### 4.6.1 UNION ALL 的特点

`UNION ALL` 的特点可以总结为：

* 会合并多个结果集。
* 不会去除重复行。
* 保留所有查询结果。
* 通常比 `UNION` 少一步去重成本。
* 如果业务允许重复，或者你确定不会重复，通常优先考虑 `UNION ALL`。

例如：

```sql id="s20eq4"
SELECT id, cname AS name
FROM t_chinamale
WHERE csex = '男'

UNION ALL

SELECT id, tname AS name
FROM t_usmale
WHERE tGender = 'male';
```

这里使用 `UNION ALL` 的含义是：

> 把中国男性用户和美国男性用户直接合并到同一个结果集中，不做去重。

如果两张表本来就是不同来源的数据，且业务上不需要判断重复，`UNION ALL` 通常更直观。

## 4.7 UNION vs UNION ALL 怎么选

可以用下面规则判断。

| 需求                | 建议写法        | 原因                                    |
| ----------------- | ----------- | ------------------------------------- |
| 需要去除重复行           | `UNION`     | 自动去重                                  |
| 需要保留重复行           | `UNION ALL` | 不会丢数据                                 |
| 确定两批结果不会重复        | `UNION ALL` | 避免不必要的去重成本                            |
| 不确定是否会重复，但重复会造成错误 | `UNION`     | 保守去重                                  |
| 后续还要统计数量          | 视业务决定       | 重复行是否要算入统计很关键                         |
| 模拟某些 JOIN 结果      | 视写法决定       | 有时用 `UNION` 去重，有时用 `UNION ALL` 避免多余成本 |

### 4.7.1 判断重点不是性能，而是语义

虽然 `UNION ALL` 通常更省资源，但不能只因为性能就盲目使用。

真正应该先问的是：

> 业务上需不需要保留重复记录？

如果重复记录代表真实数据，就不能随便用 `UNION` 去掉。

例如，两个查询结果中出现相同的金额记录，不一定代表它们是同一笔业务。
如果你使用 `UNION`，可能会把本来应该保留的重复结果去掉。

所以选择顺序应该是：

1. 先判断业务语义。
2. 再考虑性能成本。
3. 如果不需要去重，优先用 `UNION ALL`。

## 4.8 UNION 与 OR 的关系

有些查询可以用 `OR` 写，也可以用 `UNION` 写。

例如，查询：

> 部门编号大于 `90`，或者邮箱包含 `a` 的员工。

### 4.8.1 使用 OR

```sql id="znibn1"
SELECT *
FROM employees
WHERE email LIKE '%a%'
   OR department_id > 90;
```

这条 SQL 的意思是：

> 在同一张表中，查询满足任一条件的员工。

### 4.8.2 使用 UNION

```sql id="jn0ssl"
SELECT *
FROM employees
WHERE email LIKE '%a%'

UNION

SELECT *
FROM employees
WHERE department_id > 90;
```

这条 SQL 的意思是：

1. 先查邮箱包含 `a` 的员工。
2. 再查部门编号大于 `90` 的员工。
3. 合并两批结果。
4. 如果有员工同时满足两个条件，只保留一份。

### 4.8.3 OR 和 UNION 是否完全等价

在这个例子中，两种写法表达的是相近需求。

但不能简单认为：

```text id="mji6ci"
OR 永远等于 UNION
```

原因包括：

* `UNION` 默认会去重，`OR` 是在一条查询中筛选。
* `UNION ALL` 不去重，结果可能和 `OR` 不同。
* 不同数据库优化器对 `OR` 和 `UNION` 的执行计划可能不同。
* 查询字段、排序、分页、索引使用情况不同，结果或性能都可能受影响。
* 如果两段 `SELECT` 来源不同表，通常不能简单改成一个 `OR`。

所以初学阶段可以先记住：

> `OR` 是在同一个查询中写多个筛选条件；`UNION` 是把多个查询结果合并起来。
> 有些简单场景两者结果相近，但不要把它们当成完全相同的语法。

## 4.9 跨表合并结果

`UNION` 不只能合并同一张表的不同查询结果，也可以合并不同表的结果。

前提是：

> 每段 `SELECT` 的输出结构能够对齐。

例如，有两张表：

`t_chinamale`：

| id | cname | csex |
| -- | ----- | ---- |
| 1  | 张三    | 男    |
| 2  | 李四    | 男    |

`t_usmale`：

| id | tname | tGender |
| -- | ----- | ------- |
| 10 | Tom   | male    |
| 11 | Jack  | male    |

可以写：

```sql id="m5k3p0"
SELECT
    id,
    cname AS name
FROM t_chinamale
WHERE csex = '男'

UNION ALL

SELECT
    id,
    tname AS name
FROM t_usmale
WHERE tGender = 'male';
```

这条 SQL 的含义是：

1. 从 `t_chinamale` 中查出中国男性用户。
2. 从 `t_usmale` 中查出美国男性用户。
3. 把两批结果合并成统一结构。
4. 最终输出字段为 `id` 和 `name`。

### 4.9.1 加上来源字段

实际开发中，跨表合并时常常会加一个来源字段，方便后续区分数据来自哪里：

```sql id="xbi7xt"
SELECT
    id,
    cname AS name,
    'CN' AS source_country
FROM t_chinamale
WHERE csex = '男'

UNION ALL

SELECT
    id,
    tname AS name,
    'US' AS source_country
FROM t_usmale
WHERE tGender = 'male';
```

结果大致如下：

| id | name | source_country |
| -- | ---- | -------------- |
| 1  | 张三   | CN             |
| 2  | 李四   | CN             |
| 10 | Tom  | US             |
| 11 | Jack | US             |

这种写法的好处是：

* 结果结构统一。
* 数据来源清楚。
* 后续统计、筛选、展示更方便。

## 4.10 ORDER BY 与 UNION

使用 `UNION` 或 `UNION ALL` 后，如果要排序，通常把 `ORDER BY` 放在最后，对合并后的整体结果排序。

例如：

```sql id="qz9c03"
SELECT employee_id AS id, last_name AS name
FROM employees
WHERE department_id = 60

UNION ALL

SELECT employee_id AS id, last_name AS name
FROM employees
WHERE department_id = 90

ORDER BY id;
```

这里的：

```sql id="ohw59e"
ORDER BY id
```

是对合并后的整体结果排序。

### 4.10.1 ORDER BY 使用建议

建议记住：

* `ORDER BY` 通常写在整个 `UNION` 查询的最后。
* 排序字段最好使用最终结果集中的字段名或别名。
* 最终字段名通常来自第一段 `SELECT`。
* 不建议初学阶段在每一段 `SELECT` 里分别写 `ORDER BY`，除非你明确知道数据库的语法规则和执行语义。

例如：

```sql id="dvd1vn"
SELECT employee_id AS id, last_name AS name
FROM employees
WHERE department_id = 60

UNION ALL

SELECT employee_id AS id, last_name AS name
FROM employees
WHERE department_id = 90

ORDER BY name;
```

这里按照最终结果中的 `name` 排序。

## 4.11 与后续 JOIN 图示的关系

后面学习「7 种 SQL JOINS 的实现」时，会看到 MySQL 中可以用 `UNION` 或 `UNION ALL` 来模拟满外连接。

原因是 MySQL 不直接支持：

```sql id="t2ol4x"
FULL OUTER JOIN
```

所以要用组合方式取得类似结果。

例如：

```sql id="xv29za"
SELECT
    e.employee_id,
    e.last_name,
    d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id

UNION

SELECT
    e.employee_id,
    e.last_name,
    d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;
```

这类写法的思路是：

1. 用 `LEFT JOIN` 取得左表完整结果。
2. 用 `RIGHT JOIN` 取得右表完整结果。
3. 用 `UNION` 把两批结果合并。
4. 如果中间有重复交集，`UNION` 会去重。

如果写法已经避免了重复，或者业务允许重复，也可能使用 `UNION ALL`。

因此，这一节的 `UNION` 是后面理解 JOIN 图示的重要基础。

## 4.12 常见错误示例

### 错误 1：列数不同

```sql id="xrt5eo"
SELECT employee_id, last_name
FROM employees

UNION

SELECT department_id
FROM departments;
```

问题：

```text id="fzmgd8"
第一段 SELECT 返回 2 列，第二段 SELECT 返回 1 列，不能直接合并。
```

### 错误 2：列的业务含义没有对齐

```sql id="z3tqnr"
SELECT employee_id, last_name
FROM employees

UNION ALL

SELECT department_name, department_id
FROM departments;
```

问题：

```text id="mb6nms"
第一列一边是员工编号，一边是部门名称；第二列一边是员工姓名，一边是部门编号。即使能执行，语义也很混乱。
```

### 错误 3：误以为 UNION 是表连接

```sql id="a1e3hc"
SELECT employee_id, last_name
FROM employees

UNION

SELECT department_id, department_name
FROM departments;
```

这条 SQL 只是把员工资料和部门资料合并成同一类结果，不会产生“员工所属部门”的关系。

如果需求是查询员工和部门对应关系，应该使用 `JOIN`：

```sql id="pme4dw"
SELECT
    e.employee_id,
    e.last_name,
    d.department_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;
```

### 错误 4：该保留重复时误用 UNION

```sql id="fn3ghd"
SELECT amount
FROM order_2023

UNION

SELECT amount
FROM order_2024;
```

如果两个年度中刚好都有相同金额，`UNION` 可能会把重复金额去掉。

如果业务上每一笔金额记录都应该保留，应该使用：

```sql id="psnx5v"
SELECT amount
FROM order_2023

UNION ALL

SELECT amount
FROM order_2024;
```

## 4.13 如何阅读一条 UNION 查询

看到一条 `UNION` 查询时，可以按下面步骤阅读。

### 第一步：先看有几段 SELECT

例如：

```sql id="cjycc5"
SELECT ...
UNION ALL
SELECT ...
UNION ALL
SELECT ...
```

表示有三段查询结果要合并。

### 第二步：确认每段 SELECT 的输出结构

重点看：

* 每段返回几列。
* 每列的顺序是否一致。
* 对应位置的字段类型是否兼容。
* 对应位置的业务含义是否一致。

### 第三步：判断使用的是 UNION 还是 UNION ALL

如果是：

```sql id="b1u3k7"
UNION
```

表示要去重。

如果是：

```sql id="l1ptct"
UNION ALL
```

表示不去重。

### 第四步：看是否有来源字段

例如：

```sql id="t6eryz"
'CN' AS source_country
```

这种字段通常用来标记资料来源。

### 第五步：看最后有没有 ORDER BY

如果有：

```sql id="povrrw"
ORDER BY name
```

通常表示对合并后的整体结果排序。

## 常见混淆点

* `UNION` 和 `UNION ALL` 都是在合并结果集，不是在做表连接。
* `JOIN` 是横向连接字段，`UNION` 是纵向合并行。
* `UNION` 会去重，`UNION ALL` 不会去重。
* `UNION` 去重的是最终结果集中的完整行，不是只看某一个字段。
* 使用 `UNION` 时，不是原表去重，而是最终结果集去重。
* 不同 `SELECT` 能否合并，关键不是表名是否相同，而是输出结构是否一致。
* 合并时按字段位置对齐，不是按字段名称自动匹配。
* 最终字段名通常来自第一段 `SELECT`，所以第一段的字段别名要取清楚。
* `UNION` 和 `OR` 有时能表达相近需求，但不能简单认为两者永远等价。
* 如果明确不需要去重，通常优先使用 `UNION ALL`。
* 如果重复记录在业务上有意义，就不要随便用 `UNION` 去重。
* `ORDER BY` 通常写在整个 `UNION` 查询的最后，对合并后的整体结果排序。

## 常见回查问题

* `UNION` 和 `UNION ALL` 到底差在哪里？
* 为什么 `UNION` 查询结果比预期少？
* 什么时候应该优先使用 `UNION ALL`？
* `UNION` 是不是表连接？
* `UNION` 和 `JOIN` 有什么区别？
* 不同表的查询结果可以直接 `UNION` 吗？
* 使用 `UNION` 时，各段 `SELECT` 要满足什么条件？
* `UNION` 合并时是按字段名对齐，还是按字段位置对齐？
* `UNION` 和 `OR` 是不是一样的？
* `ORDER BY` 在 `UNION` 中应该写在哪里？
* 为什么 MySQL 模拟满外连接时会用到 `UNION`？

## 一句话抓核心

`UNION` 和 `UNION ALL` 都是把多个查询结果纵向合并成一个结果集；`UNION` 会去重，`UNION ALL` 不会去重，而能不能合并的关键在于每段 `SELECT` 的输出列数、类型和业务语义是否能够对齐。

## 小结

这一节需要记住：

* `UNION` 和 `UNION ALL` 都可以把多条 `SELECT` 合并成一个结果集。
* `UNION` 处理的是结果集合并，不是表连接。
* `JOIN` 是横向连接表，`UNION` 是纵向合并结果行。
* 合并前，各个 `SELECT` 的列数必须相同。
* 合并前，各个 `SELECT` 对应位置的数据类型需要相同或兼容。
* 合并时字段按位置对齐，不是按字段名自动对齐。
* `UNION` 会去除重复记录。
* `UNION ALL` 会保留重复记录。
* 如果不需要去重，通常优先使用 `UNION ALL`。
* 如果重复记录有业务意义，不应该随便使用 `UNION` 去掉。
* `OR` 和 `UNION` 有时能表达相近查询意图，但不是所有场景都完全等价。
* `ORDER BY` 通常写在整个 `UNION` 查询的最后。
* 后面模拟 MySQL 满外连接时，会用到 `LEFT JOIN`、`RIGHT JOIN` 与 `UNION` / `UNION ALL` 的组合。

---
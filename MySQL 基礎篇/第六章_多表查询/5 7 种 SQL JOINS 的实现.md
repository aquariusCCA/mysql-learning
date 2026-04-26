# 5 7 种 SQL JOINS 的实现

> - 所属章节：第六章_多表查询  
> - 关键字：INNER JOIN、LEFT JOIN、RIGHT JOIN、FULL OUTER JOIN、左外连接、右外连接、左独有、右独有、满外连接、UNION、UNION ALL、IS NULL  
> - 建议回查情境：看到 7 种 JOIN 图示时忘记每一块区域对应哪种 SQL、想查询左表独有或右表独有数据、不确定左外连接和左独有的差别，或需要在 MySQL 中模拟满外连接时

## 本节导读

前面已经学过：

- `JOIN` / `INNER JOIN`：只保留匹配成功的数据。
- `LEFT JOIN`：保留左表全部数据。
- `RIGHT JOIN`：保留右表全部数据。
- `UNION` / `UNION ALL`：合并多个查询结果集。

这一节把这些内容组合起来，专门回答一个实战问题：

> JOIN 图示中的每一块区域，到底应该用什么 SQL 查出来？

需要先注意一个重点：

> 所谓「7 种 SQL JOINs」，不一定代表 SQL 里真的有 7 个不同的 JOIN 关键字。  
> 它更准确地说，是 7 种常见的结果集组合方式。

这些结果集可以用：

- `INNER JOIN`
- `LEFT JOIN`
- `RIGHT JOIN`
- `IS NULL`
- `UNION`
- `UNION ALL`

组合出来。

本节用下面两个表作为示例：

```text
A 表：employees    员工表
B 表：departments  部门表
```

它们的连接条件是：

```sql
e.department_id = d.department_id
```

其中：

* `employees e` 代表 A 表。
* `departments d` 代表 B 表。
* `A ∩ B` 代表员工和部门能匹配成功的部分。
* `A - A∩B` 代表员工表有，但部门表匹配不到的部分。
* `B - A∩B` 代表部门表有，但员工表匹配不到的部分。
* `A ∪ B` 代表两张表的全部结果。

## 你会在这篇学到什么

* 7 种 JOIN 图示本质上是在讨论 A 表、B 表及其交集的不同组合。
* 内连接对应 `A ∩ B`。
* 左外连接对应左表全部结果，也就是 `A`。
* 右外连接对应右表全部结果，也就是 `B`。
* 左表独有不是 `LEFT JOIN` 本身，而是 `LEFT JOIN` 后再筛选右表为 `NULL`。
* 右表独有不是 `RIGHT JOIN` 本身，而是 `RIGHT JOIN` 后再筛选左表为 `NULL`。
* MySQL 不支持直接使用 `FULL OUTER JOIN`。
* MySQL 可以用 `LEFT JOIN`、`RIGHT JOIN`、`UNION` 或 `UNION ALL` 模拟满外连接。
* 使用 `UNION ALL` 模拟满外连接时，要避免把交集重复合并进去。
* `IS NULL` 筛选时，应尽量选择被排除一侧中不可能为 `NULL` 的主键或唯一键字段。

## 快速定位

* `5.1 结果集总览`：先把 7 种 JOIN 图示对应到集合关系。
* `5.2 示例表与连接条件`：看本节所有 SQL 使用的共同前提。
* `5.3 中图：内连接 A∩B`：看只保留匹配成功数据的写法。
* `5.4 左上图：左外连接 A`：看如何保留左表全部数据。
* `5.5 右上图：右外连接 B`：看如何保留右表全部数据。
* `5.6 左中图：A - A∩B`：看如何查询左表独有数据。
* `5.7 右中图：B - A∩B`：看如何查询右表独有数据。
* `5.8 左下图：满外连接 A∪B`：看 MySQL 如何模拟满外连接。
* `5.9 右下图：A∪B - A∩B`：看如何查询左右两边各自独有数据。
* `5.10 UNION 与 UNION ALL 的选择`：看模拟满外连接时如何避免重复。
* `5.11 通用模板小结`：看可复用的 SQL 模板。

## 快速回查表

| 图示含义 | 集合关系          | 实现方式      | 核心写法                                                     |
| ---- | ------------- | --------- | -------------------------------------------------------- |
| 中图   | `A ∩ B`       | 内连接       | `JOIN ... ON ...`                                        |
| 左上图  | `A`           | 左外连接      | `LEFT JOIN ... ON ...`                                   |
| 右上图  | `B`           | 右外连接      | `RIGHT JOIN ... ON ...`                                  |
| 左中图  | `A - A∩B`     | 左外连接后筛空   | `LEFT JOIN ... WHERE B.主键 IS NULL`                       |
| 右中图  | `B - A∩B`     | 右外连接后筛空   | `RIGHT JOIN ... WHERE A.主键 IS NULL`                      |
| 左下图  | `A ∪ B`       | 满外连接结果    | MySQL 用 `LEFT JOIN + UNION / UNION ALL + RIGHT JOIN` 模拟  |
| 右下图  | `A ∪ B - A∩B` | 左独有 + 右独有 | `LEFT JOIN ... IS NULL UNION ALL RIGHT JOIN ... IS NULL` |

## 建议阅读顺序

* 第一次学习时，建议按 `内连接 -> 左外连接 / 右外连接 -> 左独有 / 右独有 -> 满外连接 -> 左右独有` 的顺序阅读。
* 如果你只想查匹配成功的数据，直接看 `5.3 内连接`。
* 如果你要保留某一张表的全部数据，重点看 `5.4 左外连接` 和 `5.5 右外连接`。
* 如果你要找“没有对应部门的员工”或“没有员工的部门”，重点看 `5.6 左表独有` 和 `5.7 右表独有`。
* 如果你正在 MySQL 中模拟满外连接，重点看 `5.8` 和 `5.10`。
* 如果你只是复习，直接看 `快速回查表`、`通用模板小结` 和 `一句话抓核心`。

## 5.1 结果集总览

![1554979255233.png](./images/1554979255233.png)

假设：

```text
A = employees
B = departments
```

两张表通过下面条件连接：

```sql
e.department_id = d.department_id
```

JOIN 图示中的不同区域可以理解成：

| 区域            | 含义                  |
| ------------- | ------------------- |
| `A ∩ B`       | 员工和部门能匹配成功的数据       |
| `A`           | 员工表全部数据，部门能匹配就补上    |
| `B`           | 部门表全部数据，员工能匹配就补上    |
| `A - A∩B`     | 员工表有，但部门表匹配不到的数据    |
| `B - A∩B`     | 部门表有，但员工表匹配不到的数据    |
| `A ∪ B`       | 员工表和部门表两边全部数据       |
| `A ∪ B - A∩B` | 只保留左右两边各自独有的数据，不要交集 |

这 7 种结果集不是都靠单一 JOIN 关键字完成。
有些需要搭配 `IS NULL`，有些需要搭配 `UNION` 或 `UNION ALL`。

## 5.2 示例表与连接条件

本节统一使用下面两张表。

A 表：`employees e`

| employee_id | last_name | department_id |
| ----------- | --------- | ------------- |
| 100         | King      | 90            |
| 101         | Kochhar   | 90            |
| 103         | Hunold    | 60            |
| 178         | Grant     | NULL          |

B 表：`departments d`

| department_id | department_name |
| ------------- | --------------- |
| 60            | IT              |
| 90            | Executive       |
| 190           | Contracting     |

连接条件：

```sql
e.department_id = d.department_id
```

它表示：

> 员工表中的部门编号，要和部门表中的部门编号相等。

为了让结果更容易观察，本节示例统一查询下面字段：

```sql
e.employee_id,
e.last_name,
e.department_id AS employee_department_id,
d.department_id AS department_id,
d.department_name
```

这样可以清楚看出：

* 哪些数据来自员工表。
* 哪些数据来自部门表。
* 哪一侧没有匹配时会出现 `NULL`。

## 5.3 中图：内连接 `A ∩ B`

内连接只保留两张表都能匹配成功的记录。

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;
```

这条 SQL 的结果是：

```text
员工表中能找到对应部门的员工
+
部门表中能被员工匹配到的部门
```

也就是：

```text
A ∩ B
```

如果某个员工没有部门，或者员工的部门编号在部门表中找不到，对应员工不会出现在结果中。

如果某个部门没有任何员工，对应部门也不会出现在结果中。

### 适合场景

内连接适合这种需求：

> 只查询两边都能对应上的数据。

例如：

* 查询有部门的员工。
* 查询有订单的客户。
* 查询有明细的订单。
* 查询有分类的商品。

## 5.4 左上图：左外连接 `A`

左外连接会保留左表 A 的全部记录。

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id;
```

这条 SQL 的结果是：

```text
employees 全部员工
+
能匹配到的部门资料
```

也就是：

```text
A
```

如果某个员工没有对应部门，员工仍然会被保留，只是部门表字段会显示为 `NULL`。

### 结果理解

左外连接包含两部分：

```text
A ∩ B
+
A - A∩B
```

所以要特别注意：

> 左外连接不是左表独有。
> 左外连接包含匹配成功的数据，也包含左表没有匹配成功的数据。

### 适合场景

左外连接适合这种需求：

> 左表是主表，左表资料必须完整显示；右表有资料就补上，没有资料就显示 `NULL`。

例如：

* 查询所有员工及其部门。
* 查询所有客户及其订单。
* 查询所有商品及其分类。
* 查询所有学生及其班级。

## 5.5 右上图：右外连接 `B`

右外连接会保留右表 B 的全部记录。

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;
```

这条 SQL 的结果是：

```text
departments 全部部门
+
能匹配到的员工资料
```

也就是：

```text
B
```

如果某个部门没有任何员工，部门仍然会被保留，只是员工表字段会显示为 `NULL`。

### 结果理解

右外连接包含两部分：

```text
A ∩ B
+
B - A∩B
```

所以要特别注意：

> 右外连接不是右表独有。
> 右外连接包含匹配成功的数据，也包含右表没有匹配成功的数据。

### 右外连接可以改写成左外连接

这条右外连接：

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;
```

可以改写成左外连接：

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM departments d
LEFT JOIN employees e
    ON e.department_id = d.department_id;
```

实际开发中，很多人更习惯使用 `LEFT JOIN`，因为从左到右阅读比较直观：

```text
以左表为主，往右补数据。
```

## 5.6 左中图：左表独有 `A - A∩B`

左表独有表示：

> 左表有，但右表没有匹配上的数据。

也就是：

```text
A - A∩B
```

实现方式是：

1. 先使用 `LEFT JOIN` 保留左表全部数据。
2. 再通过 `WHERE 右表字段 IS NULL` 筛出没有匹配到右表的记录。

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id
WHERE d.department_id IS NULL;
```

这条 SQL 的含义是：

> 查询员工表中存在，但无法匹配到部门表的员工。

例如：

* 员工没有部门。
* 员工的部门编号在部门表中不存在。
* 员工资料和部门资料之间出现异常。

### 为什么要加 `WHERE d.department_id IS NULL`

`LEFT JOIN` 本身会返回：

```text
A ∩ B
+
A - A∩B
```

如果只要左表独有，就必须排除交集。

右表没有匹配时，右表字段会是 `NULL`，所以可以写：

```sql
WHERE d.department_id IS NULL
```

这样就只剩下：

```text
A - A∩B
```

### IS NULL 应该筛哪一个字段

建议筛选右表中不应该为 `NULL` 的主键或唯一键字段，例如：

```sql
d.department_id IS NULL
```

不建议随便筛一个业务字段，例如：

```sql
d.department_name IS NULL
```

因为业务字段本身可能允许为空，容易造成误判。

## 5.7 右中图：右表独有 `B - A∩B`

右表独有表示：

> 右表有，但左表没有匹配上的数据。

也就是：

```text
B - A∩B
```

实现方式是：

1. 先使用 `RIGHT JOIN` 保留右表全部数据。
2. 再通过 `WHERE 左表字段 IS NULL` 筛出没有匹配到左表的记录。

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;
```

这条 SQL 的含义是：

> 查询部门表中存在，但没有任何员工匹配到的部门。

例如：

* 没有员工的部门。
* 部门资料已经建立，但还没有分配员工。
* 部门和员工之间没有对应关系。

### 为什么筛 `e.employee_id IS NULL`

右表没有匹配到左表时，左表字段都会是 `NULL`。

这里推荐使用左表的主键字段：

```sql
e.employee_id IS NULL
```

而不是：

```sql
e.department_id IS NULL
```

原因是：`employee_id` 通常是员工表主键，不应该为空，更适合作为判断“左表是否匹配成功”的依据。

### 用 LEFT JOIN 改写右表独有

如果你不想使用 `RIGHT JOIN`，也可以调整表顺序，用 `LEFT JOIN` 表达同样的意思：

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM departments d
LEFT JOIN employees e
    ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;
```

这通常更容易阅读：

```text
以 departments 为主，找没有员工匹配的部门。
```

## 5.8 左下图：满外连接 `A ∪ B`

满外连接表示：

> 保留左右两张表的全部结果。

也就是：

```text
A ∪ B
```

它包含三部分：

```text
A ∩ B
+
A - A∩B
+
B - A∩B
```

标准 SQL 可以写：

```sql
SELECT 字段列表
FROM A
FULL OUTER JOIN B
    ON A.关联字段 = B.关联字段;
```

但是需要特别注意：

> MySQL 不支持直接使用 `FULL OUTER JOIN`。

所以在 MySQL 中，通常要用 `LEFT JOIN`、`RIGHT JOIN` 和 `UNION` / `UNION ALL` 来模拟。

## 5.8.1 写法一：LEFT JOIN + UNION + RIGHT JOIN

这是最容易理解的写法：

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id

UNION

SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;
```

这条 SQL 的逻辑是：

1. `LEFT JOIN` 取得左表全部结果。
2. `RIGHT JOIN` 取得右表全部结果。
3. `UNION` 合并两批结果。
4. `UNION` 会去除重复的交集部分。

这种写法直观，但 `UNION` 会做去重。

## 5.8.2 写法二：LEFT JOIN + UNION ALL + 右表独有

如果想避免 `UNION` 的去重成本，可以改成：

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id

UNION ALL

SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;
```

这条 SQL 的逻辑是：

```text
左外连接结果
+
右表独有结果
=
满外连接结果
```

也就是：

```text
A
+
(B - A∩B)
=
A ∪ B
```

这里可以安全使用 `UNION ALL`，因为第二段只取右表独有数据，不会再包含交集，所以不会和第一段重复。

### 不建议的写法

不要直接写成：

```sql
SELECT ...
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id

UNION ALL

SELECT ...
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;
```

原因是：

> `LEFT JOIN` 和 `RIGHT JOIN` 都会包含交集部分，直接 `UNION ALL` 会让匹配成功的数据重复出现。

如果要这样写，就应该使用 `UNION` 去重；
如果要用 `UNION ALL`，就要让其中一段只取独有部分。

## 5.9 右下图：左右独有 `A ∪ B - A∩B`

这一部分表示：

> 只保留左右两边各自独有的数据，不要匹配成功的数据。

也就是：

```text
A ∪ B - A∩B
```

也可以理解为：

```text
(A - A∩B) ∪ (B - A∩B)
```

SQL 写法：

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id
WHERE d.department_id IS NULL

UNION ALL

SELECT
    e.employee_id,
    e.last_name,
    e.department_id AS employee_department_id,
    d.department_id AS department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;
```

这条 SQL 的逻辑是：

1. 第一段查询左表独有：`A - A∩B`。
2. 第二段查询右表独有：`B - A∩B`。
3. 用 `UNION ALL` 合并。
4. 因为左右独有本来就不会重叠，所以可以使用 `UNION ALL`。

### 适合场景

这种查询适合找两张表之间“不匹配”的资料，例如：

* 有员工资料但没有对应部门。
* 有部门资料但没有任何员工。
* 两张表之间需要做数据一致性检查。
* 找出关联关系异常的数据。

## 5.10 UNION 与 UNION ALL 的选择

在这一节中，`UNION` 和 `UNION ALL` 的选择非常关键。

| 场景                               | 建议写法           | 原因            |
| -------------------------------- | -------------- | ------------- |
| `LEFT JOIN` 全部 + `RIGHT JOIN` 全部 | `UNION`        | 两边都会包含交集，需要去重 |
| `LEFT JOIN` 全部 + 右表独有            | `UNION ALL`    | 第二段不包含交集，不会重复 |
| 左表独有 + 右表独有                      | `UNION ALL`    | 两边本来就不会重叠     |
| 不确定是否重复                          | 先用 `UNION`     | 结果较安全，但有去重成本  |
| 明确不可能重复                          | 可用 `UNION ALL` | 避免不必要的去重成本    |

### 重点原则

选择时不要只背性能结论，而要先判断：

> 两段查询结果会不会包含同一批交集数据？

如果会重复：

```text
使用 UNION
```

如果不会重复：

```text
可以使用 UNION ALL
```

## 5.11 通用模板小结

### 5.11.1 内连接：`A ∩ B`

```sql
SELECT 字段列表
FROM A
JOIN B
    ON A.关联字段 = B.关联字段;
```

### 5.11.2 左外连接：`A`

```sql
SELECT 字段列表
FROM A
LEFT JOIN B
    ON A.关联字段 = B.关联字段;
```

### 5.11.3 右外连接：`B`

```sql
SELECT 字段列表
FROM A
RIGHT JOIN B
    ON A.关联字段 = B.关联字段;
```

也可以改写成：

```sql
SELECT 字段列表
FROM B
LEFT JOIN A
    ON A.关联字段 = B.关联字段;
```

### 5.11.4 左表独有：`A - A∩B`

```sql
SELECT 字段列表
FROM A
LEFT JOIN B
    ON A.关联字段 = B.关联字段
WHERE B.主键字段 IS NULL;
```

### 5.11.5 右表独有：`B - A∩B`

```sql
SELECT 字段列表
FROM A
RIGHT JOIN B
    ON A.关联字段 = B.关联字段
WHERE A.主键字段 IS NULL;
```

或改写成：

```sql
SELECT 字段列表
FROM B
LEFT JOIN A
    ON A.关联字段 = B.关联字段
WHERE A.主键字段 IS NULL;
```

### 5.11.6 满外连接：`A ∪ B`

写法一：使用 `UNION` 去重。

```sql
SELECT 字段列表
FROM A
LEFT JOIN B
    ON A.关联字段 = B.关联字段

UNION

SELECT 字段列表
FROM A
RIGHT JOIN B
    ON A.关联字段 = B.关联字段;
```

写法二：使用 `UNION ALL`，但第二段只取右表独有。

```sql
SELECT 字段列表
FROM A
LEFT JOIN B
    ON A.关联字段 = B.关联字段

UNION ALL

SELECT 字段列表
FROM A
RIGHT JOIN B
    ON A.关联字段 = B.关联字段
WHERE A.主键字段 IS NULL;
```

### 5.11.7 左右独有：`A ∪ B - A∩B`

```sql
SELECT 字段列表
FROM A
LEFT JOIN B
    ON A.关联字段 = B.关联字段
WHERE B.主键字段 IS NULL

UNION ALL

SELECT 字段列表
FROM A
RIGHT JOIN B
    ON A.关联字段 = B.关联字段
WHERE A.主键字段 IS NULL;
```

## 5.12 如何判断该用哪一种 JOIN 图示

看到需求时，可以按下面问题判断。

### 第一步：是否只要匹配成功的数据？

如果是，用：

```sql
JOIN
```

对应：

```text
A ∩ B
```

### 第二步：是否要保留左表全部数据？

如果是，用：

```sql
LEFT JOIN
```

对应：

```text
A
```

### 第三步：是否要保留右表全部数据？

如果是，用：

```sql
RIGHT JOIN
```

或者调整表顺序后用：

```sql
LEFT JOIN
```

对应：

```text
B
```

### 第四步：是否只要左表没有匹配的数据？

如果是，用：

```sql
LEFT JOIN ... WHERE B.主键 IS NULL
```

对应：

```text
A - A∩B
```

### 第五步：是否只要右表没有匹配的数据？

如果是，用：

```sql
RIGHT JOIN ... WHERE A.主键 IS NULL
```

对应：

```text
B - A∩B
```

### 第六步：是否要两边全部数据？

如果是，要模拟满外连接：

```sql
LEFT JOIN
UNION
RIGHT JOIN
```

或者：

```sql
LEFT JOIN
UNION ALL
右表独有
```

对应：

```text
A ∪ B
```

### 第七步：是否只要两边不匹配的数据？

如果是，用：

```sql
左表独有
UNION ALL
右表独有
```

对应：

```text
A ∪ B - A∩B
```

## 5.13 常见错误示例

### 错误 1：把左外连接误认为左表独有

错误理解：

```sql
SELECT ...
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id;
```

这不是左表独有。

它的结果是：

```text
A ∩ B
+
A - A∩B
```

如果只要左表独有，必须加：

```sql
WHERE d.department_id IS NULL
```

### 错误 2：把右外连接误认为右表独有

错误理解：

```sql
SELECT ...
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;
```

这不是右表独有。

它的结果是：

```text
A ∩ B
+
B - A∩B
```

如果只要右表独有，必须加：

```sql
WHERE e.employee_id IS NULL
```

### 错误 3：MySQL 中直接写 FULL OUTER JOIN

错误写法：

```sql
SELECT *
FROM employees e
FULL OUTER JOIN departments d
    ON e.department_id = d.department_id;
```

MySQL 不支持这种写法。

应该改用：

```sql
LEFT JOIN
UNION
RIGHT JOIN
```

或者：

```sql
LEFT JOIN
UNION ALL
右表独有
```

### 错误 4：直接用 UNION ALL 合并左右外连接

不建议写法：

```sql
SELECT ...
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id

UNION ALL

SELECT ...
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;
```

问题是：

```text
匹配成功的交集会出现两次。
```

如果两段都包含交集，应该用 `UNION` 去重；
如果要用 `UNION ALL`，第二段应改成只取右表独有。

### 错误 5：IS NULL 筛选字段选错

不建议：

```sql
WHERE d.department_name IS NULL
```

如果 `department_name` 本身允许为空，就可能误判。

建议优先使用右表主键或唯一键：

```sql
WHERE d.department_id IS NULL
```

同理，筛左表是否没有匹配时，建议使用左表主键：

```sql
WHERE e.employee_id IS NULL
```

## 常见混淆点

* 7 种 JOIN 图示不是 7 种独立 SQL 语法，而是 7 种常见结果集组合。
* 内连接对应 `A ∩ B`。
* 左外连接对应 `A`，不是 `A - A∩B`。
* 右外连接对应 `B`，不是 `B - A∩B`。
* 左表独有要用 `LEFT JOIN` 加 `WHERE B.主键 IS NULL`。
* 右表独有要用 `RIGHT JOIN` 加 `WHERE A.主键 IS NULL`。
* `IS NULL` 应尽量筛被排除一侧的主键或唯一键，不要随便筛可能为空的业务字段。
* MySQL 不支持直接写 `FULL OUTER JOIN`。
* 模拟满外连接时，`LEFT JOIN UNION RIGHT JOIN` 可以用 `UNION` 去重。
* 如果使用 `UNION ALL` 模拟满外连接，要确保其中一段只取独有数据，避免交集重复。
* `UNION` 会去重，`UNION ALL` 不会去重。
* 右外连接通常可以通过调整表顺序改写成左外连接。
* 看到 JOIN 图示时，不要先背 SQL，要先判断你要保留哪一块结果集。

## 常见回查问题

* 7 种 JOIN 图示分别对应什么 SQL？
* 内连接对应图上的哪一块？
* 左外连接是不是左表独有？
* 右外连接是不是右表独有？
* 为什么左表独有要写 `LEFT JOIN ... WHERE B.主键 IS NULL`？
* 为什么右表独有要写 `RIGHT JOIN ... WHERE A.主键 IS NULL`？
* MySQL 为什么不能直接写 `FULL OUTER JOIN`？
* MySQL 如何模拟满外连接？
* `LEFT JOIN UNION RIGHT JOIN` 为什么通常用 `UNION`？
* 什么时候可以用 `UNION ALL` 模拟满外连接？
* `A ∪ B` 和 `A ∪ B - A∩B` 差在哪里？
* `IS NULL` 应该筛哪一侧的字段？

## 一句话抓核心

7 种 JOIN 图示的本质，是在决定要保留 `A∩B`、`A`、`B`、`A - A∩B`、`B - A∩B`、`A∪B`，还是 `A∪B - A∩B`；MySQL 中这些结果可以通过 `JOIN`、`IS NULL`、`UNION` 和 `UNION ALL` 组合实现，但要特别注意 `UNION ALL` 不能重复包含交集。

## 小结

这一节需要记住：

* `INNER JOIN` 对应 `A ∩ B`。
* `LEFT JOIN` 对应左表全部结果 `A`。
* `RIGHT JOIN` 对应右表全部结果 `B`。
* 左表独有是 `A - A∩B`，要用 `LEFT JOIN` 后筛右表主键为 `NULL`。
* 右表独有是 `B - A∩B`，要用 `RIGHT JOIN` 后筛左表主键为 `NULL`。
* 满外连接是 `A ∪ B`，MySQL 不支持直接写 `FULL OUTER JOIN`。
* MySQL 可以用 `LEFT JOIN UNION RIGHT JOIN` 模拟满外连接。
* 如果使用 `UNION ALL` 模拟满外连接，应写成 `LEFT JOIN 全部 + 右表独有`，避免交集重复。
* 左右独有是 `A ∪ B - A∩B`，可以用左表独有 `UNION ALL` 右表独有实现。
* 看到 JOIN 图示时，先判断你要保留哪一块结果集，再决定 SQL 写法。

---
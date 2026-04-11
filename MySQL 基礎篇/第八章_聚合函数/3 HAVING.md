# 3 HAVING

> 所属章节：MySQL 基础篇 / 第 08 章 聚合函数

## 本节导读

本节说明 `HAVING` 的用途，也就是如何对分组后的结果继续筛选。它的核心不是替代 `WHERE`，而是在 `GROUP BY` 之后处理聚合结果，因此这篇会重点对比 `WHERE` 与 `HAVING` 的执行阶段、可用条件与性能差异。

建议阅读顺序：

1. 先掌握 `HAVING` 与 `WHERE` 的本质区别。
2. 再看 `HAVING` 的基本写法与合法用法。
3. 最后回查 `WHERE` 和 `HAVING` 在开发中的组合使用方式。

## 前置知识

- 建议先读：[2 GROUP BY](./2%20GROUP%20BY.md)

## 关键字

`HAVING` `WHERE` `GROUP BY` `分组过滤` `聚合函数`

## 建议回查情境

- 想确认为什么聚合函数不能写在 `WHERE` 中时。
- 忘记 `HAVING` 和 `WHERE` 分别作用在哪个阶段时。
- 想快速比较 `WHERE` 和 `HAVING` 的性能差异时。
- 需要回查分组查询中该把条件写在 `WHERE` 还是 `HAVING` 时。

## 内容导航

- [3.1 基本使用](#31-基本使用)
- [3.2 WHERE 和 HAVING 的对比](#32-where-和-having-的对比)

## HAVING vs WHERE

- `WHERE` 在 `GROUP BY` 之前使用，不能用来筛选聚合函数结果。
- `HAVING` 在 `GROUP BY` 之后使用，可用于筛选聚合函数结果。

## 3.1 基本使用

![HAVING 过滤分组示意图](./images/1554981808091.png)

`HAVING` 子句用于过滤分组后的结果，理解时可以把它记成“对已经分好的组再做一次筛选”。

使用 `HAVING` 时需要注意：

1. 行已经先被分组。
2. 查询中已经使用了聚合函数。
3. 只有满足 `HAVING` 条件的分组会被显示出来。
4. `HAVING` 不能单独使用，必须和 `GROUP BY` 一起使用。

```sql
SELECT
    department_id,
    MAX(salary)
FROM employees
GROUP BY department_id
HAVING MAX(salary) > 10000;
```

![HAVING 查询结果](./images/1554981824564.png)

### 非法使用示例

不能在 `WHERE` 子句中使用聚合函数，例如下面的写法是错误的：

```sql
SELECT
    department_id,
    AVG(salary)
FROM employees
WHERE AVG(salary) > 8000
GROUP BY department_id;
```

![WHERE 中错误使用聚合函数](./images/1554981724375.png)

## 3.2 WHERE 和 HAVING 的对比

### 区别 1：可用的筛选条件不同

`WHERE` 可以直接使用表中的字段作为筛选条件，但不能使用分组后的聚合函数结果作为筛选条件；`HAVING` 必须和 `GROUP BY` 配合使用，可以把分组字段和聚合函数结果作为筛选条件。

这决定了当查询需要先分组、再统计、再过滤时，`HAVING` 可以完成 `WHERE` 做不到的事情。原因在于 SQL 的执行顺序中，`WHERE` 位于 `GROUP BY` 之前，因此它无法筛选分组结果；而 `HAVING` 位于 `GROUP BY` 之后，所以可以对分组后的结果集继续筛选。另外，被 `WHERE` 排除的记录不会再参与后续分组。

### 区别 2：执行效率不同

如果需要通过连接从关联表中获取数据，`WHERE` 是先筛选、后连接；`HAVING` 是先连接、后筛选。

这意味着在关联查询中，`WHERE` 通常比 `HAVING` 更高效。因为 `WHERE` 可以先缩小数据集，再参与连接；而 `HAVING` 往往需要先准备出较大的结果集，再在最后阶段进行筛选，因此资源消耗更高、执行效率也更低。

小结如下：

| 子句 | 优点 | 缺点 |
| --- | --- | --- |
| `WHERE` | 先筛选数据再关联，执行效率高 | 不能使用分组中的聚合函数进行筛选 |
| `HAVING` | 可以使用分组中的聚合函数 | 在最后的结果集中进行筛选，执行效率较低 |

### 开发中的选择

`WHERE` 和 `HAVING` 不是互相排斥的，可以在同一个查询中同时使用。

使用原则是：

- 包含分组统计函数的条件写在 `HAVING` 中。
- 普通条件优先写在 `WHERE` 中。

这样既能利用 `WHERE` 先筛选数据带来的效率优势，也能保留 `HAVING` 对聚合结果进行过滤的能力。在数据量较大时，这种写法的执行效率差异会更明显。

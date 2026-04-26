# 4.4 日期字段提取与 EXTRACT

> - 所属章节：[第七章_单行函数 / 4 日期和时间函数](./README.md)  
> - 关键字：EXTRACT、YEAR、MONTH、DAY、HOUR、MINUTE、SECOND、WEEK、QUARTER、YEAR_MONTH、DAY_HOUR、MINUTE_SECOND、日期字段提取、复合时间字段  
> - 建议回查情境：需要从日期时间中提取指定部分；想用统一语法取年、月、日、时、分、秒、季度、周数；需要一次取出复合时间字段，例如 `YEAR_MONTH`、`MINUTE_SECOND` 时。

## 本节导读

`EXTRACT(type FROM date)` 是日期时间函数中很实用的一种统一写法。

前一节介绍了很多独立函数，例如：

```sql
YEAR(date)
MONTH(date)
DAY(date)
HOUR(time)
MINUTE(time)
SECOND(time)
```

`EXTRACT()` 的想法是：

```text
不用记一堆独立函数名，而是统一用 EXTRACT()，再指定要提取的部分。
```

例如：

```sql
EXTRACT(YEAR FROM order_time)
EXTRACT(MONTH FROM order_time)
EXTRACT(MINUTE_SECOND FROM order_time)
```

它特别适合想统一 SQL 风格，或需要提取复合时间字段的场景。

---

## 你会在这篇学到什么

- `EXTRACT(type FROM date)` 的基本语法。
- `EXTRACT()` 和 `YEAR()`、`MONTH()`、`DAY()` 这类独立函数的关系。
- 常见 `type` 取值，例如 `YEAR`、`MONTH`、`DAY`、`HOUR`、`MINUTE`、`SECOND`。
- 复合 `type` 取值，例如 `YEAR_MONTH`、`DAY_HOUR`、`MINUTE_SECOND`。
- `EXTRACT()` 在报表统计、日期拆解、时间字段分析中的实务用法。
- 为什么在 `WHERE` 中使用 `EXTRACT()` 过滤索引栏位也要谨慎。

---

## 快速定位

| 想解决的问题 | 优先使用 |
| --- | --- |
| 用统一写法取得年份 | `EXTRACT(YEAR FROM date)` |
| 用统一写法取得月份 | `EXTRACT(MONTH FROM date)` |
| 用统一写法取得日期 | `EXTRACT(DAY FROM date)` |
| 用统一写法取得小时 | `EXTRACT(HOUR FROM datetime)` |
| 用统一写法取得分钟 | `EXTRACT(MINUTE FROM datetime)` |
| 用统一写法取得秒 | `EXTRACT(SECOND FROM datetime)` |
| 取得季度 | `EXTRACT(QUARTER FROM date)` |
| 取得周数 | `EXTRACT(WEEK FROM date)` |
| 一次取得年月 | `EXTRACT(YEAR_MONTH FROM date)` |
| 一次取得分秒 | `EXTRACT(MINUTE_SECOND FROM datetime)` |

---

## 快速回查表

| 写法 | 作用 | 示例结果概念 | 高频程度 |
| --- | --- | --- | --- |
| `EXTRACT(YEAR FROM date)` | 提取年份 | `2026` | 高频 |
| `EXTRACT(MONTH FROM date)` | 提取月份 | `4` | 高频 |
| `EXTRACT(DAY FROM date)` | 提取日 | `26` | 高频 |
| `EXTRACT(HOUR FROM datetime)` | 提取小时 | `14` | 高频 |
| `EXTRACT(MINUTE FROM datetime)` | 提取分钟 | `30` | 高频 |
| `EXTRACT(SECOND FROM datetime)` | 提取秒 | `25` | 高频 |
| `EXTRACT(QUARTER FROM date)` | 提取季度 | `1` 到 `4` | 中频 |
| `EXTRACT(WEEK FROM date)` | 提取周数 | 一年中的第几周 | 中频 |
| `EXTRACT(YEAR_MONTH FROM date)` | 提取年月组合 | `202604` | 中频 |
| `EXTRACT(DAY_HOUR FROM datetime)` | 提取日与小时组合 | 复合数字 | 低到中频 |
| `EXTRACT(MINUTE_SECOND FROM datetime)` | 提取分秒组合 | 例如 `3025` | 中频 |

---

## 4.4.1 EXTRACT() 基本语法

```sql
EXTRACT(type FROM date)
```

其中：

| 部分 | 说明 |
| --- | --- |
| `type` | 要提取的日期时间部分 |
| `date` | 日期、时间或日期时间表达式 |

示例：

```sql
SELECT EXTRACT(YEAR FROM '2026-04-26 14:30:25') AS year_value;
```

结果：

```text
2026
```

---

## 4.4.2 基础字段提取

### 示例

```sql
SELECT
    EXTRACT(YEAR FROM '2026-04-26 14:30:25')   AS y,
    EXTRACT(MONTH FROM '2026-04-26 14:30:25')  AS m,
    EXTRACT(DAY FROM '2026-04-26 14:30:25')    AS d,
    EXTRACT(HOUR FROM '2026-04-26 14:30:25')   AS h,
    EXTRACT(MINUTE FROM '2026-04-26 14:30:25') AS i,
    EXTRACT(SECOND FROM '2026-04-26 14:30:25') AS s;
```

结果概念：

| 表达式 | 结果 |
| --- | --- |
| `EXTRACT(YEAR FROM ...)` | `2026` |
| `EXTRACT(MONTH FROM ...)` | `4` |
| `EXTRACT(DAY FROM ...)` | `26` |
| `EXTRACT(HOUR FROM ...)` | `14` |
| `EXTRACT(MINUTE FROM ...)` | `30` |
| `EXTRACT(SECOND FROM ...)` | `25` |

---

## 4.4.3 EXTRACT() 与独立函数的对应关系

很多 `EXTRACT()` 写法可以对应到独立函数。

| `EXTRACT()` 写法 | 类似独立函数 |
| --- | --- |
| `EXTRACT(YEAR FROM date)` | `YEAR(date)` |
| `EXTRACT(MONTH FROM date)` | `MONTH(date)` |
| `EXTRACT(DAY FROM date)` | `DAY(date)` |
| `EXTRACT(HOUR FROM time)` | `HOUR(time)` |
| `EXTRACT(MINUTE FROM time)` | `MINUTE(time)` |
| `EXTRACT(SECOND FROM time)` | `SECOND(time)` |
| `EXTRACT(QUARTER FROM date)` | `QUARTER(date)` |
| `EXTRACT(WEEK FROM date)` | `WEEK(date)` |

### 什么时候用 EXTRACT()？

适合：

- 想统一 SQL 风格。
- 需要提取复合字段。
- 看到标准 SQL 或跨数据库风格写法。
- 想让「提取日期字段」的意图更明显。

### 什么时候用独立函数？

适合：

- 写法更短。
- 团队习惯 `YEAR()`、`MONTH()`。
- 初学阶段更容易阅读。

两种都可以，重点是团队风格一致。

---

## 4.4.4 复合字段提取

`EXTRACT()` 的优势之一，是可以提取复合时间字段。

### 常见复合 type

| type | 说明 | 示例概念 |
| --- | --- | --- |
| `YEAR_MONTH` | 年月组合 | `202604` |
| `DAY_HOUR` | 日与小时组合 | 例如 `2614` |
| `DAY_MINUTE` | 日、小时、分钟组合 | 复合数字 |
| `DAY_SECOND` | 日、小时、分钟、秒组合 | 复合数字 |
| `HOUR_MINUTE` | 小时与分钟组合 | 例如 `1430` |
| `HOUR_SECOND` | 小时、分钟、秒组合 | 例如 `143025` |
| `MINUTE_SECOND` | 分钟与秒组合 | 例如 `3025` |

### 示例

```sql
SELECT
    EXTRACT(YEAR_MONTH FROM '2026-04-26 14:30:25') AS ym,
    EXTRACT(HOUR_MINUTE FROM '2026-04-26 14:30:25') AS hm,
    EXTRACT(MINUTE_SECOND FROM '2026-04-26 14:30:25') AS ms;
```

结果概念：

| 表达式 | 结果概念 |
| --- | --- |
| `EXTRACT(YEAR_MONTH FROM ...)` | `202604` |
| `EXTRACT(HOUR_MINUTE FROM ...)` | `1430` |
| `EXTRACT(MINUTE_SECOND FROM ...)` | `3025` |

---

## 4.4.5 实务场景

### 场景 1：按年份统计订单

```sql
SELECT
    EXTRACT(YEAR FROM order_time) AS order_year,
    COUNT(*) AS order_count
FROM orders
GROUP BY EXTRACT(YEAR FROM order_time);
```

---

### 场景 2：按年月统计订单

```sql
SELECT
    EXTRACT(YEAR_MONTH FROM order_time) AS order_year_month,
    COUNT(*) AS order_count
FROM orders
GROUP BY EXTRACT(YEAR_MONTH FROM order_time)
ORDER BY order_year_month;
```

结果可能类似：

| order_year_month | order_count |
| --- | --- |
| 202601 | 120 |
| 202602 | 135 |
| 202603 | 150 |

---

### 场景 3：按小时统计登入量

```sql
SELECT
    EXTRACT(HOUR FROM login_time) AS login_hour,
    COUNT(*) AS login_count
FROM login_log
GROUP BY EXTRACT(HOUR FROM login_time)
ORDER BY login_hour;
```

---

### 场景 4：取当前时间的分秒

```sql
SELECT EXTRACT(MINUTE_SECOND FROM NOW()) AS minute_second_value;
```

---

## 4.4.6 使用提醒

### 1. EXTRACT() 适合统一风格

如果一段 SQL 中要取多个日期字段，用 `EXTRACT()` 可以保持风格一致：

```sql
SELECT
    EXTRACT(YEAR FROM created_at) AS y,
    EXTRACT(MONTH FROM created_at) AS m,
    EXTRACT(DAY FROM created_at) AS d
FROM users;
```

---

### 2. 复合字段结果通常是数字组合，不是日期类型

例如：

```sql
EXTRACT(YEAR_MONTH FROM '2026-04-26')
```

结果概念是：

```text
202604
```

它不是一个真正的日期类型，而是提取后的数值组合。

---

### 3. 在 WHERE 中对栏位使用 EXTRACT() 要谨慎

不推荐大表中随意写：

```sql
SELECT *
FROM orders
WHERE EXTRACT(YEAR FROM order_time) = 2026;
```

更常见的范围条件：

```sql
SELECT *
FROM orders
WHERE order_time >= '2026-01-01'
  AND order_time <  '2027-01-01';
```

原因是对索引栏位套函数可能影响索引使用。

---

### 4. EXTRACT(WEEK FROM date) 仍要注意周数规则

`EXTRACT(WEEK FROM date)` 与 `WEEK(date)` 一样，涉及周数定义时要确认系统规则。

---

## 4.4.7 常见混淆点

### 混淆点 1：EXTRACT() 不是格式化函数

`EXTRACT()` 是把日期中的某个部分取出来。  
它不是用来把日期显示成指定格式。

格式化日期应该看：

```sql
DATE_FORMAT(date, fmt)
```

---

### 混淆点 2：YEAR_MONTH 的结果不是 `YYYY-MM`

```sql
SELECT EXTRACT(YEAR_MONTH FROM '2026-04-26');
```

结果概念是：

```text
202604
```

不是：

```text
2026-04
```

如果要 `2026-04` 这种显示格式，应使用 `DATE_FORMAT()`：

```sql
SELECT DATE_FORMAT('2026-04-26', '%Y-%m');
```

---

### 混淆点 3：EXTRACT() 和 YEAR() 等函数很多时候可以互换，但风格不同

```sql
EXTRACT(YEAR FROM order_time)
YEAR(order_time)
```

两者都能取年份。  
选择哪个通常取决于团队风格、可读性与是否需要复合字段。

---

### 混淆点 4：EXTRACT() 用在筛选条件也可能影响索引

```sql
WHERE EXTRACT(MONTH FROM order_time) = 4
```

这种写法容易理解，但大表中要考虑是否改成范围条件。

---

## 4.4.8 自我检查题

### 问题 1

`EXTRACT(YEAR FROM '2026-04-26')` 的结果是什么？

答案：`2026`。

---

### 问题 2

`EXTRACT(YEAR_MONTH FROM '2026-04-26')` 的结果概念是什么？

答案：`202604`。

---

### 问题 3

如果要把日期显示成 `2026-04`，应该使用 `EXTRACT(YEAR_MONTH FROM date)` 还是 `DATE_FORMAT(date, '%Y-%m')`？

答案：应该使用 `DATE_FORMAT(date, '%Y-%m')`。

---

### 问题 4

下面 SQL 有什么潜在问题？

```sql
SELECT *
FROM orders
WHERE EXTRACT(YEAR FROM order_time) = 2026;
```

答案：如果 `order_time` 有索引，对栏位套 `EXTRACT()` 可能影响索引使用。较常见做法是改成日期范围。

---

## 4.4.9 本节总结

本节可以浓缩成下面几句话：

1. `EXTRACT(type FROM date)` 用统一语法从日期时间中提取指定字段。
2. `EXTRACT(YEAR FROM date)` 类似 `YEAR(date)`，`EXTRACT(MONTH FROM date)` 类似 `MONTH(date)`。
3. `EXTRACT()` 的优势是风格统一，并且支持复合字段，例如 `YEAR_MONTH`、`MINUTE_SECOND`。
4. `EXTRACT()` 不是格式化函数，如果要输出 `YYYY-MM` 这类格式，要用 `DATE_FORMAT()`。
5. 在 `WHERE` 中对索引栏位使用 `EXTRACT()` 要谨慎，实务中常改用范围条件。

如果只记一句话：

> `EXTRACT()` 是统一的日期字段提取语法，适合取年、月、日、时、分、秒和复合时间字段。

---

## 返回导航

- [回到 4 日期和时间函数](./README.md)
- [上一节：03 获取月份星期天数等信息](./03%20获取月份星期天数等信息.md)
- [下一节：05 时间与秒数转换](./05%20时间与秒数转换.md)

--- 
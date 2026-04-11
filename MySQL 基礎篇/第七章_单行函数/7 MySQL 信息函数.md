# 7 MySQL 信息函数

> 所属章节：[第七章_单行函数](./README.md)
> 关键字：信息函数、`VERSION()`、`CONNECTION_ID()`、`DATABASE()`、`SCHEMA()`、`USER()`、`CURRENT_USER()`、`SYSTEM_USER()`、`SESSION_USER()`、`CHARSET()`、`COLLATION()`
> 建议回查情境：想确认当前数据库、当前连接用户、MySQL 版本、字符集或排序规则，或忘了这些信息函数该怎么写时

## 本节导读

这一节整理 MySQL 中常见的信息函数。它们的重点不是对数据做运算，而是帮助你快速确认“当前连接环境是什么样子”，例如当前在哪个数据库、当前使用什么账号连接、服务器版本是多少，以及某个字符串值采用什么字符集和排序规则。

第一次阅读时，建议先把这些函数分成三组来记：环境信息、当前连接与用户信息、字符集与排序规则。复习时如果只是想查“我现在连到哪一个数据库”或“这段字符串到底用什么字符集”，可以直接看“快速定位”和函数总表。

## 你会在这篇学到什么

- `VERSION()`、`DATABASE()`、`USER()` 等信息函数分别用来确认什么。
- 哪些函数适合查看当前连接环境，哪些适合查看字符集与比较规则。
- `DATABASE()` 与 `SCHEMA()`、`USER()` 与 `CURRENT_USER()` 等函数在教材中的基本定位。
- 这些函数在 MySQL 中的基本调用方式与返回结果示例。

## 快速定位

- 想看当前 MySQL 版本：看 `VERSION()`
- 想看当前连接编号：看 `CONNECTION_ID()`
- 想确认当前所在数据库：看 `DATABASE()`、`SCHEMA()`
- 想看当前连接使用的用户信息：看 `USER()`、`CURRENT_USER()`、`SYSTEM_USER()`、`SESSION_USER()`
- 想看字符串的字符集或排序规则：看 `CHARSET()`、`COLLATION()`

## 先分清三类信息

### 环境信息

这类函数用来确认当前数据库环境本身，例如 MySQL 版本号、当前连接编号，以及当前命令行所在的数据库。

### 连接与用户信息

这类函数用来确认“是谁在连接数据库”。在排查权限、连接来源或执行环境时，经常需要先看这些信息。

### 字符集与排序规则

这类函数用来确认字符串值所使用的字符集与比较规则。遇到乱码、大小写比较异常、排序结果不符合预期时，这组函数很有用。

## MySQL 信息函数总表

| 函数 | 用法 |
| --- | --- |
| `VERSION()` | 返回当前 MySQL 的版本号 |
| `CONNECTION_ID()` | 返回当前 MySQL 服务器的连接数 |
| `DATABASE()`、`SCHEMA()` | 返回 MySQL 命令行当前所在的数据库 |
| `USER()`、`CURRENT_USER()`、`SYSTEM_USER()`、`SESSION_USER()` | 返回当前连接 MySQL 的用户名，返回结果格式为“主机名@用户名” |
| `CHARSET(value)` | 返回字符串 `value` 的字符集 |
| `COLLATION(value)` | 返回字符串 `value` 的比较规则 |

## 使用提醒

- `DATABASE()` 与 `SCHEMA()` 都用于查看当前所在数据库，适合在执行 SQL 前先确认上下文。
- `USER()`、`CURRENT_USER()`、`SYSTEM_USER()`、`SESSION_USER()` 都与当前连接身份有关，排查权限问题时很常用。
- `CHARSET()` 和 `COLLATION()` 关注的是字符串值本身的字符集与比较规则，不是整个数据库的全局配置。

## 示例

### `DATABASE()`

```sql
SELECT DATABASE();

+------------+
| DATABASE() |
+------------+
| test       |
+------------+
1 row in set (0.00 sec)
```

### `USER()`、`CURRENT_USER()`、`SYSTEM_USER()`、`SESSION_USER()`

```sql
SELECT USER(), CURRENT_USER(), SYSTEM_USER(), SESSION_USER();

+----------------+----------------+----------------+----------------+
| USER()         | CURRENT_USER() | SYSTEM_USER()  | SESSION_USER() |
+----------------+----------------+----------------+----------------+
| root@localhost | root@localhost | root@localhost | root@localhost |
+----------------+----------------+----------------+----------------+
```

### `CHARSET()`

```sql
SELECT CHARSET('ABC');

+----------------+
| CHARSET('ABC') |
+----------------+
| utf8mb4        |
+----------------+
1 row in set (0.00 sec)
```

### `COLLATION()`

```sql
SELECT COLLATION('ABC');

+--------------------+
| COLLATION('ABC')   |
+--------------------+
| utf8mb4_general_ci |
+--------------------+
1 row in set (0.00 sec)
```

## 典型回查场景

- 执行 SQL 前不确定当前是不是在正确的数据库：先查 `DATABASE()`
- 排查权限或用户来源问题：先查 `USER()`、`CURRENT_USER()`
- 怀疑字符串比较或排序结果异常：先查 `CHARSET()`、`COLLATION()`
- 想确认当前 MySQL 环境版本：先查 `VERSION()`

## 常见混淆点

- `DATABASE()` / `SCHEMA()` 是查当前数据库环境，不是列出所有数据库。
- `CHARSET()` / `COLLATION()` 看的是某个字符串值的字符集与比较规则，不等于直接查看整库的默认设置。
- 用户信息函数返回的是当前连接上下文，主要用来帮助确认“现在是谁在执行这条 SQL”。

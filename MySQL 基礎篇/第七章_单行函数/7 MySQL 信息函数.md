# 7 MySQL 信息函数

> - 所属章节：[第七章_单行函数](./README.md)  
> - 关键字：信息函数、环境诊断、`VERSION()`、`CONNECTION_ID()`、`DATABASE()`、`SCHEMA()`、`USER()`、`CURRENT_USER()`、`SESSION_USER()`、`SYSTEM_USER()`、`CHARSET()`、`COLLATION()`、当前数据库、当前用户、连接身份、字符集、排序规则、权限排查、乱码排查  
> - 建议回查情境：想确认当前 MySQL 版本、当前连接 ID、当前默认数据库、当前连接用户、实际认证账号、字符串字符集或排序规则，或排查“为什么 SQL 执行在错误数据库 / 权限不对 / 字符串比较异常 / 排序结果不符合预期”时

## 本节导读

这一节整理 MySQL 中常见的信息函数。信息函数的重点不是对业务数据做计算，而是帮助我们确认“当前连接环境是什么样子”。

写 SQL 时，很多问题不是语法错，而是环境错：

- 你以为自己在 `test` 数据库，实际上当前默认数据库是 `prod`。
- 你以为自己用的是某个账号，但服务器实际认证的是另一个账号。
- 你以为字符串比较会区分大小写，但当前排序规则可能不区分大小写。
- 你以为连的是 MySQL 8.x，但实际环境可能是 MySQL 5.7 或 MariaDB。
- 你以为 `CONNECTION_ID()` 是连接数量，但它其实是当前连接的编号。

因此，本节要建立的重点不是“背函数名”，而是知道：

> 遇到环境、权限、连接、字符集、排序规则问题时，应该先用哪些信息函数确认现场。

---

## 你会在这篇学到什么

- `VERSION()` 用来确认当前 MySQL Server 版本。
- `CONNECTION_ID()` 返回的是当前连接 ID / thread ID，不是服务器连接总数。
- `DATABASE()` 与 `SCHEMA()` 都用来查看当前默认数据库。
- `USER()`、`SESSION_USER()`、`SYSTEM_USER()` 关注客户端连接时提供的用户与主机信息。
- `CURRENT_USER()` 关注服务器实际用于权限判断的认证账号。
- 为什么 `USER()` 和 `CURRENT_USER()` 可能不同。
- `CHARSET(value)` 与 `COLLATION(value)` 分别查看字符串值的字符集与排序规则。
- 字符集和排序规则为什么会影响乱码、排序、大小写比较与字符串匹配。
- 信息函数在排查 SQL 执行环境、权限、乱码、排序异常时的使用方式。

---

## 快速定位

| 想解决的问题 | 优先函数 | 建议阅读位置 |
| --- | --- | --- |
| 想确认当前 MySQL Server 版本 | `VERSION()` | `7.2 查看 MySQL 版本` |
| 想确认当前连接编号 | `CONNECTION_ID()` | `7.3 查看当前连接 ID` |
| 想确认当前默认数据库 | `DATABASE()` / `SCHEMA()` | `7.4 查看当前默认数据库` |
| 想确认连接时使用的用户 | `USER()` / `SESSION_USER()` / `SYSTEM_USER()` | `7.5 查看当前连接用户` |
| 想确认实际参与权限判断的账号 | `CURRENT_USER()` | `7.6 USER() 与 CURRENT_USER() 的差异` |
| 想确认字符串字符集 | `CHARSET(value)` | `7.7 查看字符串字符集` |
| 想确认字符串排序规则 | `COLLATION(value)` | `7.8 查看字符串排序规则` |
| 想排查权限、乱码、排序异常 | 多个信息函数组合 | `7.9 实务排查场景` |
| 想避免常见误解 | 全章重点整理 | `7.10 使用提醒`、`7.11 常见混淆点` |

---

## 快速回查表

| 类别 | 函数 | 作用 | 高频程度 | 重点提醒 |
| --- | --- | --- | --- | --- |
| 版本信息 | `VERSION()` | 返回当前 MySQL Server 版本字符串 | 高频 | 版本可能带有额外后缀 |
| 连接信息 | `CONNECTION_ID()` | 返回当前连接的连接 ID / thread ID | 高频 | 不是服务器连接总数 |
| 默认数据库 | `DATABASE()` | 返回当前默认数据库名称 | 高频 | 如果没有选择数据库，返回 `NULL` |
| 默认数据库 | `SCHEMA()` | `DATABASE()` 的同义函数 | 中频 | 在 MySQL 中 schema 通常可理解为 database |
| 连接用户 | `USER()` | 返回客户端连接时提供的用户名与主机 | 高频 | 可能和 `CURRENT_USER()` 不同 |
| 连接用户 | `SESSION_USER()` | `USER()` 的同义函数 | 中频 | 关注当前会话连接身份 |
| 连接用户 | `SYSTEM_USER()` | `USER()` 的同义函数 | 中频 | 不要和 `SYSTEM_USER` 权限混淆 |
| 认证账号 | `CURRENT_USER()` | 返回服务器实际用于权限判断的账号 | 高频 | 排查权限时尤其重要 |
| 字符集 | `CHARSET(value)` | 返回字符串参数的字符集 | 高频 | 看的是表达式/字符串值，不是整库默认值 |
| 排序规则 | `COLLATION(value)` | 返回字符串参数的排序规则 | 高频 | 会影响比较、排序、大小写敏感性 |

---

## 建议阅读顺序

第一次学习时，建议按照下面顺序阅读：

```text
7.1 信息函数的分类思路
 -> 7.2 VERSION()
 -> 7.3 CONNECTION_ID()
 -> 7.4 DATABASE() / SCHEMA()
 -> 7.5 USER() / SESSION_USER() / SYSTEM_USER()
 -> 7.6 CURRENT_USER()
 -> 7.7 CHARSET()
 -> 7.8 COLLATION()
 -> 7.9 实务排查场景
```

如果只是复习，可以这样查：

- 确认环境：看 `VERSION()`、`DATABASE()`。
- 确认连接：看 `CONNECTION_ID()`。
- 排查权限：看 `USER()`、`CURRENT_USER()`。
- 排查乱码或排序异常：看 `CHARSET()`、`COLLATION()`。

---

## 7.1 信息函数的分类思路

信息函数可以先分成三类：

| 分类 | 关注问题 | 代表函数 |
| --- | --- | --- |
| 环境信息 | 现在连到哪个 MySQL 环境？版本是什么？当前默认数据库是什么？ | `VERSION()`、`DATABASE()`、`SCHEMA()` |
| 连接与用户信息 | 当前连接是谁？连接编号是什么？服务器实际用哪个账号判断权限？ | `CONNECTION_ID()`、`USER()`、`CURRENT_USER()` |
| 字符集与排序规则 | 字符串值采用什么字符集？比较和排序规则是什么？ | `CHARSET()`、`COLLATION()` |

这三类信息函数很适合当作 SQL 排查的第一步。

例如：

```sql
SELECT
    VERSION()       AS mysql_version,
    DATABASE()      AS current_database,
    CONNECTION_ID() AS connection_id,
    USER()          AS login_user,
    CURRENT_USER()  AS authenticated_user;
```

这段 SQL 可以快速确认当前环境、数据库、连接和用户身份。

---

## 7.2 查看 MySQL 版本：VERSION()

`VERSION()` 用来查看当前 MySQL Server 的版本。

### 7.2.1 语法

```sql
SELECT VERSION();
```

### 7.2.2 示例

```sql
SELECT VERSION() AS mysql_version;
```

可能结果：

```text
8.4.9-standard
```

版本字符串可能不只是纯数字，也可能包含发行版本、编译信息或发行商后缀。

### 7.2.3 什么时候会用到？

`VERSION()` 常用于确认功能兼容性。

例如：

- 某个函数是否在当前版本可用。
- 当前环境是 MySQL 5.7、8.0、8.4，还是 MariaDB。
- 开发环境和生产环境版本是否一致。
- 某个 SQL 在本机可以执行，但服务器不行时，先确认版本差异。

### 7.2.4 实务示例

```sql
SELECT VERSION() AS version_info;
```

如果你发现教材函数在你的环境不能执行，第一步可以先查版本：

```sql
SELECT VERSION();
```

因为很多函数、默认字符集、排序规则和权限行为都可能随版本不同而有差异。

---

## 7.3 查看当前连接 ID：CONNECTION_ID()

`CONNECTION_ID()` 返回当前连接的连接 ID，也可以理解为当前会话在服务器中的 thread ID。

### 7.3.1 语法

```sql
SELECT CONNECTION_ID();
```

### 7.3.2 重要修正

`CONNECTION_ID()` 不是“当前 MySQL 服务器的连接数”。

它表示的是：

```text
当前这个连接的唯一编号。
```

如果想看当前有多少连接，通常要查看 processlist、status、performance_schema 或相关监控指标，而不是使用 `CONNECTION_ID()`。

### 7.3.3 示例

```sql
SELECT CONNECTION_ID() AS connection_id;
```

可能结果：

```text
23786
```

这个数字可以和下面这些来源中的连接编号对应：

- `SHOW PROCESSLIST` 的 `Id`。
- `INFORMATION_SCHEMA.PROCESSLIST` 的 `ID`。
- `performance_schema.threads` 中的 `PROCESSLIST_ID`。

### 7.3.4 实务场景：排查当前会话

当你想确认某个 SQL 是由哪条连接执行时，可以先查：

```sql
SELECT CONNECTION_ID();
```

然后再搭配：

```sql
SHOW PROCESSLIST;
```

就可以在 processlist 中找到对应的连接。

这在排查锁等待、长查询、连接占用时很有用。

---

## 7.4 查看当前默认数据库：DATABASE() / SCHEMA()

`DATABASE()` 用来查看当前默认数据库，也就是当前连接中没有明确指定库名时，SQL 默认会使用的数据库。

`SCHEMA()` 是 `DATABASE()` 的同义函数。

### 7.4.1 语法

```sql
SELECT DATABASE();
SELECT SCHEMA();
```

### 7.4.2 示例

```sql
SELECT DATABASE() AS current_database;
```

可能结果：

```text
test
```

如果当前连接没有选择默认数据库，结果会是：

```text
NULL
```

### 7.4.3 为什么这很重要？

因为很多 SQL 不会写完整库名，例如：

```sql
SELECT * FROM employees;
```

这时 MySQL 会到当前默认数据库中找 `employees` 表。

如果当前默认数据库不是你以为的那个，就可能出现：

- 查错资料库。
- 找不到表。
- 修改到错误环境中的表。
- 开发、测试、生产环境误操作。

### 7.4.4 实务建议

执行敏感 SQL 前，可以先确认：

```sql
SELECT DATABASE();
```

尤其是执行：

```sql
UPDATE ...
DELETE ...
DROP ...
TRUNCATE ...
```

这类会修改或删除资料的 SQL 前，更应该确认当前数据库。

---

## 7.5 查看当前连接用户：USER() / SESSION_USER() / SYSTEM_USER()

`USER()` 用来查看当前连接时客户端提供的用户名和主机。

`SESSION_USER()` 和 `SYSTEM_USER()` 在 MySQL 中是 `USER()` 的同义函数。

### 7.5.1 语法

```sql
SELECT USER();
SELECT SESSION_USER();
SELECT SYSTEM_USER();
```

### 7.5.2 示例

```sql
SELECT
    USER()          AS login_user,
    SESSION_USER()  AS session_user,
    SYSTEM_USER()   AS system_user;
```

可能结果：

```text
root@localhost
root@localhost
root@localhost
```

### 7.5.3 USER() 表示什么？

`USER()` 关注的是：

```text
客户端连接时提供的用户名称，以及客户端来源主机。
```

例如：

```text
app_user@192.168.1.10
root@localhost
report_user@%
```

这对排查“是谁连上数据库”很有帮助。

### 7.5.4 SYSTEM_USER() 不要和 SYSTEM_USER 权限混淆

`SYSTEM_USER()` 是函数，用来返回当前连接用户信息。

`SYSTEM_USER` 也可能出现在权限或账号类别相关语境中。两者不是同一件事：

| 名称 | 类型 | 含义 |
| --- | --- | --- |
| `SYSTEM_USER()` | 函数 | 返回当前连接用户信息，作用类似 `USER()` |
| `SYSTEM_USER` | 权限 / 账号类别相关概念 | 和系统用户、普通用户的权限类别有关 |

初学阶段只要先记：

```text
SYSTEM_USER() 是函数，在这里可当成 USER() 的同义函数理解。
```

---

## 7.6 USER() 与 CURRENT_USER() 的差异

这是本节最重要的概念之一。

很多时候 `USER()` 和 `CURRENT_USER()` 看起来结果一样，但它们的语义不同。

| 函数 | 关注点 | 说明 |
| --- | --- | --- |
| `USER()` | 客户端连接时提供的用户与主机 | 偏向“你用什么身份连进来” |
| `CURRENT_USER()` | 服务器实际用于权限判断的认证账号 | 偏向“服务器最后认定你是谁” |

---

### 7.6.1 基本示例

```sql
SELECT
    USER() AS login_user,
    CURRENT_USER() AS authenticated_user;
```

常见结果可能是：

```text
root@localhost | root@localhost
```

这表示客户端提供的用户身份和服务器认证后的账号一致。

---

### 7.6.2 为什么可能不同？

`USER()` 和 `CURRENT_USER()` 可能不同，常见原因包括：

- MySQL 账号匹配规则导致实际认证账号不同。
- 匿名用户账号参与认证。
- 在视图、存储过程、触发器、事件中，`CURRENT_USER()` 可能和 definer / invoker 有关。
- 权限定义和连接身份不完全一致。

因此，排查权限问题时，不能只看 `USER()`，也要看 `CURRENT_USER()`。

### 7.6.3 权限排查建议

如果遇到：

```text
明明用某个账号连接，却没有预期权限
```

可以先执行：

```sql
SELECT
    USER() AS login_user,
    CURRENT_USER() AS authenticated_user;
```

如果两者不同，就要进一步检查 MySQL 用户表、账号授权、host 匹配规则、视图或存储程序的 `DEFINER` 设置。

---

## 7.7 查看字符串字符集：CHARSET()

`CHARSET(value)` 用来查看某个字符串值或表达式使用的字符集。

### 7.7.1 语法

```sql
SELECT CHARSET(value);
```

### 7.7.2 示例

```sql
SELECT CHARSET('ABC') AS charset_name;
```

可能结果：

```text
utf8mb4
```

如果使用字符集转换：

```sql
SELECT CHARSET(CONVERT('ABC' USING latin1)) AS charset_name;
```

可能结果：

```text
latin1
```

### 7.7.3 CHARSET() 看的是谁？

`CHARSET()` 看的是传入参数这个字符串值或表达式的字符集。

它不是直接查看：

- 整个 MySQL Server 的默认字符集。
- 整个数据库的默认字符集。
- 整张表的默认字符集。
- 某个字段定义的字符集。

如果要查库、表、字段层级的字符集，要使用 `SHOW CREATE TABLE`、`SHOW FULL COLUMNS`、`information_schema` 等方式。

---

## 7.8 查看字符串排序规则：COLLATION()

`COLLATION(value)` 用来查看某个字符串值或表达式使用的排序规则。

### 7.8.1 语法

```sql
SELECT COLLATION(value);
```

### 7.8.2 示例

```sql
SELECT COLLATION('ABC') AS collation_name;
```

可能结果：

```text
utf8mb4_0900_ai_ci
```

不同环境可能看到不同结果，例如：

```text
utf8mb4_general_ci
utf8mb4_0900_ai_ci
utf8mb4_bin
latin1_swedish_ci
```

---

### 7.8.3 排序规则会影响什么？

排序规则会影响字符串的：

- 排序结果。
- 等值比较。
- 大小写是否敏感。
- 重音符号是否敏感。
- 某些语言文字的比较方式。

例如，很多以 `_ci` 结尾的 collation 表示 case-insensitive，也就是大小写不敏感。

```text
ci = case-insensitive
cs = case-sensitive
bin = binary comparison
```

具体是否大小写敏感，要以实际 collation 定义为准。

---

### 7.8.4 实务场景：排查大小写比较异常

如果你发现：

```sql
SELECT 'abc' = 'ABC';
```

结果和预期不一样，就可以先查：

```sql
SELECT
    CHARSET('abc') AS charset_name,
    COLLATION('abc') AS collation_name;
```

如果排序规则是不区分大小写的，那么 `'abc'` 和 `'ABC'` 在比较时可能会被视为相等。

---

## 7.9 实务排查场景

### 7.9.1 场景一：确认当前是否连到正确环境

```sql
SELECT
    VERSION()  AS mysql_version,
    DATABASE() AS current_database;
```

适合在执行重要 SQL 前先确认：

- 当前 MySQL 版本。
- 当前默认数据库。

尤其是在多个环境切换时，例如：

```text
local / dev / test / uat / prod
```

---

### 7.9.2 场景二：确认当前连接身份

```sql
SELECT
    CONNECTION_ID() AS connection_id,
    USER()          AS login_user,
    CURRENT_USER()  AS authenticated_user;
```

适合排查：

- 当前 SQL 是哪条连接在执行。
- 当前客户端用什么身份连接。
- MySQL 实际用哪个账号进行权限判断。

---

### 7.9.3 场景三：排查权限异常

如果出现：

```text
Access denied
```

或某个账号明明应该有权限却执行失败，可以先执行：

```sql
SELECT
    USER() AS login_user,
    CURRENT_USER() AS authenticated_user,
    DATABASE() AS current_database;
```

接着再检查：

- 当前默认数据库是否正确。
- 登录账号和认证账号是否一致。
- 是否有同名不同 host 的 MySQL 账号。
- 视图、存储过程是否受 `DEFINER` 影响。

---

### 7.9.4 场景四：排查乱码或字元集异常

```sql
SELECT
    CHARSET('中文') AS charset_name,
    COLLATION('中文') AS collation_name;
```

这可以先确认字符串字面量在当前连接下使用的字符集和排序规则。

如果问题发生在字段资料上，可以进一步查：

```sql
SHOW FULL COLUMNS FROM table_name;
```

或：

```sql
SHOW CREATE TABLE table_name;
```

---

### 7.9.5 场景五：排查排序结果不符合预期

如果你发现：

- 英文大小写排序和预期不同。
- 中文排序不符合预期。
- `A` 和 `a` 被当成一样或不一样。
- 特殊符号、重音符号比较异常。

可以先看：

```sql
SELECT
    COLLATION(column_name) AS collation_name
FROM table_name
LIMIT 1;
```

也可以检查字段定义：

```sql
SHOW FULL COLUMNS FROM table_name;
```

---

### 7.9.6 场景六：把环境信息放进排查日志

有时候排查线上问题时，可以先记录：

```sql
SELECT
    NOW()           AS checked_at,
    VERSION()       AS mysql_version,
    DATABASE()      AS current_database,
    CONNECTION_ID() AS connection_id,
    USER()          AS login_user,
    CURRENT_USER()  AS authenticated_user;
```

这样之后看问题记录时，可以知道当时查询发生在哪个环境、哪个连接、哪个用户上下文。

---

## 7.10 使用提醒

### 7.10.1 CONNECTION_ID() 不是连接数量

`CONNECTION_ID()` 返回的是当前连接 ID，不是当前连接总数。

如果要看连接列表，可以使用：

```sql
SHOW PROCESSLIST;
```

如果要看连接统计，通常需要看 MySQL 状态变量、performance_schema 或监控系统。

---

### 7.10.2 DATABASE() 可能返回 NULL

如果当前连接没有选择默认数据库：

```sql
SELECT DATABASE();
```

结果会是：

```text
NULL
```

这时执行没有指定库名的表查询，可能会出现：

```text
No database selected
```

---

### 7.10.3 USER() 和 CURRENT_USER() 语义不同

`USER()` 更偏向“客户端提供的连接身份”。  
`CURRENT_USER()` 更偏向“服务器实际用于权限判断的账号”。

排查权限问题时，建议两个都查：

```sql
SELECT USER(), CURRENT_USER();
```

---

### 7.10.4 CHARSET() / COLLATION() 看的是表达式，不是整库设定

```sql
SELECT CHARSET('ABC'), COLLATION('ABC');
```

这看的是字符串字面量 `'ABC'` 的字符集和排序规则，不等于直接查看数据库、表或字段的默认设置。

如果要查字段层级，建议使用：

```sql
SHOW FULL COLUMNS FROM table_name;
```

如果要查建表语句：

```sql
SHOW CREATE TABLE table_name;
```

---

### 7.10.5 COLLATION 会影响字符串比较

如果排序规则不区分大小写，下面比较可能返回 `1`：

```sql
SELECT 'abc' = 'ABC';
```

所以排查字符串比较异常时，不要只看 SQL 条件，也要看 collation。

---

### 7.10.6 VERSION() 可用于兼容性判断，但不要只靠版本猜行为

`VERSION()` 可以告诉你当前 MySQL 版本，但真正的 SQL 行为还可能受到：

- `sql_mode`
- 字符集
- 排序规则
- 时区
- 权限
- 存储引擎
- 连接参数

影响。

因此排查问题时，`VERSION()` 是第一步，不是全部。

---

## 7.11 常见混淆点

### 混淆点 1：CONNECTION_ID() 不是连接数

错误理解：

```text
CONNECTION_ID() = 当前服务器连接数
```

正确理解：

```text
CONNECTION_ID() = 当前连接的编号
```

---

### 混淆点 2：DATABASE() / SCHEMA() 不是列出所有数据库

```sql
SELECT DATABASE();
```

只会返回当前默认数据库。

如果要列出所有数据库，要使用：

```sql
SHOW DATABASES;
```

---

### 混淆点 3：SCHEMA() 在 MySQL 中是 DATABASE() 的同义函数

在 MySQL 中：

```sql
SELECT DATABASE(), SCHEMA();
```

两者含义相同，都是查看当前默认数据库。

---

### 混淆点 4：USER() 和 CURRENT_USER() 不一定相同

常见情况下两者相同，但在权限、匿名账号、视图、存储程序等场景中可能不同。

排查权限问题时应该一起看。

---

### 混淆点 5：SYSTEM_USER() 是函数，不等于 SYSTEM_USER 权限

`SYSTEM_USER()` 是信息函数，作用类似 `USER()`。

`SYSTEM_USER` 权限是另一个概念，不要混在一起。

---

### 混淆点 6：CHARSET() / COLLATION() 看的是值或表达式

```sql
SELECT CHARSET('ABC'), COLLATION('ABC');
```

这不是查看整个数据库的默认字符集，也不是查看所有字段的字符集。

---

### 混淆点 7：排序异常不一定是 ORDER BY 写错

如果排序结果和预期不同，也可能是 collation 导致的。

例如大小写敏感、重音符号敏感、中文排序规则，都可能影响结果。

---

## 7.12 自我检查题

### 问题 1

`CONNECTION_ID()` 返回的是当前服务器连接数吗？

答案：不是。它返回当前连接的连接 ID / thread ID。

---

### 问题 2

`DATABASE()` 和 `SCHEMA()` 有什么关系？

答案：在 MySQL 中，`SCHEMA()` 是 `DATABASE()` 的同义函数，两者都返回当前默认数据库。

---

### 问题 3

如果当前没有选择默认数据库，`DATABASE()` 会返回什么？

答案：返回 `NULL`。

---

### 问题 4

`USER()` 和 `CURRENT_USER()` 的核心差异是什么？

答案：`USER()` 表示客户端连接时提供的用户名和主机；`CURRENT_USER()` 表示服务器实际用于权限判断的认证账号。两者可能不同。

---

### 问题 5

`SESSION_USER()` 和 `SYSTEM_USER()` 在 MySQL 中通常可以怎么理解？

答案：它们是 `USER()` 的同义函数，用来返回当前连接用户信息。

---

### 问题 6

`CHARSET('ABC')` 查看的是整个数据库的字符集吗？

答案：不是。它查看的是字符串表达式 `'ABC'` 的字符集。

---

### 问题 7

如果发现 `'abc' = 'ABC'` 的结果和预期不同，应该优先检查什么？

答案：优先检查字符串或字段的 `COLLATION()`，因为排序规则会影响大小写敏感性和字符串比较行为。

---

### 问题 8

下面 SQL 适合用在什么场景？

```sql
SELECT
    VERSION(),
    DATABASE(),
    CONNECTION_ID(),
    USER(),
    CURRENT_USER();
```

答案：适合快速确认当前 MySQL 环境、当前默认数据库、当前连接编号、客户端连接身份与服务器实际认证账号，常用于环境与权限排查。

---

## 7.13 本节总结

本节可以浓缩成下面几条：

1. 信息函数不是用来处理业务数据，而是用来确认当前 MySQL 执行环境。
2. `VERSION()` 用来确认 MySQL Server 版本。
3. `CONNECTION_ID()` 返回当前连接 ID，不是连接数量。
4. `DATABASE()` 与 `SCHEMA()` 都用来查看当前默认数据库；没有默认数据库时可能返回 `NULL`。
5. `USER()`、`SESSION_USER()`、`SYSTEM_USER()` 关注当前连接用户。
6. `CURRENT_USER()` 关注服务器实际用于权限判断的认证账号。
7. 排查权限问题时，建议同时查看 `USER()` 和 `CURRENT_USER()`。
8. `CHARSET(value)` 查看字符串值或表达式的字符集。
9. `COLLATION(value)` 查看字符串值或表达式的排序规则。
10. 字符集和排序规则会影响乱码、排序、大小写比较和字符串匹配。

如果只记一句话：

> MySQL 信息函数的核心价值，是让你在写 SQL 前先确认「我现在连到哪里、用谁的身份、在什么字符集与排序规则下执行」。

---

## 延伸阅读

- [1 函数的理解](./1%20函数的理解.md)
- [3 字符串函数](./3%20字符串函数.md)
- [4 日期和时间函数](./4%20日期和时间函数/README.md)
- [5 流程控制函数](./5%20流程控制函数.md)
- [6 加密与解密函数](./6%20加密与解密函数.md)
- [8 其他函数](./8%20其他函数.md)

---
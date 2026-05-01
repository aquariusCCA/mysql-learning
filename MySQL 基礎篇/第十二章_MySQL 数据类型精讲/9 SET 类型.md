# 9 SET 类型

所属章节：[第十二章_MySQL 数据类型精讲](./README.md)

## 本节导读

这一篇要解决的问题是：

> 当一个字段可以同时选择多个固定选项时，到底该不该用 `SET`？它和 `ENUM`、普通字符串、多个布尔字段、关联表有什么差别？

`SET` 很容易让人觉得方便：

- 一个字段可以保存多个值
- 候选值在建表时就写死
- 查询出来看起来像逗号分隔字符串
- 底层又可以用 bit 位做紧凑存储

例如：

```sql
hobbies SET('reading', 'running', 'coding', 'music')
```

看起来很适合保存：

```text
reading,coding
```

但是 `SET` 不是普通字符串，也不是所有「多选 / 标签 / 权限」场景的默认答案。

建表前真正要先问的是：

1. 这个字段是不是允许多选？
2. 候选值是不是很少？
3. 候选值是否长期稳定？
4. 这些值需不需要中文名、英文名、排序号、启用状态、权限说明等附加信息？
5. 查询时是否经常需要按单个成员过滤、统计、联结？
6. 是否需要表达多对多关系？
7. 未来是否可能频繁新增、删除、改名、调整选项？
8. 这个字段的组合是否只是「固定开关集合」，还是一个会持续扩展的业务体系？

如果只能先记一句话：

> `SET` 适合「候选值少、允许多选、长期稳定」的小型固定集合；如果是会演进的标签、权限、分类、多对多关系，通常优先考虑关联表或字典表设计。

---

## 关键词

- 主题：MySQL 集合类型、多选字段、固定成员集合、位标记
- 英文：`SET`、set type、multiple-choice values、bit flags、bitmask
- 常见搜索：
  - MySQL SET 是什么
  - MySQL SET 和 ENUM 差别
  - MySQL SET 怎么存储
  - MySQL SET 最多多少个值
  - MySQL SET 查询方式
  - MySQL FIND_IN_SET 用法
  - MySQL SET strict mode invalid value
  - MySQL SET 排序规则
  - 多选字段该不该用 SET
  - 权限字段该用 SET 还是关联表
  - 标签系统该用 SET 还是 tag 表
- 易混淆：
  - `SET` vs `ENUM`
  - `SET` vs 普通逗号分隔字符串
  - `SET` 的显示字符串 vs 内部 bit 位
  - `SET` 的成员顺序 vs 插入时字符串顺序
  - `FIND_IN_SET()` vs `LIKE '%xxx%'`
  - 固定开关集合 vs 业务多对多关系
  - `SET('0','1')` vs 数值 0、1
  - 空字符串 `''` 表示没有选中任何成员
  - `SET` 的内部数值排序 vs 字符串字典序排序

---

## 建议回查情境

遇到下面情况时，可以回到这一篇：

- 想定义兴趣、功能开关、标签、权限、属性等多选字段。
- 想判断字段该用 `SET`、多个 `TINYINT(1)`、`JSON`、普通字符串，还是关联表。
- 想理解 `SET` 为什么看起来像字符串，但底层更接近 bitmask。
- 想知道 `SET` 的成员顺序、重复成员、非法成员会怎么处理。
- 想知道 `FIND_IN_SET()`、位运算、精确匹配、`LIKE` 查询的差异。
- 想知道 `SET` 为什么不适合大型标签系统、复杂权限系统或经常变更的字典。
- 想把旧系统里的逗号分隔字段改造成更合理的表结构。
- 想理解 `SET` 和 `ENUM` 的根本区别。

---

## 30 秒复习入口

- `SET` 是 MySQL 的一种字符串类型，用来表示「从预定义列表中选择零个或多个值」。
- `ENUM` 是单选；`SET` 是多选。
- 一个 `SET` 字段最多可以定义 64 个不同成员。
- `SET` 成员之间用逗号分隔，所以成员值本身不应该包含逗号。
- `SET` 查询出来显示为字符串组合，例如 `'read,write'`。
- `SET` 内部按数值保存，每个成员对应一个 bit 位。
- 第 1 个成员对应低位 bit，值为 `1`；第 2 个成员值为 `2`；第 3 个成员值为 `4`；第 4 个成员值为 `8`。
- `SET('a','b','c','d')` 中，如果插入数值 `9`，二进制是 `1001`，结果会选中 `'a'` 和 `'d'`。
- 插入 `'d,a,a'`，取出时会显示为定义顺序下的 `'a,d'`，重复成员不会重复保存。
- `SET` 的存储空间取决于「定义了多少个成员」，不是这一行实际选了几个成员。
- `SET` 的存储大小可理解为 `(N + 7) / 8` bytes，并向上取到 1、2、3、4 或 8 bytes。
- `FIND_IN_SET('value', set_col)` 可以判断是否包含某成员。
- 当第一个参数是常量、第二个参数是 `SET` 欄位时，`FIND_IN_SET()` 可被优化成 bit arithmetic。
- `LIKE '%value%'` 可能误匹配子串，通常不如 `FIND_IN_SET()` 精准。
- `set_col & 1` 可以判断是否包含第 1 个成员。
- `SET` 值默认按内部数值排序，不是按显示字符串字典序排序。
- 非 strict mode 下，非法成员可能被忽略并产生 warning；strict mode 下，非法 `SET` 值通常会报错。
- `SET` 不适合选项经常变化、需要多语言、需要统计扩展、需要权限继承或需要多表联结的业务系统。
- 复杂标签、权限、商品属性、用户兴趣，长期更推荐字典表 + 关联表。
- `SET` 的价值在「小型固定多选约束 + 紧凑表示」，不是「解决所有多选建模问题」。

---

## 一、先讲结论

`SET` 的价值不是「比字符串高级」，而是：

> 在数据库字段层面表达「这个字段可以从固定候选值中选择零个或多个」。

它适合的场景比很多人想象中更窄。

### 1.1 最重要的选型表

| 需求 | 推荐做法 | 说明 |
| --- | --- | --- |
| 少量、稳定、允许多选的固定开关 | `SET` | 例如几个长期不变的功能标记 |
| 少量、稳定、只能单选 | `ENUM` | `ENUM` 是单选，`SET` 是多选 |
| 多个互相独立、含义非常明确的开关 | 多个 `TINYINT(1)` / `BOOLEAN` 字段 | 可读性强，查询简单 |
| 标签、权限、兴趣、分类会持续扩展 | 字典表 + 关联表 | 更适合多对多关系 |
| 候选值需要中文名、英文名、排序号、启用状态 | 字典表 | `SET` 无法优雅承载元数据 |
| 需要复杂统计、联结、筛选、权限继承 | 规范化表设计 | 不建议塞进一个 `SET` 字段 |
| 只是临时保存前端多选结果，不太需要查询 | `JSON` 或独立明细表 | 取决于是否需要结构化查询 |
| 需要跨数据库兼容 | 避免 `SET` | `SET` 是 MySQL 特色类型 |

### 1.2 我的实务建议

业务系统中，我建议你这样判断：

```text
第一步：是不是多选？
不是多选 -> 不用 SET，考虑 ENUM、VARCHAR、TINYINT 状态码。

第二步：候选值是否很少？
不是很少 -> 不优先用 SET。

第三步：候选值是否长期稳定？
不稳定 -> 优先字典表 + 关联表。

第四步：是否需要附加信息？
需要中文名、英文名、排序、启停、说明 -> 优先字典表。

第五步：是否需要复杂查询和统计？
需要大量筛选、统计、联结 -> 优先关联表。

第六步：是否接受修改选项时改表结构？
不能接受 -> 不用 SET。

以上都通过，才考虑 SET。
```

所以，`SET` 不是不能用，而是适合「小而稳定」的多选集合。

---

## 二、什么是 `SET`

`SET` 是 MySQL 提供的一种特殊字符串类型。

它的字段值可以包含零个、一个或多个预定义成员。

例如：

```sql
CREATE TABLE user_profile (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    hobbies SET('reading', 'running', 'coding', 'music') NOT NULL
);
```

这个 `hobbies` 字段允许保存：

```text
''
'reading'
'running'
'reading,coding'
'reading,running,coding,music'
```

注意：

```text
''
```

表示没有选择任何成员。

它不是 `NULL`，而是一个合法的「空集合」值。

如果字段允许 `NULL`，则还要区分：

| 值 | 含义 |
| --- | --- |
| `NULL` | 未知、没有填写、不适用 |
| `''` | 已知为空集合，也就是没有选择任何成员 |

这两个含义不一样。

---

## 三、`SET` 和 `ENUM` 的核心区别

`ENUM` 和 `SET` 都是 MySQL 的特殊字符串类型，都要求值来自预定义列表。

但它们的根本区别是：

> `ENUM` 是单选；`SET` 是多选。

| 对比项 | `ENUM` | `SET` |
| --- | --- | --- |
| 选择数量 | 只能选一个 | 可以选零个或多个 |
| 适合语义 | 状态、类型、等级 | 固定开关集合、少量多选项 |
| 内部表示 | 枚举项 index | bit 位组合 |
| 典型例子 | `status ENUM('pending','done')` | `flags SET('email','sms','push')` |
| 最大成员数 | 最多 65,535 个 | 最多 64 个 |
| 后续变更 | 改选项通常要改表 | 改选项通常也要改表 |

判断方式很简单：

```text
一次只能有一个值 -> 可能是 ENUM。
一次可以同时有多个值 -> 才考虑 SET。
```

例如订单状态：

```sql
status ENUM('created', 'paid', 'shipped', 'done')
```

订单不应该同时是 `created` 和 `done`，所以适合单选状态。

再例如通知渠道：

```sql
notify_channels SET('email', 'sms', 'push')
```

一个用户可以同时接收 email、sms、push，所以它是多选语义。

---

## 四、`SET` 的内部 bit 位模型

虽然 `SET` 查询出来像字符串：

```text
read,write
```

但 MySQL 内部会把 `SET` 值按数值保存。

每个成员对应一个 bit 位。

例如：

```sql
SET('read', 'write', 'delete', 'export')
```

可以理解成：

| 成员 | 定义顺序 | 对应十进制值 | 二进制 |
| --- | ---: | ---: | --- |
| `read` | 第 1 个 | 1 | `0001` |
| `write` | 第 2 个 | 2 | `0010` |
| `delete` | 第 3 个 | 4 | `0100` |
| `export` | 第 4 个 | 8 | `1000` |

如果一行保存：

```text
read,export
```

内部数值可以理解成：

```text
1 + 8 = 9
```

二进制：

```text
1001
```

所以：

```sql
SELECT permission + 0
FROM demo_set;
```

可以把 `SET` 值放到数值上下文中查看内部数值。

### 4.1 数字插入 `SET` 的陷阱

因为 `SET` 内部是 bit 位组合，所以插入数字也可能被解释成成员组合。

例如：

```sql
CREATE TABLE demo_set (
    flags SET('a', 'b', 'c', 'd')
);

INSERT INTO demo_set (flags) VALUES (9);
```

`9` 的二进制是：

```text
1001
```

所以它会选中第 1 个和第 4 个成员：

```text
a,d
```

这也是为什么不建议把 `SET` 当成普通字符串看待，更不建议设计成：

```sql
SET('0', '1', '2', '3')
```

这种写法会让「字符串成员」和「内部数值」混在一起，理解成本很高。

---

## 五、`SET` 的定义、插入与显示规则

### 5.1 基本定义

```sql
CREATE TABLE feature_config (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    feature_flags SET('search', 'export', 'audit', 'notify') NOT NULL DEFAULT ''
);
```

这里的 `feature_flags` 可以保存：

```text
''
'search'
'export'
'search,export'
'search,audit,notify'
'search,export,audit,notify'
```

### 5.2 插入多选值

```sql
INSERT INTO feature_config (feature_flags)
VALUES
('search'),
('search,export'),
('notify,search'),
('');
```

查询：

```sql
SELECT id, feature_flags
FROM feature_config;
```

概念结果：

| id | feature_flags |
| ---: | --- |
| 1 | `search` |
| 2 | `search,export` |
| 3 | `search,notify` |
| 4 | `` |

注意第 3 行。

即使插入时写的是：

```text
notify,search
```

查询时仍会按定义顺序显示：

```text
search,notify
```

### 5.3 重复成员不会重复保存

```sql
INSERT INTO feature_config (feature_flags)
VALUES ('search,export,search');
```

取出时通常会显示：

```text
search,export
```

也就是说，同一个成员重复出现没有意义。

### 5.4 成员值本身不要包含逗号

`SET` 的多个成员是用逗号分隔的。

因此成员值本身不应该包含逗号。

不建议：

```sql
SET('A,B', 'C')
```

因为这会让显示、解析、维护都变得混乱。

### 5.5 定义中的尾随空格会被删除

如果定义时写：

```sql
SET('read ', 'write')
```

MySQL 创建表时会自动删除 `SET` 成员值尾部的空格。

因此不要依赖成员值末尾空格表达业务差异。

---

## 六、`SET` 的存储空间

`SET` 的存储空间取决于：

> 这个字段定义了多少个不同成员。

不是取决于：

> 某一行实际选中了几个成员。

如果定义了 `N` 个成员，可以用下面方式理解：

```text
(N + 7) / 8 bytes
```

并向上取到固定字节数。

| 定义的成员数量 | 约占用空间 |
| ---: | ---: |
| 1 ~ 8 个 | 1 byte |
| 9 ~ 16 个 | 2 bytes |
| 17 ~ 24 个 | 3 bytes |
| 25 ~ 32 个 | 4 bytes |
| 33 ~ 64 个 | 8 bytes |

例如：

```sql
flags SET('a','b','c','d','e','f','g','h')
```

定义了 8 个成员，所以可理解为 1 byte。

哪怕某一行只保存 `'a'`，它的存储模型也仍然基于字段定义的成员数量。

### 6.1 不要因为「省空间」就滥用 `SET`

`SET` 的确很紧凑，但数据库设计不能只看字段大小。

更重要的是：

- 查询是否清楚
- 业务是否会扩展
- 是否需要关联其他表
- 是否需要统计
- 是否需要权限继承
- 是否需要审计
- 是否需要历史记录
- 是否需要跨系统共享定义

如果未来会复杂化，用关联表通常比 `SET` 更稳。

---

## 七、查询 `SET` 字段

假设有表：

```sql
CREATE TABLE user_notify_setting (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    channels SET('email', 'sms', 'push') NOT NULL DEFAULT ''
);

INSERT INTO user_notify_setting (username, channels)
VALUES
('Alice', 'email,push'),
('Bob', 'sms'),
('Carol', 'email,sms,push'),
('David', '');
```

### 7.1 查询包含某个成员：`FIND_IN_SET()`

查询开启 email 通知的用户：

```sql
SELECT id, username, channels
FROM user_notify_setting
WHERE FIND_IN_SET('email', channels) > 0;
```

`FIND_IN_SET('email', channels)` 的含义是：

> 判断 `email` 是否出现在 `channels` 的逗号分隔成员列表中。

概念结果：

| id | username | channels |
| ---: | --- | --- |
| 1 | Alice | `email,push` |
| 3 | Carol | `email,sms,push` |

### 7.2 不建议用 `LIKE '%email%'` 代替

有些人会写：

```sql
SELECT *
FROM user_notify_setting
WHERE channels LIKE '%email%';
```

这在简单例子中可能看起来可行，但它有误匹配风险。

例如成员有：

```text
mail
email
```

那么：

```sql
LIKE '%mail%'
```

可能匹配到 `email`。

所以，判断 `SET` 是否包含某个成员时，优先使用：

```sql
FIND_IN_SET('member', set_col) > 0
```

### 7.3 使用位运算查询

因为 `SET` 内部是 bit 位组合，所以也可以使用位运算。

假设：

```sql
channels SET('email', 'sms', 'push')
```

则：

| 成员 | bit 值 |
| --- | ---: |
| `email` | 1 |
| `sms` | 2 |
| `push` | 4 |

查询包含 `email` 的记录：

```sql
SELECT *
FROM user_notify_setting
WHERE channels & 1;
```

查询包含 `sms` 的记录：

```sql
SELECT *
FROM user_notify_setting
WHERE channels & 2;
```

查询同时包含 `email` 和 `push` 的记录：

```sql
SELECT *
FROM user_notify_setting
WHERE (channels & (1 | 4)) = (1 | 4);
```

也就是：

```sql
SELECT *
FROM user_notify_setting
WHERE (channels & 5) = 5;
```

位运算很高效，但可读性比较差。

因此实务上要看团队熟悉程度：

| 写法 | 优点 | 缺点 |
| --- | --- | --- |
| `FIND_IN_SET('email', channels)` | 可读性较好 | 仍然不如规范关联表直观 |
| `channels & 1` | 接近底层 bit 判断 | 可读性差，成员顺序改变会出问题 |
| `LIKE '%email%'` | 写起来简单 | 有误匹配风险，不推荐 |
| 关联表 `JOIN` | 结构清楚，可扩展 | 表较多，建模较完整 |

### 7.4 精确匹配整个组合

查询刚好只有 `email,push` 的用户：

```sql
SELECT *
FROM user_notify_setting
WHERE channels = 'email,push';
```

这表示完整组合必须相同。

但要注意，`SET` 精确匹配时，最好按照字段定义顺序写成员。

如果字段定义是：

```sql
SET('email', 'sms', 'push')
```

那么精确匹配应写：

```sql
WHERE channels = 'email,push'
```

不要写成：

```sql
WHERE channels = 'push,email'
```

虽然插入时顺序会被规范化，但比较时不应该依赖混乱顺序，统一按定义顺序写最清楚。

---

## 八、`SET` 的排序规则

`SET` 值排序时，默认按内部数值排序。

例如：

```sql
CREATE TABLE sort_demo (
    flags SET('a', 'b', 'c')
);

INSERT INTO sort_demo (flags)
VALUES
('c'),       -- 4
('a'),       -- 1
('b'),       -- 2
('a,c'),     -- 5
('a,b'),     -- 3
('');
```

如果执行：

```sql
SELECT flags, flags + 0 AS numeric_value
FROM sort_demo
ORDER BY flags;
```

概念排序会更接近：

| flags | numeric_value |
| --- | ---: |
| `` | 0 |
| `a` | 1 |
| `b` | 2 |
| `a,b` | 3 |
| `c` | 4 |
| `a,c` | 5 |

它不是按显示字符串的字典序排序。

如果你真的要按显示字符串排序，可以考虑：

```sql
ORDER BY CAST(flags AS CHAR)
```

但这通常也代表：你已经在对 `SET` 的显示值做字符串逻辑处理，建模上要重新确认是否真的适合 `SET`。

---

## 九、非法值与 SQL mode

非法成员是 `SET` 最需要小心的地方之一。

假设：

```sql
CREATE TABLE invalid_demo (
    flags SET('a', 'b', 'c')
);
```

插入：

```sql
INSERT INTO invalid_demo (flags)
VALUES ('a,d');
```

其中：

- `a` 是合法成员
- `d` 是非法成员

在非 strict mode 下，MySQL 可能忽略非法成员，保留合法成员，并产生 warning。

也就是说，结果可能变成：

```text
a
```

这很危险，因为资料看起来插入成功，但实际上被数据库调整过。

在 strict SQL mode 下，插入非法 `SET` 值通常会报错。

### 9.1 实务建议

业务系统中建议：

1. 数据库启用 strict SQL mode。
2. 应用层先做白名单校验。
3. 不要依赖 MySQL 自动忽略非法成员。
4. 对重要字段，写入后不要只看「SQL 有没有成功」，还要注意 warning。
5. 不要把 `SET` 当成自由输入字段。

---

## 十、`NULL`、空集合与默认值

`SET` 有一个很容易忽略的点：

> 空字符串 `''` 可以表示「没有选中任何成员」。

例如：

```sql
CREATE TABLE user_preference (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    options SET('dark_mode', 'email_notice', 'sms_notice') NOT NULL DEFAULT ''
);
```

这里：

```sql
DEFAULT ''
```

表示默认没有选中任何选项。

### 10.1 `NULL` 和 `''` 不一样

| 写法 | 含义 |
| --- | --- |
| `NULL` | 未知、未填写、不适用 |
| `''` | 明确表示没有选中任何成员 |

如果业务上只需要表达「没有选任何选项」，可以：

```sql
options SET('dark_mode', 'email_notice', 'sms_notice') NOT NULL DEFAULT ''
```

如果业务上需要区分「用户尚未设置」和「用户明确关闭全部」，才考虑允许 `NULL`。

例如：

```sql
options SET('dark_mode', 'email_notice', 'sms_notice') NULL DEFAULT NULL
```

---

## 十一、字符集、排序规则与大小写

`SET` 虽然有内部 bit 位，但它仍然属于字符串类型。

因此它可以指定字符集和 collation。

例如：

```sql
CREATE TABLE collation_demo (
    flags SET('Read', 'Write')
        CHARACTER SET utf8mb4
        COLLATE utf8mb4_0900_ai_ci
);
```

是否区分大小写，会受到 collation 影响。

如果使用大小写不敏感的 collation，某些比较或赋值行为可能不区分大小写。

如果使用 binary 或大小写敏感的 collation，大小写就会被纳入判断。

实务建议：

- `SET` 成员统一使用小写英文，例如 `read`、`write`、`export`。
- 不要混用 `Read`、`read`、`READ`。
- 不要使用含逗号的成员。
- 不要使用尾部空格表达差异。
- 不要使用看起来像数字的成员，例如 `'0'`、`'1'`、`'2'`。

---

## 十二、什么时候适合用 `SET`

`SET` 更适合下面这类场景：

### 12.1 少量、稳定的功能开关

例如某个模块支持固定几种能力：

```sql
features SET('search', 'export', 'audit') NOT NULL DEFAULT ''
```

候选值少，而且未来基本不会变化。

### 12.2 少量、稳定的通知渠道

```sql
channels SET('email', 'sms', 'push') NOT NULL DEFAULT ''
```

如果通知渠道长期固定，`SET` 可以表达「用户可同时开启多个渠道」。

### 12.3 固定组合标记

例如内部工具中某个任务支持几个固定处理选项：

```sql
process_options SET('validate', 'archive', 'notify') NOT NULL DEFAULT ''
```

这些值更像固定 bit flags，而不是业务标签体系。

---

## 十三、什么时候不适合用 `SET`

### 13.1 不适合大型标签系统

例如：

- 用户兴趣标签
- 商品标签
- 文章标签
- 客户标签
- 风险标签

这些标签通常会：

- 经常新增
- 经常下架
- 需要中文名
- 需要排序
- 需要统计
- 需要推荐
- 需要运营配置
- 需要多语言
- 需要权限控制
- 需要批量管理

这种场景应该用字典表 + 关联表。

例如：

```sql
CREATE TABLE tag (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    tag_code VARCHAR(50) NOT NULL UNIQUE,
    tag_name VARCHAR(100) NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    sort_no INT NOT NULL DEFAULT 0
);

CREATE TABLE user_tag (
    user_id BIGINT UNSIGNED NOT NULL,
    tag_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, tag_id)
);
```

这种设计虽然多一张表，但扩展性比 `SET` 好很多。

### 13.2 不适合复杂权限系统

简单权限开关也许能用 `SET`：

```sql
permissions SET('read', 'write', 'export')
```

但真正业务系统的权限通常有：

- 用户
- 角色
- 菜单
- 按钮
- API
- 组织
- 数据权限
- 权限继承
- 权限生效时间
- 权限来源
- 审计记录

这时应该使用权限表、角色表、用户角色关联表、角色权限关联表，而不是用一个 `SET` 字段硬塞。

### 13.3 不适合需要频繁改选项的字段

如果每次新增选项都要：

```sql
ALTER TABLE ...
```

那说明这个字段可能不适合 `SET`。

字典表只需要：

```sql
INSERT INTO dict_item (...)
VALUES (...);
```

维护成本完全不同。

### 13.4 不适合需要复杂统计的字段

例如你经常要查：

- 每个标签有多少用户
- 每个标签最近 30 天新增多少
- 哪些用户同时有 A、B、C 标签
- 哪些标签最常被组合使用
- 标签之间的关联分析

这些更适合关联表，而不是 `SET`。

---

## 十四、`SET` 与其他方案的比较

### 14.1 `SET` vs 多个布尔字段

例如通知渠道有三个：

```sql
email_enabled TINYINT(1)
sms_enabled TINYINT(1)
push_enabled TINYINT(1)
```

和：

```sql
channels SET('email', 'sms', 'push')
```

比较：

| 方案 | 优点 | 缺点 |
| --- | --- | --- |
| 多个布尔字段 | 查询简单、语义直观、容易建索引 | 开关很多时字段膨胀 |
| `SET` | 字段集中、存储紧凑 | 查询和维护有特殊语义 |
| 关联表 | 扩展性好、统计灵活 | 表结构更完整，查询要 JOIN |

如果只有 2～5 个非常固定的开关，多字段或 `SET` 都可以。

如果开关数量会持续变多，优先关联表。

### 14.2 `SET` vs 普通逗号分隔字符串

不建议自己用普通 `VARCHAR` 保存：

```text
email,sms,push
```

因为普通字符串没有数据库层约束：

- 可能写入非法值
- 可能重复
- 可能顺序混乱
- 可能多出空格
- 查询容易误匹配
- 没有成员白名单

如果真的要保存小型固定多选，`SET` 至少比普通逗号字符串更有约束。

但如果业务会复杂化，应该直接关联表。

### 14.3 `SET` vs `JSON`

`JSON` 可以保存数组：

```json
["email", "sms", "push"]
```

它比 `SET` 灵活，但也有代价：

| 方案 | 适合 | 不适合 |
| --- | --- | --- |
| `SET` | 小型固定多选 | 动态扩展、多层结构 |
| `JSON` | 半结构化、不固定配置 | 高频关系查询、复杂统计 |
| 关联表 | 多对多关系、统计、联结 | 只是简单配置时略重 |

如果你经常查询数组内部成员、统计成员出现次数，通常不该把它长期放在 JSON 里。

### 14.4 `SET` vs 字典表 + 关联表

这是最常见的关键选择。

| 对比项 | `SET` | 字典表 + 关联表 |
| --- | --- | --- |
| 建表复杂度 | 简单 | 较完整 |
| 新增选项 | 通常要改表 | 新增字典数据 |
| 删除 / 停用选项 | 不方便 | 可用 `enabled` 控制 |
| 多语言 | 不方便 | 可扩展 |
| 排序号 | 不方便 | 可扩展 |
| 统计分析 | 不自然 | 很自然 |
| 多对多关系 | 勉强表达 | 天然适合 |
| 长期维护 | 适合小型稳定场景 | 适合业务系统 |

实务建议：

```text
只是固定开关 -> SET 可以考虑。
是真正业务标签 / 权限 / 分类 -> 优先关联表。
```

---

## 十五、完整建表示例：用户通知设置

这个场景相对适合 `SET`，因为通知渠道数量少，而且通常比较稳定。

```sql
CREATE TABLE user_notify_setting (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键 ID',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户 ID',

    channels SET('email', 'sms', 'push')
        NOT NULL
        DEFAULT ''
        COMMENT '通知渠道：email、sms、push，可多选',

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    UNIQUE KEY uk_user_id (user_id)
) COMMENT = '用户通知设置表';
```

### 15.1 插入数据

```sql
INSERT INTO user_notify_setting (user_id, channels)
VALUES
(1001, 'email,push'),
(1002, 'sms'),
(1003, ''),
(1004, 'email,sms,push');
```

### 15.2 查询开启 email 的用户

```sql
SELECT user_id, channels
FROM user_notify_setting
WHERE FIND_IN_SET('email', channels) > 0;
```

### 15.3 查询开启 push 的用户

```sql
SELECT user_id, channels
FROM user_notify_setting
WHERE FIND_IN_SET('push', channels) > 0;
```

### 15.4 查询完全没有开启通知的用户

```sql
SELECT user_id, channels
FROM user_notify_setting
WHERE channels = '';
```

### 15.5 查看内部数值

```sql
SELECT
    user_id,
    channels,
    channels + 0 AS channels_numeric
FROM user_notify_setting;
```

---

## 十六、反例：用户标签不建议用 `SET`

不推荐：

```sql
CREATE TABLE user_profile_bad (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    tags SET('vip', 'new_user', 'high_risk', 'student', 'developer') NOT NULL DEFAULT ''
);
```

一开始看起来简单，但后续很可能会出现：

- 标签越来越多，超过设计预期
- 标签要显示中文名
- 标签要停用
- 标签要统计人数
- 标签要记录打标签时间
- 标签要记录谁打的标签
- 标签要做标签分组
- 标签要做推荐和画像分析

更合理的是：

```sql
CREATE TABLE user_profile (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL
);

CREATE TABLE tag (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    tag_code VARCHAR(50) NOT NULL UNIQUE,
    tag_name VARCHAR(100) NOT NULL,
    tag_group VARCHAR(50) DEFAULT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    sort_no INT NOT NULL DEFAULT 0
);

CREATE TABLE user_tag (
    user_id BIGINT UNSIGNED NOT NULL,
    tag_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED DEFAULT NULL,
    PRIMARY KEY (user_id, tag_id),
    KEY idx_tag_id (tag_id)
);
```

这就是典型的多对多关系。

---

## 十七、Java / MyBatis 中的实务提醒

在 Java 项目里，`SET` 字段通常会被当成字符串取出，例如：

```text
email,push
```

然后应用层再拆分：

```java
List<String> channels = Arrays.asList(dbValue.split(","));
```

但这样也有几个注意点：

### 17.1 不要让业务层到处手写字符串

不建议业务代码到处写：

```java
if (channels.contains("email")) {
    // ...
}
```

更好的方式是集中定义常量或枚举：

```java
public enum NotifyChannel {
    EMAIL("email"),
    SMS("sms"),
    PUSH("push");

    private final String code;

    NotifyChannel(String code) {
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
```

### 17.2 做好输入白名单校验

即使数据库有 `SET` 约束，应用层也应该先检查：

```java
private static final Set<String> ALLOWED_CHANNELS =
        Set.of("email", "sms", "push");
```

避免非法值进入 SQL。

### 17.3 小心和前端数组之间的转换

前端可能传：

```json
["email", "push"]
```

数据库需要：

```text
email,push
```

转换逻辑要集中封装，不要散落在 controller、service、mapper 各处。

### 17.4 如果业务继续变复杂，应尽早重构

如果你发现代码里开始出现：

- 标签名称转换
- 标签排序
- 标签权限
- 标签统计
- 标签分组
- 标签启停
- 标签审计

这代表 `SET` 已经不够用了，应考虑改成独立表。

---

## 十八、常见错误写法

### 错误 1：把大型标签系统做成 `SET`

```sql
tags SET('tag1', 'tag2', 'tag3', ...)
```

问题：

- 标签扩展困难
- 统计困难
- 维护困难
- 超过 64 个成员就无法继续

更建议：标签表 + 关联表。

### 错误 2：用 `LIKE` 判断成员

```sql
WHERE tags LIKE '%vip%'
```

问题：

- 可能误匹配子串
- 语义不够精准

更建议：

```sql
WHERE FIND_IN_SET('vip', tags) > 0
```

或者使用关联表：

```sql
JOIN user_tag ut ON ...
JOIN tag t ON ...
WHERE t.tag_code = 'vip'
```

### 错误 3：使用数字样式成员

```sql
status_flags SET('0', '1', '2')
```

问题：

- 容易和内部数值混淆
- 可读性差
- 后续维护困难

更建议使用有语义的英文 code：

```sql
SET('read', 'write', 'export')
```

### 错误 4：频繁调整 `SET` 成员

```sql
ALTER TABLE user_profile
MODIFY tags SET(...新增一堆值...);
```

如果经常这样做，说明它本来就不该用 `SET`。

### 错误 5：把 `SET` 当成任意字符串

```sql
SET('anything')
```

然后希望之后随便塞任何值。

这违反了 `SET` 的本质。

`SET` 是固定成员集合，不是自由字符串。

---

## 十九、常见混淆点

### 19.1 `SET` 是字符串类型还是数字类型？

从类型分类看，它是字符串类型。

但从内部保存和比较看，它有数值 bit 位模型。

所以更准确的理解是：

> `SET` 是一种对外显示为字符串、内部按 bit 位组合保存的特殊字符串类型。

### 19.2 `SET` 可以保存多少个成员？

一个 `SET` 字段最多可以定义 64 个不同成员。

这不是建议你定义 64 个，而是上限。

如果你的候选项已经多到几十个，通常应该认真考虑关联表。

### 19.3 `SET` 中的成员顺序重要吗？

定义顺序非常重要，因为：

- 它决定内部 bit 位
- 它决定查询显示时的成员顺序
- 它影响数值排序
- 它影响位运算判断

不要随便调整已经上线字段的成员顺序。

### 19.4 插入时的顺序重要吗？

插入时成员顺序不重要。

例如：

```sql
'a,d'
'd,a'
'a,d,a'
```

取出时都会按定义顺序显示，例如：

```text
a,d
```

### 19.5 `SET` 可以包含重复成员吗？

插入值中重复成员没有意义，取出时只会出现一次。

但字段定义中重复成员会产生 warning；在 strict SQL mode 下可能会报错。

### 19.6 `SET` 可以替代关联表吗？

只能在非常小、非常稳定、查询很简单的场景下勉强替代。

真正的多对多关系不建议用 `SET` 替代。

---

## 二十、自测问题

1. `SET` 和 `ENUM` 最核心的区别是什么？
2. 为什么说 `SET` 的内部更像 bitmask？
3. `SET('a','b','c','d')` 中，数值 `9` 代表哪些成员？
4. 为什么 `SET` 最多只能定义 64 个成员？
5. `SET` 的存储空间取决于「实际选中几个值」还是「定义了几个成员」？
6. 为什么 `SET` 成员值本身不应该包含逗号？
7. 插入 `'d,a,a'` 后，为什么取出时可能显示为 `'a,d'`？
8. 非 strict mode 下插入非法 `SET` 成员可能有什么风险？
9. 为什么不建议使用 `LIKE '%vip%'` 判断 `SET` 是否包含 `vip`？
10. `FIND_IN_SET('email', channels)` 和 `channels & 1` 各有什么优缺点？
11. 为什么用户标签、商品标签、角色权限通常不建议长期使用 `SET`？
12. `NULL` 和 `''` 在 `SET` 字段里分别表示什么？
13. 为什么不建议定义 `SET('0','1','2')`？
14. 如果标签需要中文名、排序号、启用状态，应该怎么建模？
15. 什么时候可以接受使用 `SET`？

---

## 二十一、一句话抓核心

`SET` 适合「候选值少、允许多选、长期稳定」的小型固定集合；它对外像逗号分隔字符串，内部像 bit 位组合，但真正复杂的标签、权限、多对多关系，长期应优先使用字典表和关联表。

---

## 返回导航

- [回到第十二章入口](./README.md)
- [上一节：8 ENUM 类型](./8%20ENUM%20类型.md)
- [下一节：10 二进制字符串类型](./10%20二进制字符串类型.md)
- [回到 README](../../README.md)

---

## 参考资料

- MySQL 8.4 Reference Manual：The `SET` Type  
  <https://dev.mysql.com/doc/refman/8.4/en/set.html>
- MySQL 8.4 Reference Manual：String Functions and Operators，`FIND_IN_SET()`  
  <https://dev.mysql.com/doc/refman/8.4/en/string-functions.html>
- MySQL 8.4 Reference Manual：Data Type Storage Requirements  
  <https://dev.mysql.com/doc/refman/8.4/en/storage-requirements.html>

# 11 JSON 类型

所属章节：[第十二章_MySQL 数据类型精讲](./README.md)

## 本节导读

这一篇要解决的问题是：

> 当字段内容不是完全固定的关系型结构，而是带有对象、数组、嵌套属性、可扩展配置时，应该用 `JSON`，还是应该拆成普通列？如果用了 `JSON`，又该怎么查询、修改、建索引、避免滥用？

`JSON` 类型很容易被误解成：

- 只是一个高级版 `TEXT`。
- 只要字段很多、结构变化快，就全部塞进 `JSON`。
- `JSON` 很灵活，所以可以不用设计表结构。
- `JSON` 里面的属性可以随便查，性能不会有问题。
- `->` 和 `->>` 只是写法不同，结果差不多。
- `JSON` 字段可以像普通字段一样直接建索引。
- `JSON` 可以代替一对多、多对多关系。

这些理解都不够准确。

真正要先抓住的是：

> MySQL 的 `JSON` 类型适合保存「半结构化数据」，但它不是用来替代关系型建模的。

如果只能先记一句话：

> 稳定、高频查询、需要约束的业务主字段，应该拆成普通列；结构有弹性、低频查询、主要作为扩展信息或原始报文保存的内容，才适合考虑放进 `JSON`。

---

## 关键词

- 主题：MySQL JSON 类型、半结构化数据、JSON 查询、JSON 更新、JSON 索引
- 英文：`JSON`、`JSON_EXTRACT()`、`JSON_UNQUOTE()`、`JSON_SET()`、`JSON_INSERT()`、`JSON_REPLACE()`、`JSON_REMOVE()`、`JSON_CONTAINS()`、`JSON_CONTAINS_PATH()`、`JSON_TABLE()`、`generated column`、`functional index`、`multi-valued index`
- 常见搜索：
  - MySQL JSON 类型
  - MySQL JSON 和 TEXT 区别
  - MySQL JSON_EXTRACT 用法
  - MySQL -> 和 ->> 区别
  - MySQL JSON_SET JSON_INSERT JSON_REPLACE 区别
  - MySQL JSON 字段怎么建索引
  - MySQL JSON generated column index
  - MySQL JSON_TABLE 用法
  - MySQL JSON 默认值
  - MySQL JSON 数组查询
- 易混淆：
  - `JSON` vs `TEXT`
  - `JSON` vs 普通关系型字段
  - `->` vs `->>`
  - `JSON_EXTRACT()` vs `JSON_UNQUOTE()`
  - JSON `null` vs SQL `NULL`
  - JSON 对象 key 重复时的处理
  - JSON 路径不存在 vs 值为 `null`
  - `JSON_SET()` vs `JSON_INSERT()` vs `JSON_REPLACE()`
  - JSON 普通路径索引 vs generated column 索引
  - JSON array 查询 vs 多对多关联表
  - 原始接口报文保存 vs 业务主字段建模

---

## 建议回查情境

遇到下面情况时，可以回到这一篇：

- 想判断某个字段该不该用 `JSON`。
- 想保存用户偏好、扩展配置、第三方接口原始报文。
- 想知道 `JSON` 和 `TEXT` 的差别。
- 想知道 `->` 和 `->>` 的返回结果差别。
- 想从 JSON 字段中取出某个属性做筛选或排序。
- 想局部修改 JSON 文档中的某个 key。
- 想判断 JSON 内是否包含某个值、某个 key 或某个数组元素。
- 想知道 JSON 字段怎么优化查询性能。
- 想知道 JSON 是否可以直接建索引。
- 想把商品扩展属性、用户设置、接口 payload 设计成表字段。
- 想判断旧系统中「一整列 JSON 保存所有业务字段」是否合理。

---

## 30 秒复习入口

- `JSON` 是 MySQL 的原生 JSON 数据类型，不是普通字符串列。
- 写入 `JSON` 列的内容必须是合法 JSON；非法 JSON 会报错。
- MySQL 会把 `JSON` 文档转换成内部格式保存，方便按 key 或数组下标访问。
- `JSON` 的空间开销大致可以理解为接近 `LONGBLOB` / `LONGTEXT` 级别，且受 `max_allowed_packet` 限制。
- `JSON` 适合半结构化数据，例如用户偏好、扩展配置、第三方接口原始响应。
- `JSON` 不适合稳定、高频查询、需要强约束的业务主字段。
- `->` 等价于 `JSON_EXTRACT()` 的简写，返回 JSON 值。
- `->>` 等价于取出后再解包，返回更适合显示或比较的文本值。
- JSON 路径通常从 `$` 开始，例如 `$.name`、`$.address.city`、`$.tags[0]`。
- JSON 数组下标从 `0` 开始。
- `JSON_SET()`：存在就更新，不存在就尽量新增。
- `JSON_INSERT()`：只在路径不存在时新增，存在则不覆盖。
- `JSON_REPLACE()`：只替换已存在路径，不存在则不新增。
- `JSON_REMOVE()`：删除指定路径。
- `JSON_CONTAINS()` 判断是否包含某个 JSON 值。
- `JSON_CONTAINS_PATH()` 判断某个路径是否存在。
- `JSON_TABLE()` 可以把 JSON 数据投影成关系型结果集。
- `JSON` 列本身不能像普通标量列那样直接建立一般索引。
- 高频查询 JSON 内部字段时，常见做法是 generated column + index，或在合适场景下使用 functional index。
- JSON array 的成员查询可以考虑 multi-valued index，但它不是多对多关系的万能替代。
- 需要外键、唯一约束、范围查询、联结、排序、统计的字段，优先拆成普通列。
- 不要因为 `JSON` 灵活，就放弃表结构设计。

---

## 一、先讲结论

`JSON` 类型适合的是「结构有弹性，但仍然希望数据库知道它是 JSON 文档」的场景。

它比 `TEXT` 更强的地方在于：

- 可以自动验证 JSON 合法性。
- 可以使用 JSON 路径提取内部值。
- 可以使用 JSON 函数做局部修改、判断、聚合、转换。
- 可以通过 generated column、functional index 或 multi-valued index 优化部分查询。

但它不等于：

- 不用建表结构。
- 不用设计字段。
- 不用考虑索引。
- 可以任意塞业务主字段。
- 可以替代正常的一对多、多对多关系。

### 1.1 最重要的选型表

| 需求 | 推荐设计 | 说明 |
| --- | --- | --- |
| 订单状态、付款状态、审核状态 | 普通列 | 稳定、高频查询、通常需要索引和约束 |
| 金额、价格、余额、汇率 | `DECIMAL` 普通列 | 精确计算，不要塞 JSON |
| 创建时间、更新时间、业务日期 | `DATETIME` / `TIMESTAMP` 普通列 | 高频排序、范围查询、索引优化 |
| 用户 ID、订单 ID、商品 ID | 普通列 + 外键/索引 | 关系型主字段，不应藏在 JSON 中 |
| 用户偏好设置 | 可考虑 `JSON` | 结构弹性，查询频率通常不高 |
| 商品少量扩展属性 | 普通列 + `JSON` 扩展列 | 核心属性拆列，非核心属性放 JSON |
| 第三方接口原始响应 | 可考虑 `JSON` | 方便追踪、排查、保留原始结构 |
| 表单自定义字段 | 可考虑 `JSON`，但要评估查询需求 | 若经常统计或筛选，可能要抽列或建明细表 |
| 标签、角色、权限 | 通常用关联表 | 多对多关系不建议直接塞 JSON array |
| 多个地址、多个联系方式 | 通常用子表 | 一对多关系应优先建明细表 |
| 操作日志 diff | 可考虑 `JSON` | 适合保存变更前后结构化快照 |
| 搜索条件、高频过滤字段 | 普通列或 generated column | 不要每次全表解析 JSON |

### 1.2 我的实务建议

设计字段时可以这样判断：

```text
第一步：这个属性是不是稳定的业务主字段？
是 -> 优先拆成普通列。

第二步：这个属性是否需要高频 WHERE / ORDER BY / GROUP BY / JOIN？
是 -> 优先拆成普通列，或至少建立 generated column / functional index。

第三步：这个属性是否需要 NOT NULL、UNIQUE、外键、CHECK、范围约束？
是 -> 优先拆成普通列。

第四步：这个属性是否只是扩展配置、附加信息、接口原始报文？
是 -> 可以考虑 JSON。

第五步：JSON 内部字段未来可能变成高频查询条件吗？
可能 -> 一开始就要考虑抽列或索引策略。

第六步：这是多对多或一对多关系吗？
是 -> 通常建关联表或子表，不要只用 JSON array。
```

一句话总结：

> `JSON` 是关系型设计的补充，不是关系型设计的逃避。

---

## 二、什么是 MySQL 的 `JSON` 类型

`JSON` 是 MySQL 支持的原生数据类型，用来保存合法 JSON 文档。

JSON 文档可以是：

- 对象：`{"name": "Alice", "age": 25}`
- 数组：`["java", "mysql", "vue"]`
- 字符串：`"hello"`
- 数字：`123`
- 布尔值：`true` / `false`
- JSON null：`null`

不过在业务表中，最常见的是对象或数组。

### 2.1 基本建表示例

```sql
CREATE TABLE user_profile (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    profile JSON NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_id (user_id)
);
```

插入：

```sql
INSERT INTO user_profile (user_id, profile)
VALUES (
    1001,
    '{
        "nickname": "Alice",
        "preferences": {
            "theme": "dark",
            "language": "zh-TW"
        },
        "tags": ["vip", "beta_user"]
    }'
);
```

这里的 `profile` 不是普通字符串，而是 JSON 文档。

### 2.2 `JSON` 和 `TEXT` 的差别

| 对比点 | `JSON` | `TEXT` |
| --- | --- | --- |
| 是否验证 JSON 合法性 | 会验证 | 不会验证 |
| 是否有 JSON 路径操作 | 有 | 没有专属语义，只是文本 |
| 是否适合保存普通长文本 | 不适合 | 适合 |
| 是否适合保存对象 / 数组结构 | 适合 | 可以存，但数据库不知道语义 |
| 内部处理 | MySQL 按 JSON 语义处理 | 按字符串处理 |
| 查询内部属性 | 可用 `->`、`->>`、JSON 函数 | 需要手动解析或字符串处理 |
| 索引方式 | 通常 generated column / functional index / multi-valued index | prefix index / fulltext 等 |
| 典型用途 | 配置、扩展属性、接口响应 | 文章、备注、说明、日志正文 |

结论：

> 如果内容本质是普通文章、备注、说明，用 `TEXT`；如果内容本质是对象、数组、配置、结构化报文，用 `JSON`。

### 2.3 JSON 的储存特性

MySQL 会把 JSON 文档转换成内部格式保存，而不是单纯把原始字符串原封不动当作普通文字处理。

这带来两个重要结果：

1. MySQL 可以更有效地按 key 或数组下标访问 JSON 内部元素。
2. 原始 JSON 文本中的空白、对象 key 顺序、重复 key，不应该被当成业务逻辑依据。

尤其要注意：

> JSON 对象是键值结构，不要依赖 key 的显示顺序。

---

## 三、合法 JSON 与写入规则

写入 `JSON` 列时，内容必须是合法 JSON。

### 3.1 正确示例

```sql
CREATE TABLE test_json (
    id INT AUTO_INCREMENT PRIMARY KEY,
    js JSON
);

INSERT INTO test_json (js)
VALUES ('{"name":"Alice","age":25}');

INSERT INTO test_json (js)
VALUES ('["java", "mysql", "vue"]');

INSERT INTO test_json (js)
VALUES ('true');

INSERT INTO test_json (js)
VALUES ('null');
```

这些都是合法 JSON。

### 3.2 错误示例

```sql
INSERT INTO test_json (js)
VALUES ('{name:"Alice"}');
```

错误原因：JSON 对象的 key 必须使用双引号。

```sql
INSERT INTO test_json (js)
VALUES ('{"name":"Alice",}');
```

错误原因：最后一个成员后面不能多一个逗号。

```sql
INSERT INTO test_json (js)
VALUES ('hello');
```

错误原因：这不是合法 JSON 字符串。合法 JSON 字符串应该写成：

```sql
INSERT INTO test_json (js)
VALUES ('"hello"');
```

注意这里有两层含义：

```text
SQL 字符串：'"hello"'
JSON 字符串："hello"
```

### 3.3 推荐用 JSON 构造函数减少转义错误

手写 JSON 字符串时，最容易出错的是引号、反斜线、特殊字符。

可以使用 `JSON_OBJECT()` 和 `JSON_ARRAY()`：

```sql
INSERT INTO test_json (js)
VALUES (JSON_OBJECT(
    'name', 'Alice',
    'age', 25,
    'tags', JSON_ARRAY('java', 'mysql', 'vue')
));
```

这样比手写长 JSON 字符串更安全，也更容易维护。

---

## 四、JSON `null` 与 SQL `NULL`

这是非常容易混淆的地方。

### 4.1 SQL `NULL`

SQL `NULL` 表示这个字段本身没有值。

```sql
INSERT INTO test_json (js)
VALUES (NULL);
```

这表示 `js` 这一列是 SQL 层面的 `NULL`。

前提是该字段允许 `NULL`。

### 4.2 JSON `null`

JSON `null` 表示 JSON 文档本身存在，内容是 JSON 的 `null` 值。

```sql
INSERT INTO test_json (js)
VALUES ('null');
```

这表示 `js` 这一列有值，这个值是 JSON 文档 `null`。

### 4.3 实务建议

如果字段是 `JSON NOT NULL`，但你想表示「没有额外配置」，更常见的设计是：

```sql
settings JSON NOT NULL DEFAULT (JSON_OBJECT())
```

或：

```sql
settings JSON NOT NULL DEFAULT (JSON_ARRAY())
```

不要随便混用 SQL `NULL` 和 JSON `null`，否则应用层判断会变复杂。

### 4.4 JSON 默认值的注意事项

在现代 MySQL 中，`JSON` 和 `BLOB`、`TEXT`、`GEOMETRY` 一样，如果要设置默认值，需要把默认值写成表达式形式。

正确：

```sql
CREATE TABLE user_settings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    settings JSON NOT NULL DEFAULT (JSON_OBJECT())
);
```

也可以写成：

```sql
CREATE TABLE user_settings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    settings JSON NOT NULL DEFAULT ('{}')
);
```

不推荐或可能报错的写法：

```sql
CREATE TABLE user_settings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    settings JSON NOT NULL DEFAULT '{}'
);
```

差别在于：

```text
DEFAULT ('{}') -> 表达式形式
DEFAULT '{}'   -> 普通字面量形式
```

实务上，我更推荐：

```sql
DEFAULT (JSON_OBJECT())
DEFAULT (JSON_ARRAY())
```

语义更清楚。

---

## 五、JSON 路径语法

JSON 查询通常要配合路径表达式。

路径从 `$` 开始，表示整份 JSON 文档。

### 5.1 常见路径

假设 JSON 内容如下：

```json
{
  "name": "Alice",
  "age": 25,
  "address": {
    "city": "Taipei",
    "district": "Da'an"
  },
  "tags": ["vip", "beta_user", "java"],
  "orders": [
    {"id": 101, "amount": 300},
    {"id": 102, "amount": 500}
  ]
}
```

常见路径：

| 路径 | 含义 |
| --- | --- |
| `$` | 整份 JSON 文档 |
| `$.name` | 取 `name` |
| `$.address.city` | 取嵌套对象中的 `city` |
| `$.tags[0]` | 取 `tags` 数组第 1 个元素 |
| `$.tags[1]` | 取 `tags` 数组第 2 个元素 |
| `$.orders[0].id` | 取第 1 个订单的 id |
| `$.tags[*]` | 取 `tags` 数组全部元素 |
| `$.*` | 取根对象下一层所有成员 |
| `$**.id` | 递归查找所有名为 `id` 的路径 |

注意：JSON 数组下标从 `0` 开始。

### 5.2 key 名称有空格或特殊字符时

如果 key 不是普通合法标识符，例如：

```json
{
  "a fish": "shark",
  "user-name": "Alice"
}
```

路径要把 key 用双引号包起来：

```sql
'$."a fish"'
'$."user-name"'
```

也就是说：

> key 名称中有空格、连字符或特殊字符时，路径中的 key 要用双引号包起来。

---

## 六、提取 JSON 内部值：`->`、`->>`、`JSON_EXTRACT()`

读取 JSON 内部值时，最常见的是：

- `JSON_EXTRACT(json_doc, path)`
- `json_col -> path`
- `json_col ->> path`

### 6.1 准备测试数据

```sql
CREATE TABLE user_profile_demo (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    profile JSON NOT NULL
);

INSERT INTO user_profile_demo (profile)
VALUES ('{
    "name": "Alice",
    "age": 25,
    "address": {
        "city": "Taipei"
    },
    "tags": ["vip", "java"]
}');
```

### 6.2 `JSON_EXTRACT()`

```sql
SELECT JSON_EXTRACT(profile, '$.name') AS name_json
FROM user_profile_demo;
```

返回结果类似：

```text
"Alice"
```

它返回的是 JSON 值，所以字符串仍然带 JSON 的双引号。

### 6.3 `->`

`->` 可以理解成 `JSON_EXTRACT()` 的简写。

```sql
SELECT profile -> '$.name' AS name_json
FROM user_profile_demo;
```

结果也是 JSON 值：

```text
"Alice"
```

### 6.4 `->>`

`->>` 会取出并解包，比较适合显示、比较或转成其他类型。

```sql
SELECT profile ->> '$.name' AS name_text
FROM user_profile_demo;
```

结果：

```text
Alice
```

### 6.5 `->` 和 `->>` 对比

| 写法 | 近似理解 | 返回语义 | 示例结果 |
| --- | --- | --- | --- |
| `profile -> '$.name'` | `JSON_EXTRACT()` | JSON 值 | `"Alice"` |
| `profile ->> '$.name'` | `JSON_UNQUOTE(JSON_EXTRACT())` | 解包后的文本 | `Alice` |

简单记：

```text
->  取 JSON
->> 取文本
```

### 6.6 数字字段提取时要注意类型

假设 JSON 中有：

```json
{"age": 25}
```

查询：

```sql
SELECT profile ->> '$.age' AS age_text
FROM user_profile_demo;
```

如果要做数值比较，建议显式转换：

```sql
SELECT *
FROM user_profile_demo
WHERE CAST(profile ->> '$.age' AS UNSIGNED) >= 18;
```

不要长期依赖隐式类型转换，否则代码可读性和稳定性都会变差。

---

## 七、查询 JSON 数据

### 7.1 根据普通 key 查询

```sql
SELECT *
FROM user_profile_demo
WHERE profile ->> '$.name' = 'Alice';
```

这适合简单查询。

但如果这个条件非常高频，就要考虑索引策略。

### 7.2 根据嵌套 key 查询

```sql
SELECT *
FROM user_profile_demo
WHERE profile ->> '$.address.city' = 'Taipei';
```

### 7.3 判断路径是否存在

使用 `JSON_CONTAINS_PATH()`：

```sql
SELECT *
FROM user_profile_demo
WHERE JSON_CONTAINS_PATH(profile, 'one', '$.address.city');
```

`'one'` 表示只要指定路径中任意一个存在即可。

也可以用 `'all'`：

```sql
SELECT *
FROM user_profile_demo
WHERE JSON_CONTAINS_PATH(profile, 'all', '$.name', '$.age');
```

表示所有路径都要存在。

### 7.4 判断是否包含指定 JSON 值

```sql
SELECT *
FROM user_profile_demo
WHERE JSON_CONTAINS(profile, '"vip"', '$.tags');
```

注意：`'"vip"'` 是 SQL 字符串，里面包的是 JSON 字符串 `"vip"`。

### 7.5 判断对象是否包含某个结构

```sql
SELECT JSON_CONTAINS(
    '{"address": {"city": "Taipei", "district": "Da''an"}}',
    '{"city": "Taipei"}',
    '$.address'
) AS matched;
```

如果 `$.address` 中包含 `{"city": "Taipei"}`，结果为 `1`。

### 7.6 查询 JSON array 的元素

假设：

```json
{"tags": ["vip", "beta_user", "java"]}
```

可以写：

```sql
SELECT *
FROM user_profile_demo
WHERE JSON_CONTAINS(profile -> '$.tags', '"java"');
```

也可以写：

```sql
SELECT *
FROM user_profile_demo
WHERE JSON_CONTAINS(profile, '"java"', '$.tags');
```

### 7.7 不建议用 `LIKE` 查 JSON

不推荐：

```sql
SELECT *
FROM user_profile_demo
WHERE profile LIKE '%vip%';
```

问题包括：

- 可能误匹配 key 或其他字符串。
- 不理解 JSON 结构。
- 不利于索引优化。
- JSON 格式变化、空格变化、顺序变化时容易出错。

应该优先用 JSON 函数或路径提取。

---

## 八、修改 JSON 数据

修改 JSON 文档时，常见函数有：

- `JSON_SET()`
- `JSON_INSERT()`
- `JSON_REPLACE()`
- `JSON_REMOVE()`

### 8.1 `JSON_SET()`：存在则更新，不存在则新增

```sql
UPDATE user_profile_demo
SET profile = JSON_SET(profile, '$.age', 26)
WHERE id = 1;
```

如果 `$.age` 存在，就更新。

如果 `$.age` 不存在，在合适位置新增。

### 8.2 `JSON_INSERT()`：只新增，不覆盖

```sql
UPDATE user_profile_demo
SET profile = JSON_INSERT(profile, '$.age', 26)
WHERE id = 1;
```

如果 `$.age` 已经存在，通常不会覆盖原值。

适合「只在没有这个属性时补默认值」。

### 8.3 `JSON_REPLACE()`：只替换，不新增

```sql
UPDATE user_profile_demo
SET profile = JSON_REPLACE(profile, '$.age', 26)
WHERE id = 1;
```

如果 `$.age` 存在，就替换。

如果 `$.age` 不存在，不新增。

适合「只允许改既有属性，不允许悄悄加新属性」。

### 8.4 `JSON_REMOVE()`：删除路径

```sql
UPDATE user_profile_demo
SET profile = JSON_REMOVE(profile, '$.age')
WHERE id = 1;
```

这会删除 `age`。

### 8.5 三个修改函数的核心差异

| 函数 | 路径存在 | 路径不存在 | 适合场景 |
| --- | --- | --- | --- |
| `JSON_SET()` | 更新 | 新增 | 最常用的 upsert 风格修改 |
| `JSON_INSERT()` | 不覆盖 | 新增 | 只补默认值，不动既有值 |
| `JSON_REPLACE()` | 更新 | 忽略 | 只改既有属性，不新增结构 |
| `JSON_REMOVE()` | 删除 | 忽略 | 删除指定路径 |

一句话：

```text
SET      = 有就改，没有就加
INSERT   = 没有才加，有就不动
REPLACE  = 有才改，没有不加
REMOVE   = 有就删，没有不动
```

### 8.6 不要为了改一个字段就整份覆盖

不推荐：

```sql
UPDATE user_profile_demo
SET profile = '{"name":"Alice","age":26,"tags":["vip"]}'
WHERE id = 1;
```

风险：

- 可能漏掉原本其他 key。
- 并发更新时更容易覆盖别人的修改。
- 代码维护成本高。

更推荐：

```sql
UPDATE user_profile_demo
SET profile = JSON_SET(profile, '$.age', 26)
WHERE id = 1;
```

不过要注意：

> JSON 局部更新函数不等于任何情况下都只改磁盘上的一小块；是否能触发 MySQL 的 partial update 优化，要满足特定条件。

实务学习阶段先记：

> 语义上局部修改用 JSON 函数，性能上仍然要根据数据大小和执行计划评估。

---

## 九、JSON 常用函数速查

### 9.1 创建 JSON

| 函数 | 作用 | 示例 |
| --- | --- | --- |
| `JSON_OBJECT(k, v, ...)` | 创建 JSON 对象 | `JSON_OBJECT('name','Alice','age',25)` |
| `JSON_ARRAY(v1, v2, ...)` | 创建 JSON 数组 | `JSON_ARRAY('java','mysql')` |
| `JSON_QUOTE(str)` | 把字符串转换成 JSON 字符串字面量 | `JSON_QUOTE('Alice')` |

示例：

```sql
SELECT JSON_OBJECT(
    'name', 'Alice',
    'age', 25,
    'tags', JSON_ARRAY('java', 'mysql')
);
```

### 9.2 查询 JSON

| 函数 / 运算子 | 作用 |
| --- | --- |
| `JSON_EXTRACT(json_doc, path)` | 按路径提取 JSON 值 |
| `col -> path` | `JSON_EXTRACT()` 简写 |
| `col ->> path` | 提取后解包为文本 |
| `JSON_CONTAINS(json_doc, candidate[, path])` | 判断是否包含指定 JSON 值 |
| `JSON_CONTAINS_PATH(json_doc, 'one'/'all', path...)` | 判断路径是否存在 |
| `JSON_SEARCH(json_doc, 'one'/'all', search_str)` | 搜索字符串并返回路径 |

### 9.3 修改 JSON

| 函数 | 作用 |
| --- | --- |
| `JSON_SET(json_doc, path, val...)` | 存在更新，不存在新增 |
| `JSON_INSERT(json_doc, path, val...)` | 不存在才新增 |
| `JSON_REPLACE(json_doc, path, val...)` | 存在才替换 |
| `JSON_REMOVE(json_doc, path...)` | 删除路径 |
| `JSON_ARRAY_APPEND(json_doc, path, val...)` | 向数组追加元素 |
| `JSON_ARRAY_INSERT(json_doc, path, val...)` | 向数组指定位置插入元素 |

### 9.4 查看 JSON 属性

| 函数 | 作用 |
| --- | --- |
| `JSON_TYPE(json_val)` | 返回 JSON 值类型，例如 `OBJECT`、`ARRAY`、`STRING` |
| `JSON_VALID(val)` | 判断是否为合法 JSON |
| `JSON_LENGTH(json_doc[, path])` | 返回对象成员数或数组元素数 |
| `JSON_DEPTH(json_doc)` | 返回 JSON 最大深度 |
| `JSON_KEYS(json_doc[, path])` | 返回对象 key 列表 |
| `JSON_STORAGE_SIZE(json_doc)` | 查看 JSON 二进制表示占用空间 |
| `JSON_STORAGE_FREE(json_doc)` | 查看部分更新后释放的空间 |

### 9.5 转成关系型结果集

`JSON_TABLE()` 可以把 JSON 转成类似表的结果。

例如：

```sql
SELECT jt.*
FROM JSON_TABLE(
    '[{"name":"Alice","age":25},{"name":"Bob","age":30}]',
    '$[*]' COLUMNS (
        name VARCHAR(50) PATH '$.name',
        age INT PATH '$.age'
    )
) AS jt;
```

结果类似：

```text
+-------+-----+
| name  | age |
+-------+-----+
| Alice |  25 |
| Bob   |  30 |
+-------+-----+
```

这个函数适合处理 JSON array 中多行结构的数据。

但如果这种结构长期稳定、经常查询，仍然要考虑是否应该直接建明细表。

---

## 十、JSON 字段怎么建索引

这是 `JSON` 类型最重要的实务问题之一。

### 10.1 先记结论

> `JSON` 列本身不能像 `INT`、`VARCHAR`、`DATETIME` 那样直接建立普通索引来优化任意内部路径查询。

如果经常查询 JSON 中某个路径，常见做法是：

1. 把该路径提取成 generated column。
2. 对 generated column 建索引。
3. 或在支持场景下使用 functional index。
4. 如果是 JSON array 成员查询，可评估 multi-valued index。

### 10.2 错误期待

很多初学者会以为：

```sql
CREATE INDEX idx_profile ON user_profile(profile);
```

然后：

```sql
SELECT *
FROM user_profile
WHERE profile ->> '$.nickname' = 'Alice';
```

就会自动变快。

这个想法不准确。

因为你真正查询的是 `profile` 里面的某个路径，不是整份 JSON 文档的整体值。

### 10.3 generated column + index

假设经常根据 `nickname` 查询：

```sql
CREATE TABLE user_profile_index_demo (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    profile JSON NOT NULL,
    nickname VARCHAR(50)
        GENERATED ALWAYS AS (profile ->> '$.nickname') STORED,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_nickname (nickname)
);
```

之后查询：

```sql
SELECT *
FROM user_profile_index_demo
WHERE nickname = 'Alice';
```

这样比每次在 `WHERE` 中解析 JSON 路径更利于索引。

### 10.4 generated column 适合哪些 JSON 路径

适合抽出来的路径通常有：

- 高频筛选字段
- 高频排序字段
- 高频分组字段
- 需要唯一约束的字段
- 需要和其他表关联的字段
- 需要范围查询的数字或日期字段

例如：

```sql
CREATE TABLE order_ext (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    ext JSON NOT NULL,
    channel VARCHAR(30)
        GENERATED ALWAYS AS (ext ->> '$.channel') STORED,
    risk_score DECIMAL(10, 4)
        GENERATED ALWAYS AS (CAST(ext ->> '$.risk_score' AS DECIMAL(10, 4))) STORED,
    INDEX idx_channel (channel),
    INDEX idx_risk_score (risk_score)
);
```

查询：

```sql
SELECT *
FROM order_ext
WHERE channel = 'mobile'
  AND risk_score >= 0.8;
```

### 10.5 functional index

在较新的 MySQL 版本中，也可以考虑函数索引。

例如概念上：

```sql
CREATE INDEX idx_nickname
ON user_profile ((profile ->> '$.nickname'));
```

不过实务学习和兼容性角度，我建议你先掌握 generated column + index。

原因：

- 可读性更好。
- 更容易被团队理解。
- 查询时可以直接写字段名。
- 类型转换可以显式写清楚。
- 对旧项目或保守环境更友好。

### 10.6 multi-valued index：JSON array 成员索引

如果 JSON 中有数组，例如：

```json
{
  "tags": ["vip", "beta", "java"]
}
```

并且经常查询「数组是否包含某个值」，可以了解 multi-valued index。

概念示例：

```sql
CREATE TABLE customer_tags (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    info JSON NOT NULL,
    INDEX idx_tags ((CAST(info -> '$.tags' AS CHAR(20) ARRAY)))
);
```

然后配合数组成员查询函数使用。

但是要注意：

- 它只适合特定 JSON array 查询场景。
- 它不是主键。
- 它不是外键。
- 它不能替代所有多对多关系表。
- 它有不少限制，学习阶段不建议把它当默认方案。

### 10.7 多对多关系优先用关联表

如果是用户标签：

```text
user_id -> tag_id
```

更常见的关系型设计是：

```sql
CREATE TABLE user_tag (
    user_id BIGINT UNSIGNED NOT NULL,
    tag_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (user_id, tag_id),
    INDEX idx_tag_id (tag_id)
);
```

不要一开始就设计成：

```sql
CREATE TABLE user_profile (
    id BIGINT PRIMARY KEY,
    tags JSON NOT NULL
);
```

除非你很确定：

- 标签只是展示用。
- 不需要复杂查询。
- 不需要标签维表。
- 不需要统计每个标签有多少用户。
- 不需要权限、审计、有效期、创建人等关系属性。

否则关联表更稳。

---

## 十一、`JSON` 的适合场景

### 11.1 用户偏好设置

例如：

```json
{
  "theme": "dark",
  "language": "zh-TW",
  "notification": {
    "email": true,
    "sms": false
  }
}
```

表设计：

```sql
CREATE TABLE user_settings (
    user_id BIGINT UNSIGNED PRIMARY KEY,
    settings JSON NOT NULL DEFAULT (JSON_OBJECT()),
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

适合原因：

- 设置项可能会增加。
- 每个用户配置可能不同。
- 多数时候是按用户整份读取。
- 通常不需要对每个设置项建立复杂关系约束。

### 11.2 商品扩展属性

核心商品字段应该拆列：

```sql
CREATE TABLE product (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id BIGINT UNSIGNED NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    status TINYINT NOT NULL,
    attributes JSON NOT NULL DEFAULT (JSON_OBJECT()),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category_status (category_id, status),
    INDEX idx_price (price)
);
```

`attributes` 可以保存：

```json
{
  "color": "black",
  "size": "M",
  "material": "cotton"
}
```

适合原因：

- 不同品类属性不同。
- 扩展属性变化较快。
- 核心查询字段仍然是普通列。

不适合做法：

```json
{
  "name": "T-shirt",
  "category_id": 10,
  "price": 399,
  "status": 1,
  "color": "black"
}
```

然后整张商品表只有：

```sql
id BIGINT,
data JSON
```

这种设计会让筛选、排序、约束、统计、维护都变麻烦。

### 11.3 第三方接口原始响应

例如银行、支付、物流、征信、风控接口返回的原始报文。

```sql
CREATE TABLE api_call_log (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    request_id VARCHAR(64) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    api_name VARCHAR(100) NOT NULL,
    status VARCHAR(30) NOT NULL,
    request_payload JSON NULL,
    response_payload JSON NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_request_id (request_id),
    INDEX idx_provider_api_time (provider, api_name, created_at)
);
```

适合原因：

- 原始响应结构可能由第三方决定。
- 主要用途是追踪、排查、审计。
- 高频查询条件已经拆成普通列。

### 11.4 操作日志变更内容

```sql
CREATE TABLE audit_log (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT UNSIGNED NOT NULL,
    action VARCHAR(30) NOT NULL,
    before_data JSON NULL,
    after_data JSON NULL,
    operator_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_operator_time (operator_id, created_at)
);
```

适合原因：

- 不同实体的变更字段不同。
- 日志更多是追踪和审计。
- 查询主路径仍然是普通列。

---

## 十二、`JSON` 的不适合场景

### 12.1 订单主数据不要全塞 JSON

不推荐：

```sql
CREATE TABLE orders_bad (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    data JSON NOT NULL
);
```

里面放：

```json
{
  "order_no": "A202601010001",
  "user_id": 1001,
  "amount": 1200.50,
  "status": "PAID",
  "created_at": "2026-01-01 10:00:00"
}
```

问题：

- `user_id` 不方便建外键或联结。
- `amount` 不方便做精确约束和范围查询。
- `status` 不方便建立清楚的状态索引。
- `created_at` 不方便高效排序和时间范围查询。
- 业务字段缺乏类型约束。
- 后续报表统计成本高。

更推荐：

```sql
CREATE TABLE orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(50) NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(18, 2) NOT NULL,
    status TINYINT NOT NULL,
    ext JSON NOT NULL DEFAULT (JSON_OBJECT()),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_order_no (order_no),
    INDEX idx_user_time (user_id, created_at),
    INDEX idx_status_time (status, created_at)
);
```

### 12.2 金额不要放 JSON

不推荐：

```json
{"amount": 1200.50}
```

然后每次查询：

```sql
WHERE CAST(data ->> '$.amount' AS DECIMAL(18,2)) > 1000
```

金额字段通常需要：

- 精确计算。
- 范围查询。
- 排序。
- 汇总。
- 对账。
- 报表统计。

应优先使用：

```sql
amount DECIMAL(18, 2) NOT NULL
```

### 12.3 状态字段不要随便放 JSON

订单状态、审核状态、启用状态、处理结果这类字段通常应该拆列。

不推荐：

```json
{"status": "APPROVED"}
```

推荐：

```sql
status TINYINT NOT NULL COMMENT '1=待审,2=同意,3=不同意,4=补充文件'
```

或使用字典表 / 代码表。

### 12.4 多对多关系不要默认用 JSON array

不推荐：

```json
{"role_ids": [1, 2, 3]}
```

如果角色权限需要：

- 查询某角色有哪些用户。
- 用户角色有效期。
- 谁授予的角色。
- 权限审计。
- 角色停用影响分析。

应该使用关联表：

```sql
CREATE TABLE user_role (
    user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    granted_by BIGINT UNSIGNED NULL,
    granted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    INDEX idx_role_id (role_id)
);
```

---

## 十三、JSON 设计模式

### 13.1 「核心字段拆列 + 扩展字段 JSON」模式

这是最常见、也最稳的模式。

```sql
CREATE TABLE customer (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NULL,
    level TINYINT NOT NULL,
    status TINYINT NOT NULL,
    extra JSON NOT NULL DEFAULT (JSON_OBJECT()),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phone (phone),
    INDEX idx_level_status (level, status)
);
```

`extra` 可以放：

```json
{
  "source": "campaign_2026",
  "preferences": {
    "contact_time": "evening"
  },
  "remark_tags": ["sensitive", "vip"]
}
```

优点：

- 核心业务字段清楚。
- 扩展信息有弹性。
- 查询性能可控。
- 后续某个 JSON 属性变重要时，可以抽成普通列。

### 13.2 「原始 JSON + 提取字段」模式

适合第三方接口。

```sql
CREATE TABLE credit_report_raw (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    request_id VARCHAR(64) NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    provider VARCHAR(50) NOT NULL,
    report JSON NOT NULL,
    score INT
        GENERATED ALWAYS AS (CAST(report ->> '$.score' AS UNSIGNED)) STORED,
    risk_level VARCHAR(20)
        GENERATED ALWAYS AS (report ->> '$.risk_level') STORED,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_customer_time (customer_id, created_at),
    INDEX idx_score (score),
    INDEX idx_risk_level (risk_level)
);
```

这样可以：

- 保留完整原始 JSON。
- 抽出高频字段做查询和报表。
- 避免每次全表扫描解析 JSON。

### 13.3 「配置快照」模式

适合保存规则配置、页面配置、流程配置。

```sql
CREATE TABLE rule_snapshot (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rule_code VARCHAR(50) NOT NULL,
    version_no INT NOT NULL,
    config JSON NOT NULL,
    created_by BIGINT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_rule_version (rule_code, version_no)
);
```

这种场景下，`JSON` 主要作为配置快照保存。

不过如果配置内部字段也需要频繁查询，仍然要抽列或拆表。

---

## 十四、JSON 与 Java / MyBatis 实务提醒

### 14.1 Java 中常见映射方式

MySQL `JSON` 字段在 Java 中常见处理方式有：

- 映射成 `String`
- 映射成 `Map<String, Object>`
- 映射成自定义 DTO
- 映射成 Jackson 的 `JsonNode`
- 使用 MyBatis TypeHandler 做转换

### 14.2 简单场景：映射成 `String`

适合：

- 只是保存和读取原始 JSON。
- 不在 Java 内部频繁操作。
- 主要交给前端或外部系统消费。

缺点：

- Java 侧没有结构约束。
- 修改内部属性不方便。
- 容易出现格式错误，虽然写入 MySQL 时会验证。

### 14.3 中等复杂：映射成 DTO

例如：

```java
public class UserSettings {
    private String theme;
    private String language;
    private Notification notification;
}
```

适合：

- JSON 结构相对稳定。
- Java 侧需要清楚的类型提示。
- 需要校验和业务处理。

缺点：

- 扩展性比 `Map` 差。
- JSON 结构变化时 DTO 要同步调整。

### 14.4 动态结构：映射成 `Map` 或 `JsonNode`

适合：

- 字段不固定。
- 第三方报文结构复杂。
- 只需要局部读取或透传。

但要注意：

- 不要在业务核心逻辑中到处用字符串 key 取值。
- 高频字段还是应该抽出来。
- 重要字段要有校验逻辑。

### 14.5 MyBatis TypeHandler

如果项目中经常使用 JSON 字段，可以封装 TypeHandler，把 JSON 字符串和 Java 对象互相转换。

概念上：

```java
public class JsonTypeHandler<T> extends BaseTypeHandler<T> {
    // 使用 ObjectMapper 做序列化 / 反序列化
}
```

实务建议：

- 不要每个 Mapper 都手写 JSON parse。
- 统一 ObjectMapper 配置。
- 明确空对象 `{}`、空数组 `[]`、SQL `NULL` 的处理规则。
- 对 DTO 增加必要校验。
- 避免把核心业务字段藏在 JSON DTO 里，导致 SQL 不好查。

---

## 十五、常见错误与避坑

### 15.1 错误一：把 `JSON` 当成不用设计表结构的理由

错误想法：

> 需求一直变，那我整张表只放 `id` 和 `data JSON` 就好了。

问题：

- 后续查询越来越复杂。
- SQL 可读性变差。
- 索引设计困难。
- 类型约束弱。
- 报表统计痛苦。
- 和其他表关联不清楚。

更好的做法：

> 核心字段拆列，弹性字段放 JSON。

### 15.2 错误二：高频查询字段藏在 JSON 里

不推荐：

```sql
SELECT *
FROM orders
WHERE data ->> '$.status' = 'PAID'
ORDER BY data ->> '$.created_at' DESC;
```

如果这是高频查询，应该把 `status`、`created_at` 拆成普通列。

### 15.3 错误三：用 JSON 存金额并做计算

不推荐：

```sql
SELECT SUM(CAST(data ->> '$.amount' AS DECIMAL(18, 2)))
FROM orders;
```

金额应使用 `DECIMAL` 普通列。

### 15.4 错误四：用 `LIKE` 查询 JSON

不推荐：

```sql
WHERE data LIKE '%"status":"PAID"%'
```

问题：

- 格式稍微变化就可能匹配失败。
- 可能误匹配。
- 不理解 JSON 结构。
- 通常不能有效利用 JSON 路径相关优化。

### 15.5 错误五：不处理 JSON 路径不存在

例如：

```sql
SELECT data ->> '$.score'
FROM t;
```

如果路径不存在，结果可能是 `NULL`。

你需要区分：

- 路径不存在。
- 路径存在但值是 JSON `null`。
- 字段本身是 SQL `NULL`。
- 类型不符合预期。

重要逻辑中要显式处理。

### 15.6 错误六：以为 JSON key 顺序稳定

MySQL 会对 JSON 值做规范化处理。对象 key 的顺序不应该作为业务逻辑依据。

不要依赖：

```text
JSON 对象显示出来的 key 顺序
```

如果业务需要顺序，应该用数组，并明确保存顺序字段。

### 15.7 错误七：重复 key 以为都会保留

例如：

```json
{"x": 1, "x": 2, "x": 3}
```

JSON 对象中重复 key 本身就不适合依赖。

MySQL 规范化后，不应期待多个同名 key 都能保留下来。

实务建议：

> JSON 对象 key 应该唯一；如果要保存多笔同类值，用数组。

### 15.8 错误八：把 JSON array 当关联表

如果你需要：

- 查某标签对应多少用户。
- 查某角色有哪些权限。
- 给关系增加创建时间、创建人、状态。
- 做外键约束。
- 做关系审计。

请优先使用关联表。

### 15.9 错误九：没有限制 JSON 结构

虽然 MySQL 会验证 JSON 合法性，但不会自动保证你的业务结构一定正确。

例如它只知道这是合法 JSON：

```json
{"age": "twenty"}
```

但你业务上可能要求：

```json
{"age": 20}
```

这种结构校验通常要在应用层做，或进一步使用 JSON schema 验证函数。

---

## 十六、完整建表示例

下面是一个比较合理的「核心字段 + JSON 扩展」示例。

### 16.1 用户资料扩展表

```sql
CREATE TABLE user_profile_full_demo (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,

    -- 核心字段：经常查询、排序、过滤，所以拆成普通列
    nickname VARCHAR(50) NOT NULL,
    gender TINYINT NULL COMMENT '1=男,2=女,3=其他',
    birthday DATE NULL,
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1=启用,2=停用',

    -- 扩展字段：弹性结构
    extra JSON NOT NULL DEFAULT (JSON_OBJECT()),

    -- 从 JSON 中抽出一个高频查询字段
    preferred_language VARCHAR(20)
        GENERATED ALWAYS AS (extra ->> '$.preferences.language') STORED,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_nickname (nickname),
    INDEX idx_preferred_language (preferred_language)
);
```

### 16.2 插入数据

```sql
INSERT INTO user_profile_full_demo (
    user_id,
    nickname,
    gender,
    birthday,
    status,
    extra
) VALUES (
    1001,
    'Alice',
    2,
    '2000-01-01',
    1,
    JSON_OBJECT(
        'preferences', JSON_OBJECT(
            'theme', 'dark',
            'language', 'zh-TW'
        ),
        'tags', JSON_ARRAY('vip', 'beta_user'),
        'third_party', JSON_OBJECT(
            'source', 'campaign_2026'
        )
    )
);
```

### 16.3 查询核心字段

```sql
SELECT user_id, nickname, status
FROM user_profile_full_demo
WHERE status = 1;
```

### 16.4 查询 JSON 扩展字段

```sql
SELECT
    user_id,
    nickname,
    extra ->> '$.preferences.theme' AS theme,
    extra ->> '$.preferences.language' AS language
FROM user_profile_full_demo;
```

### 16.5 使用 generated column 查询

```sql
SELECT user_id, nickname, preferred_language
FROM user_profile_full_demo
WHERE preferred_language = 'zh-TW';
```

### 16.6 修改 JSON 内部属性

```sql
UPDATE user_profile_full_demo
SET extra = JSON_SET(extra, '$.preferences.theme', 'light')
WHERE user_id = 1001;
```

### 16.7 判断标签是否存在

```sql
SELECT *
FROM user_profile_full_demo
WHERE JSON_CONTAINS(extra, '"vip"', '$.tags');
```

---

## 十七、自测问题

### 问题 1

`JSON` 和 `TEXT` 最大的区别是什么？

答案：

`JSON` 会按 JSON 文档语义处理，写入时会验证合法性，并支持 JSON 路径提取、修改、判断等函数；`TEXT` 只是普通长文本，数据库不会理解里面是不是 JSON。

---

### 问题 2

`->` 和 `->>` 的差别是什么？

答案：

`->` 返回 JSON 值，类似 `JSON_EXTRACT()`；`->>` 返回解包后的文本值，类似提取后再 `JSON_UNQUOTE()`。

简单记：

```text
->  取 JSON
->> 取文本
```

---

### 问题 3

订单金额适合放在 JSON 中吗？

答案：

通常不适合。

订单金额需要精确计算、范围查询、排序、汇总、对账，应该使用 `DECIMAL` 普通列。

---

### 问题 4

用户偏好设置适合用 JSON 吗？

答案：

通常适合。

因为用户偏好设置结构可能变化，不同用户字段可能不同，而且多数时候按用户整份读取，不一定需要对每个内部 key 做高频查询。

---

### 问题 5

JSON 字段可以直接建立普通索引优化 `data ->> '$.status'` 吗？

答案：

不能简单这样理解。

如果经常查询 `data ->> '$.status'`，常见做法是把它提取成 generated column，再对 generated column 建索引，或者在合适版本和场景下使用 functional index。

---

### 问题 6

`JSON_SET()`、`JSON_INSERT()`、`JSON_REPLACE()` 的差别是什么？

答案：

```text
JSON_SET()      存在就更新，不存在就新增
JSON_INSERT()   不存在才新增，存在不覆盖
JSON_REPLACE()  存在才更新，不存在不新增
```

---

### 问题 7

JSON array 可以取代多对多关联表吗？

答案：

通常不建议。

如果只是低频展示，可以考虑 JSON array；但如果需要查询、统计、权限、审计、外键、关系属性，应该使用关联表。

---

### 问题 8

为什么不要依赖 JSON 对象 key 的显示顺序？

答案：

因为 MySQL 会对 JSON 值进行规范化处理，对象 key 的排序和显示结果不应作为业务逻辑依据。业务需要顺序时，应使用数组或显式顺序字段。

---

## 十八、本节总结

`JSON` 类型的核心价值不是「可以把一大段文本塞进数据库」，而是：

> MySQL 知道这是一份 JSON 文档，所以可以验证合法性、按路径读取、局部修改、判断包含关系，并在特定设计下优化查询。

最重要的选型规则是：

```text
稳定核心字段 -> 普通列
高频查询字段 -> 普通列或 generated column + index
需要精确计算字段 -> 普通列，例如 DECIMAL
需要外键/唯一/强约束字段 -> 普通列
弹性扩展配置 -> JSON
第三方原始报文 -> JSON
低频附加属性 -> JSON
一对多/多对多关系 -> 通常拆表
```

再进一步：

- `JSON` 不是 `TEXT` 的简单替代品。
- `JSON` 也不是关系型建模的替代品。
- `->` 返回 JSON 值，`->>` 返回解包后的文本。
- 数字、日期从 JSON 中取出后，重要查询应显式 `CAST()`。
- 高频查询 JSON 路径时，要考虑 generated column、functional index 或 multi-valued index。
- JSON array 可以存弹性列表，但不能默认替代关联表。
- JSON 字段的结构约束通常还需要应用层或 JSON schema 验证配合。
- 核心业务字段藏进 JSON，短期省事，长期通常会让查询、索引、报表、维护都变复杂。

一句话抓核心：

> MySQL 的 `JSON` 适合保存半结构化扩展信息；稳定、高频、需要约束的业务主数据仍然应该回到普通关系型字段。

---

## 返回导航

- 上一篇：[10 二进制字符串类型](./mysql-binary-string-types-9-5.md)
- 下一篇：12 空间类型
- 返回：[第十二章_MySQL 数据类型精讲](./README.md)

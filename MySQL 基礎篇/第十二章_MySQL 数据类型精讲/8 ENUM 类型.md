# 8 ENUM 类型

所属章节：[第十二章_MySQL 数据类型精讲](./README.md)

## 本节导读

这一篇要解决的问题是：

> 当一个字段只能从少量固定选项中选一个值时，到底该不该用 `ENUM`？它和普通字符串、数字状态码、字典表有什么差别？

`ENUM` 很容易让人觉得方便：

- 字段值只能从固定列表里选择
- 表结构本身就能看出允许哪些值
- 查询出来又是可读字符串
- 底层存储比完整字符串紧凑

例如：

```sql
status ENUM('pending', 'approved', 'rejected')
```

看起来很直观：这个字段只能是 `pending`、`approved`、`rejected` 其中之一。

但是 `ENUM` 也很容易埋坑，因为它不是普通字符串字段。它对外显示为字符串，但内部有「枚举列表顺序」和「索引编号」的概念。

建表前真正要先问的是：

1. 这个字段是不是只能单选？
2. 这个字段的候选值是不是很少？
3. 这些候选值未来会不会频繁新增、删除、改名、调整顺序？
4. 这个字段是否需要多语言显示、排序号、颜色、启用状态、业务说明等附加信息？
5. 这个字段的排序规则是否真的应该由 `ENUM` 定义顺序决定？
6. 应用程序、报表、其他系统是否需要共享这一组状态定义？
7. 这个字段是否适合由数据库强约束，还是应该交给字典表 / 配置表 / 应用层管理？

如果只能先记一句话：

> `ENUM` 适合「候选值少、只能单选、长期稳定」的字段；如果选项经常变化，通常更适合用字典表、普通状态码或 `VARCHAR + CHECK`。

---

## 关键词

- 主题：MySQL 枚举类型、单选受限值、枚举字段设计
- 英文：ENUM、enumeration、enumerated value、enumeration index、literal value
- 常见搜索：
  - MySQL ENUM 是什么
  - MySQL ENUM 和 VARCHAR 差别
  - MySQL ENUM 和 SET 差别
  - MySQL ENUM 排序规则
  - MySQL ENUM 内部编号
  - MySQL ENUM 可以存数字吗
  - MySQL ENUM invalid value strict mode
  - MySQL ENUM 默认值
  - 状态字段该不该用 ENUM
  - ENUM 还是字典表
- 易混淆：
  - 显示字符串 vs 内部 index
  - `ENUM` 的 index vs 数据库索引 index
  - `ENUM('1','2','3')` vs 数字 1、2、3
  - `ENUM` 默认排序 vs 字符串字典序排序
  - 非 strict mode 的非法值处理 vs strict mode 的错误处理
  - 空字符串 `''` 作为普通枚举值 vs 非法值产生的特殊错误值
  - `ENUM` vs `SET`
  - `ENUM` vs `VARCHAR + CHECK`
  - `ENUM` vs 数字状态码 + 字典表

---

## 建议回查情境

遇到下面情况时，可以回到这一篇：

- 想定义订单状态、审核结果、任务状态、等级、季节、尺码等单选字段。
- 想判断状态字段该用 `ENUM`、`VARCHAR`、`TINYINT` 还是字典表。
- 想理解为什么 `ENUM` 查询出来像字符串，但排序和比较可能不像普通字符串。
- 想知道 `ENUM` 中的枚举项顺序为什么不能随便改。
- 想知道 `ENUM` 插入非法值时，strict mode 和非 strict mode 行为有什么差别。
- 想确认 `ENUM('0','1','2')` 这种写法为什么容易造成误解。
- 想理解 `ENUM` 和 `SET` 的根本差异。
- 想给字段加「只能取几个固定值」的数据库层约束，但又担心后续维护成本。
- 想把旧系统的状态码整理成更清楚的字段设计。

---

## 30 秒复习入口

- `ENUM` 是 MySQL 的一种字符串类型，用来表示「从预定义列表中选择一个值」。
- `ENUM` 适合候选值少、只能单选、长期稳定的字段。
- `ENUM` 查询出来显示为字符串，但内部会把枚举项映射成 index。
- 枚举列表从 `1` 开始编号；`NULL` 的 index 是 `NULL`；非法值在非 strict mode 下可能变成特殊空字符串，其 index 是 `0`。
- `ENUM` 的「index」不是数据库的 B+Tree 索引，而是枚举项在列表中的位置。
- `ENUM` 的默认排序是按枚举项 index 排序，不是按字符串字典序排序。
- 如果要按字符串字面值排序，可以考虑 `ORDER BY CAST(col AS CHAR)` 或 `ORDER BY CONCAT(col)`。
- `ENUM` 值必须是字符串字面量，不能用表达式或变量动态生成。
- `ENUM` 最多可以有 65,535 个不同元素，但实务上不应该设计成这么大。
- `ENUM` 的存储通常为 1 或 2 bytes，取决于枚举项数量。
- `ENUM` 会删除定义中枚举成员末尾的空格。
- `ENUM` 可以指定字符集和排序规则，大小写匹配是否敏感会受 collation 影响。
- 不建议把看起来像数字的值定义成 `ENUM`，例如 `ENUM('0','1','2')`，容易和内部 index 混淆。
- 插入非法值时，如果启用 strict SQL mode，通常会报错；如果没有启用 strict mode，可能插入特殊错误值。
- `ENUM` 选项后续变更需要改表结构，不像字典表只改数据。
- `ENUM` 不适合频繁变更、需要多语言、需要排序号、需要启停管理、需要跨系统共享的状态集合。
- 单选固定值用 `ENUM`；多选集合才考虑 `SET`。
- 业务系统中更常见的长期方案是：小而稳定的状态可用 `ENUM`，复杂且会演进的状态用状态码 / 字典表。

---

## 一、先讲结论

`ENUM` 的价值不是「比 `VARCHAR` 高级」，而是：

> 在数据库字段层面表达「这个字段只能从固定候选值中单选一个」。

它适合的情况很窄，但用对时很清楚；用错时维护成本会比较高。

### 1.1 最重要的选型表

| 需求 | 推荐做法 | 说明 |
| --- | --- | --- |
| 少量、稳定、单选值 | `ENUM` | 例如非常稳定的等级、季节、固定分类 |
| 少量、稳定，但希望标准 SQL 风格 | `VARCHAR + CHECK` | 比 `ENUM` 更接近通用 SQL 约束思路 |
| 状态经常新增 / 删除 / 改名 | 状态码字段 + 字典表 | 改数据即可，不一定要改表结构 |
| 状态需要中文名、英文名、颜色、排序号、启用状态 | 字典表 | `ENUM` 无法优雅承载这些元数据 |
| 字段需要多选 | `SET` 或关联表 | `ENUM` 只能单选 |
| 状态会被多个系统共享 | 状态码 + 统一字典 / 配置 | 避免每张表各自硬编码枚举列表 |
| 只是临时限制几个文本值 | `VARCHAR + CHECK` | 简单、清楚、可读性好 |

### 1.2 我的实务建议

在业务系统里，我建议你这样判断：

```text
第一步：是不是单选？
不是单选 -> 不用 ENUM。

第二步：候选值是否真的很少？
不是很少 -> 不用 ENUM。

第三步：候选值是否长期稳定？
不稳定 -> 优先字典表或状态码。

第四步：是否需要附加属性？
需要中文名、英文名、颜色、排序、启停 -> 优先字典表。

第五步：是否接受修改选项时改表？
不能接受 -> 不用 ENUM。

以上都通过，才考虑 ENUM。
```

所以 `ENUM` 不是不能用，而是不能无脑用。

---

## 二、什么是 `ENUM`

`ENUM` 是 MySQL 提供的一种特殊字符串类型。

它的字段值只能从建表时预先列出的字符串中选择一个。

例如：

```sql
CREATE TABLE review_task (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL,
    review_status ENUM('pending', 'approved', 'rejected') NOT NULL
);
```

这个 `review_status` 字段只能保存：

- `pending`
- `approved`
- `rejected`

插入正常值：

```sql
INSERT INTO review_task (title, review_status)
VALUES
('授信资料初审', 'pending'),
('客户资料复核', 'approved'),
('额度调整审核', 'rejected');
```

查询时看到的是字符串：

```sql
SELECT id, title, review_status
FROM review_task;
```

结果概念上类似：

| id | title | review_status |
| --- | --- | --- |
| 1 | 授信资料初审 | pending |
| 2 | 客户资料复核 | approved |
| 3 | 额度调整审核 | rejected |

所以从使用者角度看，`ENUM` 很像「受限制的字符串字段」。

但从数据库内部行为看，它还有 index 编号、排序规则、非法值处理等特殊细节。

---

## 三、`ENUM` 的内部 index 概念

`ENUM` 最重要的底层概念是：

> 枚举项按照定义顺序，从 `1` 开始分配内部 index。

例如：

```sql
CREATE TABLE enum_demo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    season ENUM('spring', 'summer', 'autumn', 'winter') NOT NULL
);
```

在这个定义中：

| 显示值 | 内部 index |
| --- | ---: |
| `spring` | 1 |
| `summer` | 2 |
| `autumn` | 3 |
| `winter` | 4 |

你可以用数值上下文查看这个 index：

```sql
SELECT season, season + 0 AS season_index
FROM enum_demo;
```

或者：

```sql
SELECT season, CAST(season AS UNSIGNED) AS season_index
FROM enum_demo;
```

这里要特别注意：

> `ENUM` 的 index 不是数据库索引，不是 `CREATE INDEX` 的那个索引。

它只是枚举值在枚举列表中的位置编号。

### 3.1 为什么这个概念重要

因为它会影响：

- 排序结果
- 数值上下文中的计算结果
- 插入数字时的解释方式
- 修改枚举列表顺序后的行为理解
- 非 strict mode 下非法值的排查方式

如果你只把 `ENUM` 当成普通字符串，就很容易在这些地方踩坑。

---

## 四、`ENUM` 的定义顺序不能随便改

`ENUM` 的定义顺序不只是「写起来好看」，它有实际行为意义。

例如：

```sql
priority ENUM('high', 'medium', 'low')
```

此时：

| 显示值 | index |
| --- | ---: |
| `high` | 1 |
| `medium` | 2 |
| `low` | 3 |

如果你改成：

```sql
priority ENUM('low', 'medium', 'high')
```

那么顺序意义就改变了：

| 显示值 | index |
| --- | ---: |
| `low` | 1 |
| `medium` | 2 |
| `high` | 3 |

这会影响默认排序结果，也会影响团队对这个字段的理解。

### 4.1 新增枚举值也要谨慎

如果只是往最后追加新值，例如：

```sql
ALTER TABLE enum_demo
MODIFY season ENUM('spring', 'summer', 'autumn', 'winter', 'rainy') NOT NULL;
```

通常比插入到中间安全，因为已有枚举值的相对顺序比较不容易被改变。

但即使只是追加，也要注意：

- 线上 `ALTER TABLE` 可能涉及锁、复制、DDL 成本。
- 应用程序代码是否已经支持新值。
- 报表、接口、前端下拉选单是否同步更新。
- 其他系统是否会因为未知状态而报错。

所以，不要把 `ENUM` 当成「以后想改就随便改」的配置项。

---

## 五、`ENUM` 的排序规则

`ENUM` 最容易误解的地方之一是排序。

很多人以为：

```sql
ORDER BY enum_col
```

会按照字符串字典序排序。

但 `ENUM` 的默认排序通常是按照枚举项的内部 index 排序。

例如：

```sql
CREATE TABLE sort_demo (
    value ENUM('b', 'a', 'c') NOT NULL
);

INSERT INTO sort_demo (value)
VALUES ('a'), ('b'), ('c');
```

执行：

```sql
SELECT value
FROM sort_demo
ORDER BY value;
```

排序概念上会按照定义顺序：

```text
b -> a -> c
```

而不是字典序：

```text
a -> b -> c
```

因为定义时 `b` 的 index 是 1，`a` 的 index 是 2，`c` 的 index 是 3。

### 5.1 如果想按字符串字面值排序

可以显式把 `ENUM` 当成字符来排序：

```sql
SELECT value
FROM sort_demo
ORDER BY CAST(value AS CHAR);
```

或者：

```sql
SELECT value
FROM sort_demo
ORDER BY CONCAT(value);
```

这可以让排序更接近普通字符串排序。

### 5.2 实务建议

如果字段的排序具有明确业务语义，不建议长期依赖 `ENUM` 的定义顺序来表达。

例如审核状态：

```text
pending -> processing -> approved -> rejected -> cancelled
```

这个顺序到底代表：

- 流程顺序？
- 展示顺序？
- 优先级顺序？
- 默认排序顺序？

如果这些语义会变化，建议使用独立字段表达排序，例如字典表中的 `sort_order`。

---

## 六、`ENUM` 的非法值处理

`ENUM` 字段只能存预定义值。

例如：

```sql
CREATE TABLE review_demo (
    status ENUM('pending', 'approved', 'rejected') NOT NULL
);
```

如果插入：

```sql
INSERT INTO review_demo (status)
VALUES ('cancelled');
```

`cancelled` 不在枚举列表里，因此是非法值。

### 6.1 strict mode 下

如果启用了 strict SQL mode，插入非法 `ENUM` 值通常会报错，数据不会被正常插入。

这比较符合现代业务系统的预期：

> 数据不合法就应该尽早失败，而不是悄悄变成别的值。

### 6.2 非 strict mode 下

如果没有启用 strict SQL mode，MySQL 可能会把非法值转成一个特殊的空字符串错误值。

这个特殊值的内部 index 是 `0`。

可以这样排查：

```sql
SELECT *
FROM review_demo
WHERE status = 0;
```

或者：

```sql
SELECT status, status + 0 AS status_index
FROM review_demo;
```

如果看到 `status_index = 0`，就要特别警觉，因为这通常代表曾经插入过非法枚举值。

### 6.3 不要用非 strict mode 兜底业务错误

不建议依赖非 strict mode 的自动转换。

更好的做法是：

- 数据库启用严格模式。
- 应用层先验证枚举值。
- 插入失败时明确抛出错误。
- 不要让非法状态静默进入数据库。

---

## 七、空字符串与 `NULL`

`ENUM` 中有两个容易混淆的特殊情况：

- 空字符串 `''`
- `NULL`

### 7.1 `NULL`

如果 `ENUM` 字段允许 `NULL`，那么 `NULL` 是合法值。

例如：

```sql
CREATE TABLE nullable_enum_demo (
    status ENUM('pending', 'approved', 'rejected') NULL
);
```

此时可以插入：

```sql
INSERT INTO nullable_enum_demo (status)
VALUES (NULL);
```

如果 `ENUM` 字段允许 `NULL`，默认值通常也是 `NULL`。

### 7.2 `NOT NULL` 时的默认值

如果 `ENUM` 字段声明为 `NOT NULL`，且没有显式指定默认值，默认值通常是枚举列表中的第一个元素。

例如：

```sql
CREATE TABLE default_enum_demo (
    status ENUM('pending', 'approved', 'rejected') NOT NULL
);
```

如果没有显式传入 `status`，可能默认使用第一个枚举值 `pending`。

但实务上我更建议你明确写出默认值：

```sql
CREATE TABLE default_enum_demo (
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending'
);
```

这样可读性更好，也比较不依赖隐式规则。

### 7.3 空字符串 `''`

`ENUM` 可以把空字符串定义成一个正常枚举成员：

```sql
status ENUM('', 'pending', 'approved')
```

但是我不建议这样设计。

原因是：非 strict mode 下，非法枚举值也可能被转成一个特殊空字符串错误值，其 index 是 `0`。

如果你又把普通空字符串也定义成合法枚举值，排查时就会变得非常混乱。

如果真的遇到旧系统这样设计，可以用数值上下文区分：

```sql
SELECT status, status + 0 AS status_index
FROM some_table;
```

普通定义出来的 `''` 会有正常 index；非法值产生的特殊错误值 index 是 `0`。

### 7.4 实务建议

对于状态字段，我建议：

```sql
status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending'
```

而不是：

```sql
status ENUM('', 'pending', 'approved', 'rejected')
```

也不要用 `''` 表示未知状态。

如果状态未知，可以考虑：

- 允许 `NULL`，表示未知。
- 增加明确枚举值，例如 `unknown`。
- 用业务流程避免未知状态进入表。

---

## 八、不要把数字当作 `ENUM` 值

这是 `ENUM` 最容易踩坑的地方。

例如：

```sql
CREATE TABLE number_enum_demo (
    level ENUM('0', '1', '2') NOT NULL
);
```

表面上看，这个字段允许字符串 `'0'`、`'1'`、`'2'`。

但它的内部 index 是：

| 显示值 | index |
| --- | ---: |
| `'0'` | 1 |
| `'1'` | 2 |
| `'2'` | 3 |

也就是说：

```text
显示值 '0' 的内部 index 不是 0，而是 1。
显示值 '1' 的内部 index 不是 1，而是 2。
显示值 '2' 的内部 index 不是 2，而是 3。
```

这会非常容易混淆。

### 8.1 插入数字时更危险

如果插入数字：

```sql
INSERT INTO number_enum_demo (level)
VALUES (2);
```

MySQL 可能会把 `2` 当成枚举 index，而不是字符串 `'2'`。

因此它可能存成 index 为 2 的值，也就是 `'1'`。

这和很多人的直觉完全相反。

### 8.2 插入带引号的数字也不一定安全

如果插入：

```sql
INSERT INTO number_enum_demo (level)
VALUES ('2');
```

如果 `'2'` 是枚举列表中的合法字符串，则它会按字符串值匹配。

但如果某些值既可能被当成字符串，又可能被当成 index，团队维护时会非常容易误判。

### 8.3 正确建议

不要这样设计：

```sql
status ENUM('0', '1', '2')
```

如果你想保存数字状态码，更适合：

```sql
status_code TINYINT UNSIGNED NOT NULL
```

再搭配应用层常量或字典表：

```sql
CREATE TABLE status_dict (
    code TINYINT UNSIGNED PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    description VARCHAR(100) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    enabled TINYINT(1) NOT NULL DEFAULT 1
);
```

如果你想用可读文本枚举，就用有语义的字符串：

```sql
status ENUM('pending', 'approved', 'rejected')
```

不要用看起来像数字的枚举项。

---

## 九、`ENUM` 的大小写、字符集与排序规则

`ENUM` 是字符串类型，因此它会受到字符集和排序规则影响。

例如：

```sql
status ENUM('pending', 'approved', 'rejected')
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci
```

这里的 collation 会影响比较行为。

### 9.1 大小写是否敏感

在大小写不敏感的 collation 下，插入或比较时可能不会严格区分大小写。

在 binary 或大小写敏感的 collation 下，大小写会被更严格地区分。

例如：

```sql
status ENUM('new', 'done')
```

在某些不区分大小写的排序规则下，`'NEW'` 可能匹配 `'new'`。

但是查询出来显示时，会按照枚举定义中的字面形式显示。

### 9.2 实务建议

为了避免混乱，枚举值建议使用统一命名风格，例如全部小写：

```sql
ENUM('pending', 'processing', 'approved', 'rejected')
```

不要混用：

```sql
ENUM('Pending', 'PROCESSING', 'approved', 'Rejected')
```

如果你的业务需要严格区分大小写，应该明确设置合适的字符集和 collation，而不是只靠团队默契。

---

## 十、`ENUM` 的存储空间

`ENUM` 的一个优点是存储紧凑。

它不会像 `VARCHAR` 那样为每一行存完整字符串，而是把枚举值编码成内部编号。

一般可以这样理解：

| 枚举项数量 | 存储空间 |
| --- | --- |
| 较少枚举项 | 通常 1 byte |
| 较多枚举项 | 通常 2 bytes |
| 上限 | 最多 65,535 个不同元素 |

例如：

```sql
size ENUM('x-small', 'small', 'medium', 'large', 'x-large')
```

每一行实际不需要存完整的 `'medium'` 字符串，而是存内部编号。

### 10.1 不要把存储节省当作主要理由

虽然 `ENUM` 比较省空间，但现代业务系统里，选择它的主要理由不应该只是省几个 bytes。

更重要的是：

- 是否能准确表达业务语义。
- 是否方便维护。
- 是否能被团队清楚理解。
- 是否会影响未来扩展。

如果一个状态未来会频繁变化，用 `ENUM` 省空间，可能会换来更高的维护成本。

---

## 十一、`ENUM` 和 `VARCHAR + CHECK`

在现代 MySQL 中，如果你只是想限制某个字符串字段只能取几个值，也可以考虑 `VARCHAR + CHECK`。

例如：

```sql
CREATE TABLE review_task_check (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    status VARCHAR(20) NOT NULL,
    CONSTRAINT chk_review_status
        CHECK (status IN ('pending', 'approved', 'rejected'))
);
```

这种写法的特点是：

- 字段本质上仍是普通字符串。
- 约束条件清楚写在 `CHECK` 中。
- 排序默认更接近普通字符串语义。
- 语义更接近标准 SQL 的约束方式。

但它也不是万能的。

如果要新增合法值，仍然需要修改 `CHECK` 约束。

### 11.1 两者怎么选

| 对比项 | `ENUM` | `VARCHAR + CHECK` |
| --- | --- | --- |
| 字段类型 | MySQL 特有枚举类型 | 普通字符串类型 |
| 约束位置 | 类型定义中 | `CHECK` 约束中 |
| 查询显示 | 字符串 | 字符串 |
| 内部 index | 有 | 无 |
| 默认排序 | 按枚举 index | 按字符串 / collation |
| 存储空间 | 通常更紧凑 | 按字符串实际长度 |
| 跨数据库迁移 | 较弱 | 较好 |
| 是否需要注意数字枚举陷阱 | 需要 | 较少 |

### 11.2 实务建议

如果你正在做 MySQL 专案，而且字段非常稳定，`ENUM` 可以接受。

如果你希望设计更贴近通用 SQL，或者不想引入 `ENUM` 内部 index 行为，可以考虑 `VARCHAR + CHECK`。

如果状态会持续变化，两者都不是最好的选择，应该考虑字典表。

---

## 十二、`ENUM` 和数字状态码

很多系统喜欢用数字状态码：

```sql
status TINYINT UNSIGNED NOT NULL
```

例如：

| status | 含义 |
| ---: | --- |
| 0 | 待审核 |
| 1 | 通过 |
| 2 | 拒绝 |
| 3 | 取消 |

这种做法的优点是：

- 存储紧凑。
- 和 Java 枚举、常量类、接口状态码容易对应。
- 修改显示名称不一定要改表结构。
- 可以搭配字典表扩展更多信息。

缺点是：

- 单看表数据不直观。
- 如果没有字典表或代码说明，容易不知道 `1`、`2` 代表什么。
- 容易出现「魔法数字」。

### 12.1 数字状态码 + 字典表

更完整的设计可以是：

```sql
CREATE TABLE review_status_dict (
    code TINYINT UNSIGNED PRIMARY KEY,
    code_name VARCHAR(30) NOT NULL UNIQUE,
    display_name VARCHAR(30) NOT NULL,
    description VARCHAR(200) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    enabled TINYINT(1) NOT NULL DEFAULT 1
);
```

业务表：

```sql
CREATE TABLE review_task_code (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL,
    status_code TINYINT UNSIGNED NOT NULL,
    CONSTRAINT fk_review_status
        FOREIGN KEY (status_code) REFERENCES review_status_dict(code)
);
```

这种设计适合：

- 状态很多。
- 状态会扩展。
- 状态需要显示名称。
- 状态需要排序。
- 状态需要启用 / 停用。
- 状态需要多语言。
- 多张表需要共享同一套状态定义。

### 12.2 和 `ENUM` 的差异

| 对比项 | `ENUM` | 数字状态码 + 字典表 |
| --- | --- | --- |
| 可读性 | 表中直接显示字符串 | 表中显示数字，需要 join 或代码解释 |
| 扩展性 | 改选项要改表结构 | 改字典数据即可 |
| 附加属性 | 不方便 | 很方便 |
| 多语言 | 不方便 | 可以扩展语言表 |
| 统一管理 | 较弱 | 较强 |
| 小型稳定字段 | 方便 | 可能略重 |
| 复杂业务状态 | 不推荐 | 推荐 |

### 12.3 实务建议

小型、稳定、单表内部使用的状态，可以考虑 `ENUM`。

复杂、会演进、会跨系统共享的状态，建议用状态码 + 字典表。

---

## 十三、`ENUM` 和 `SET`

`ENUM` 和 `SET` 都是 MySQL 的特殊字符串类型，但它们解决的问题不同。

| 对比项 | `ENUM` | `SET` |
| --- | --- | --- |
| 核心语义 | 单选 | 多选 |
| 一个字段能存几个选项 | 只能一个 | 可以多个 |
| 适合场景 | 状态、等级、类型 | 标签、权限开关、多个属性组合 |
| 内部机制 | 枚举项 index | 位图组合 |
| 是否适合复杂多对多关系 | 不适合 | 通常也不适合 |

例如：

```sql
status ENUM('pending', 'approved', 'rejected')
```

表示一个任务只能处于一个状态。

而：

```sql
tags SET('urgent', 'internal', 'vip')
```

可能表示一个对象可以同时具有多个标签。

### 13.1 选择规则

```text
只能选一个 -> ENUM
可以选多个 -> SET 或关联表
复杂多选关系 -> 优先关联表
```

如果标签需要很多元数据，例如标签名称、颜色、排序、创建者、创建时间，那么不要把它塞进 `SET`，更适合用标签表 + 中间表。

---

## 十四、`ENUM` 的适合场景

`ENUM` 比较适合这些情况：

### 14.1 很稳定的小集合

例如：

```sql
season ENUM('spring', 'summer', 'autumn', 'winter')
```

季节集合比较稳定，不太会新增第五季。

### 14.2 固定等级或分类

例如：

```sql
risk_level ENUM('low', 'medium', 'high')
```

前提是这个等级体系长期稳定，不会经常新增 `very_high`、`critical`、`unknown` 等值。

### 14.3 简单审核结果

例如：

```sql
review_result ENUM('approved', 'rejected')
```

如果审核结果只有通过 / 拒绝，且长期不变，`ENUM` 很清楚。

但是如果后来会出现：

- 待补件
- 退回修改
- 人工复核
- 系统自动通过
- 风控冻结
- 主管复核

那就不要一开始过度依赖 `ENUM`。

### 14.4 小型内部工具

如果是小型后台管理工具、内部脚本、临时系统，且状态集合非常稳定，使用 `ENUM` 可以让表结构清楚。

---

## 十五、`ENUM` 不适合的场景

### 15.1 状态经常变化

例如订单状态、风控状态、流程状态，很多时候会随着业务持续扩展。

你一开始可能只有：

```text
pending, paid, shipped, completed
```

后来可能变成：

```text
pending_payment,
paid,
payment_failed,
risk_checking,
manual_review,
stock_preparing,
partially_shipped,
shipped,
delivered,
completed,
refund_requested,
refunding,
refunded,
cancelled
```

这种状态如果用 `ENUM`，每次扩展都要改表结构。

### 15.2 需要多语言显示

例如状态要显示成：

| code | zh_TW | zh_CN | en_US |
| --- | --- | --- | --- |
| pending | 待處理 | 待处理 | Pending |
| approved | 同意 | 同意 | Approved |
| rejected | 不同意 | 不同意 | Rejected |

这时应该使用字典表 / 国际化表，而不是把中文显示文案写死在 `ENUM` 里。

### 15.3 需要附加属性

如果状态需要这些属性：

- 显示名称
- 排序号
- 标签颜色
- 是否启用
- 是否终态
- 是否允许回退
- 下一步可流转状态
- 所属业务线

那 `ENUM` 就太弱了。

### 15.4 需要复杂流程流转

例如审批流程：

```text
草稿 -> 待初审 -> 待复审 -> 待主管审 -> 通过 / 拒绝 / 补件
```

这不是单纯的数据类型问题，而是流程状态机问题。

更适合：

- 状态表
- 状态流转表
- 工作流引擎
- 应用层状态机

而不是单纯把所有状态塞进 `ENUM`。

### 15.5 需要跨系统共享

如果多个系统都要使用同一套状态：

- 前端
- 后端
- 报表系统
- 批次系统
- 外部 API
- 数据仓库

那么状态定义最好集中管理。

单张表里的 `ENUM` 不适合当成跨系统的状态字典中心。

---

## 十六、`ENUM` 修改选项的风险

修改 `ENUM` 通常需要改表结构。

例如新增状态：

```sql
ALTER TABLE review_task
MODIFY review_status ENUM('pending', 'approved', 'rejected', 'cancelled') NOT NULL;
```

看起来很简单，但在正式系统中要考虑：

- 表是否很大。
- DDL 是否会锁表或影响写入。
- 是否需要灰度发布。
- 应用程序是否已经支持新值。
- 旧版本应用是否会读取到未知值。
- 报表逻辑是否要调整。
- 数据同步、ETL、下游系统是否要调整。

### 16.1 删除枚举值更危险

如果要删除某个枚举值，例如删除 `rejected`：

```sql
ALTER TABLE review_task
MODIFY review_status ENUM('pending', 'approved') NOT NULL;
```

必须先确认现有数据中没有这个值：

```sql
SELECT COUNT(*)
FROM review_task
WHERE review_status = 'rejected';
```

如果现有数据仍有 `rejected`，直接修改可能造成数据转换错误或数据语义丢失。

### 16.2 改名也不是简单改文字

如果想把：

```text
approved
```

改成：

```text
agree
```

这不是单纯改显示名，而是在改变数据库允许的实际值。

更安全的流程通常是：

1. 新增新枚举值。
2. 应用程序同时兼容旧值和新值。
3. 执行数据迁移。
4. 确认没有旧值。
5. 移除旧枚举值。
6. 清理旧代码。

如果只是显示文案要改，说明你可能一开始就不该把显示文案写进 `ENUM`，而应该用 code + display name 的设计。

---

## 十七、`ENUM` 的建表示例

下面是一个比较适合 `ENUM` 的小型示例：

```sql
CREATE TABLE approval_record (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    applicant_name VARCHAR(50) NOT NULL COMMENT '申请人姓名',
    title VARCHAR(100) NOT NULL COMMENT '申请标题',
    review_result ENUM('pending', 'approved', 'rejected')
        NOT NULL
        DEFAULT 'pending'
        COMMENT '审核结果：pending待审核，approved同意，rejected不同意',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_review_result (review_result),
    INDEX idx_created_at (created_at)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '审核记录表';
```

这个设计可以接受的前提是：

- 审核结果长期只有这几种。
- 不需要多语言。
- 不需要颜色、排序、启停等字典属性。
- 可以接受新增结果时修改表结构。

### 17.1 更灵活的字典表示例

如果状态未来可能扩展，建议这样设计：

```sql
CREATE TABLE approval_status_dict (
    code VARCHAR(30) PRIMARY KEY COMMENT '状态代码',
    display_name VARCHAR(50) NOT NULL COMMENT '显示名称',
    description VARCHAR(200) NULL COMMENT '状态说明',
    sort_order INT NOT NULL DEFAULT 0 COMMENT '排序号',
    enabled TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '审核状态字典表';
```

业务表：

```sql
CREATE TABLE approval_record_v2 (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    applicant_name VARCHAR(50) NOT NULL COMMENT '申请人姓名',
    title VARCHAR(100) NOT NULL COMMENT '申请标题',
    status_code VARCHAR(30) NOT NULL COMMENT '审核状态代码',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT fk_approval_status
        FOREIGN KEY (status_code) REFERENCES approval_status_dict(code),
    INDEX idx_status_code (status_code),
    INDEX idx_created_at (created_at)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '审核记录表';
```

这种设计更适合长期演进的业务系统。

---

## 十八、查询 `ENUM` 的常见写法

### 18.1 按字符串值查询

```sql
SELECT *
FROM approval_record
WHERE review_result = 'approved';
```

这是最常见、也最推荐的写法。

### 18.2 查看内部 index

```sql
SELECT review_result,
       review_result + 0 AS review_result_index
FROM approval_record;
```

这个写法适合学习、排查问题，不建议在业务代码中过度依赖。

### 18.3 查找非法枚举错误值

如果旧系统曾经在非 strict mode 下插入非法值，可以检查 index 为 0 的行：

```sql
SELECT *
FROM approval_record
WHERE review_result = 0;
```

### 18.4 按枚举定义顺序排序

```sql
SELECT *
FROM approval_record
ORDER BY review_result;
```

这会按枚举 index 排序。

### 18.5 按字符串字面值排序

```sql
SELECT *
FROM approval_record
ORDER BY CAST(review_result AS CHAR);
```

或者：

```sql
SELECT *
FROM approval_record
ORDER BY CONCAT(review_result);
```

---

## 十九、Java / MyBatis 中的实务提醒

如果你是 Java 后端开发，在使用 `ENUM` 字段时要特别注意类型映射。

### 19.1 Java 实体类可以用 String

最简单的写法：

```java
private String reviewResult;
```

优点：

- 映射简单。
- 不容易和数据库驱动产生额外转换问题。

缺点：

- 应用层类型不够强。
- 容易传入非法字符串。

### 19.2 Java 实体类可以用枚举类

例如：

```java
public enum ReviewResult {
    PENDING,
    APPROVED,
    REJECTED
}
```

但要注意 Java 枚举名称和数据库枚举值如何映射。

数据库常见值是小写：

```text
pending, approved, rejected
```

Java 常见枚举名是大写：

```text
PENDING, APPROVED, REJECTED
```

此时需要明确转换规则。

### 19.3 不要让数据库 ENUM 和 Java enum 各自失控

如果数据库 `ENUM` 有：

```sql
ENUM('pending', 'approved', 'rejected')
```

Java enum 却有：

```java
PENDING, APPROVED, REJECTED, CANCELLED
```

就会出现应用层和数据库层不一致的问题。

因此要确保：

- 数据库枚举值和 Java 枚举值同步维护。
- 新增枚举值时，同时调整数据库、后端、前端、测试、报表。
- 不要只改 Java enum，却忘了改数据库 `ENUM`。

### 19.4 大型系统更建议统一状态定义

如果状态是核心业务概念，不建议让数据库 `ENUM`、Java enum、前端常量、报表字典各自维护一份。

更好的方式是：

- 使用统一字典表。
- 或使用代码生成 / 配置中心同步状态定义。
- 或将状态定义集中在领域模型中，再通过迁移脚本同步数据库约束。

---

## 二十、常见错误示例

### 错误 1：把经常变化的业务状态写成 `ENUM`

不推荐：

```sql
order_status ENUM('pending', 'paid', 'shipped', 'completed')
```

如果你的订单流程非常稳定，这可以接受。

但大多数订单系统会不断增加支付失败、取消、退款、风控、拆单、部分发货等状态。

更推荐：

```sql
order_status_code VARCHAR(30) NOT NULL
```

再搭配状态字典表。

### 错误 2：把数字字符串写进 `ENUM`

不推荐：

```sql
status ENUM('0', '1', '2')
```

容易和内部 index 混淆。

更推荐：

```sql
status_code TINYINT UNSIGNED NOT NULL
```

或者：

```sql
status ENUM('pending', 'approved', 'rejected')
```

### 错误 3：用中文显示文案作为枚举值

不推荐：

```sql
result ENUM('待審核', '同意', '不同意', '補充文件')
```

问题是：

- 显示文案以后可能会改。
- 繁简中文可能不同。
- 多语言难处理。
- 程序中引用中文值不方便。

更推荐：

```sql
result ENUM('pending', 'approved', 'rejected', 'supplement_required')
```

或者使用字典表。

### 错误 4：依赖 `ENUM` 顺序表达复杂业务排序

不推荐：

```sql
priority ENUM('urgent', 'high', 'normal', 'low')
```

然后默认：

```sql
ORDER BY priority
```

这样虽然能跑，但排序语义隐藏在字段定义里。

如果排序规则未来会变，建议显式维护排序字段：

```sql
priority_code VARCHAR(20) NOT NULL
priority_sort INT NOT NULL
```

或者放到字典表中。

### 错误 5：用 `ENUM` 表示多选

不推荐：

```sql
user_tags ENUM('vip', 'internal', 'blacklist')
```

如果用户可能同时是 `vip` 和 `internal`，那 `ENUM` 不适合。

可以考虑：

- `SET`
- 标签表 + 用户标签关联表

复杂系统中更推荐关联表。

---

## 二十一、实务选型流程

可以把 `ENUM` 的选择流程整理成下面这张表。

| 问题 | 如果答案是「是」 | 如果答案是「否」 |
| --- | --- | --- |
| 字段是否只能单选？ | 继续判断 | 不用 `ENUM` |
| 候选值是否很少？ | 继续判断 | 用字典表或普通字段 |
| 候选值是否长期稳定？ | 继续判断 | 用字典表 |
| 是否不需要多语言和附加属性？ | 继续判断 | 用字典表 |
| 是否接受修改选项时改表？ | 可以考虑 `ENUM` | 用字典表或普通字段 |
| 是否需要按定义顺序排序？ | `ENUM` 可表达简单顺序 | 显式排序字段更清楚 |
| 值是否看起来像数字？ | 不建议用 `ENUM` | 可继续考虑 |

简化成一句话：

```text
小、稳、单选、无附加属性、能接受改表，才适合 ENUM。
```

---

## 二十二、和其他类型的总对比

| 设计方式 | 适合场景 | 优点 | 缺点 |
| --- | --- | --- | --- |
| `ENUM` | 小型稳定单选值 | 约束清楚、显示可读、存储紧凑 | 修改选项要改表，排序按 index，迁移性较弱 |
| `VARCHAR` | 普通字符串状态 | 简单灵活 | 缺少数据库层限制，容易拼错 |
| `VARCHAR + CHECK` | 少量固定文本值 | 普通字符串 + 数据库约束 | 新增值仍需改约束 |
| `TINYINT` 状态码 | 固定数字状态 | 存储小、程序处理方便 | 表数据不直观，容易魔法数字 |
| 状态码 + 字典表 | 会演进的业务状态 | 扩展性强、可管理附加属性 | 设计稍复杂，需要 join 或缓存 |
| `SET` | 简单多选值 | 单字段可存多个选项 | 复杂多选关系不推荐 |
| 关联表 | 标签、权限、复杂多对多 | 规范、扩展性强 | 表结构和查询更复杂 |

---

## 二十三、面试与复习重点

如果面试中被问到 `ENUM`，可以这样回答：

> `ENUM` 是 MySQL 的枚举类型，适合字段只能从少量固定值中单选一个的场景。它查询出来是字符串，但内部会按定义顺序映射成 index，因此排序默认会受枚举定义顺序影响。它的优点是约束清楚、存储紧凑，缺点是后续新增、删除、改名选项都要改表结构，不适合频繁变化或需要字典属性的业务状态。对于复杂业务，更建议用状态码加字典表。

可以展开成四个点：

1. `ENUM` 是受限字符串类型。
2. `ENUM` 内部有 index，定义顺序有行为意义。
3. `ENUM` 适合小而稳定的单选值。
4. 复杂、可变、多语言、有附加属性的状态应该用字典表。

---

## 常见混淆点

### 1. `ENUM` 查询出来是字符串，所以它就是普通字符串吗？

不是。

它显示为字符串，但内部有枚举 index，排序、数值上下文、非法值处理都有特殊行为。

### 2. `ENUM` 的 index 是数据库索引吗？

不是。

`ENUM` 的 index 是枚举项在列表中的位置，不是 B+Tree 索引，也不是 `CREATE INDEX` 建出来的索引。

### 3. `ENUM` 可以存数字吗？

技术上可以定义看起来像数字的字符串枚举值，但不建议。

例如 `ENUM('0','1','2')` 很容易和内部 index 混淆。

如果你要数字状态码，用 `TINYINT` / `SMALLINT` 更清楚。

### 4. `ENUM` 排序按什么来？

默认按枚举项的内部 index，也就是定义顺序。

如果要按字符串字面值排序，需要显式转换，例如：

```sql
ORDER BY CAST(enum_col AS CHAR)
```

### 5. `ENUM` 插入非法值会怎样？

启用 strict SQL mode 时通常会报错。

非 strict mode 下可能插入特殊空字符串错误值，其 index 是 `0`。

### 6. `ENUM` 可以有空字符串吗？

可以，但不建议。

因为非 strict mode 下非法值也可能表现成特殊空字符串，容易混淆。

### 7. `ENUM` 和 `SET` 最大差别是什么？

`ENUM` 是单选。

`SET` 是多选。

### 8. 状态字段是不是都适合 `ENUM`？

不是。

状态字段如果长期稳定，可以考虑 `ENUM`。

如果状态会持续扩展，建议用状态码 + 字典表。

### 9. `ENUM` 可以替代字典表吗？

只能在非常简单的场景下替代。

只要需要显示名、排序、颜色、多语言、启停管理、状态说明，就不适合用 `ENUM` 替代字典表。

### 10. `ENUM` 的最大元素数量是多少？

MySQL 中 `ENUM` 最多可以有 65,535 个不同元素。

但这只是技术上限，不代表实务上应该这样设计。一个 `ENUM` 如果有几十、几百个值，通常就该重新思考数据模型。

---

## 自测问题

1. `ENUM` 最适合什么样的字段？
2. 为什么说 `ENUM` 的定义顺序有行为意义？
3. `ENUM` 的 index 和数据库索引有什么差别？
4. `ENUM('0','1','2')` 为什么容易造成误解？
5. `ORDER BY enum_col` 默认按什么排序？
6. 如果想按字符串字面值排序，应该怎么写？
7. 插入非法 `ENUM` 值时，strict mode 和非 strict mode 有什么差异？
8. 为什么不建议用空字符串作为状态枚举值？
9. `ENUM` 和 `SET` 最核心的差异是什么？
10. 什么时候应该用字典表替代 `ENUM`？
11. 如果状态需要多语言显示，为什么 `ENUM` 不合适？
12. 如果 Java enum 和数据库 `ENUM` 不同步，会有什么问题？

---

## 一句话抓核心

`ENUM` 是 MySQL 用来表达「小型、稳定、单选固定值」的特殊字符串类型；它的优点是约束清楚、存储紧凑，代价是定义顺序有行为意义，后续变更不如字典表灵活。

---

## 官方参考

- MySQL 8.4 Reference Manual：The ENUM Type  
  https://dev.mysql.com/doc/refman/8.4/en/enum.html
- MySQL 8.4 Reference Manual：Data Type Storage Requirements  
  https://dev.mysql.com/doc/refman/8.4/en/storage-requirements.html

---

## 返回导航

- [回到第十二章入口](./README.md)
- [上一节：7 文本字符串类型](./7%20文本字符串类型.md)
- [下一节：9 SET 类型](./9%20SET%20类型.md)
- [回到 README](../../README.md)

# 5 位类型：BIT

所属章节：[第十二章_MySQL 数据类型精讲](./README.md)

## 本节导读

这一篇要解决的问题是：

> `BIT` 到底适合存什么？`BIT(1)` 能不能当布尔值？`BIT(8)`、`BIT(16)`、`BIT(64)` 和普通整数有什么差别？为什么直接查询 `BIT` 字段时，有时结果看起来很奇怪？

在前面几篇中，我们已经学习了：

- 整数类型：适合保存普通整数、编号、数量、状态码。
- 浮点类型：适合保存允许近似误差的测量值、统计值、科学计算值。
- 定点数类型：适合保存金额、价格、余额、税率这类需要精确十进制表示的数值。

`BIT` 和这些类型都不完全一样。

`BIT` 的重点不是「普通整数」，而是：

```text
按位保存二进制值。
```

也就是说，`BIT(M)` 关心的是「这个值由几个 bit 组成」。

例如：

- `BIT(1)`：1 个二进制位。
- `BIT(5)`：5 个二进制位。
- `BIT(8)`：8 个二进制位。
- `BIT(64)`：64 个二进制位。

很多初学者会误解：

- `BIT(1)` 就等于 MySQL 的 `BOOLEAN`。
- `BIT(5)` 表示最多存 5 位十进制数字。
- `BIT` 比 `TINYINT` 更适合所有布尔字段。
- 多个状态塞进一个 `BIT` 字段一定更高级。
- `BIT` 字段查出来应该像普通整数一样直观显示。

这些理解都不够准确。

这一篇的重点不是让你到处使用 `BIT`，而是让你知道：

1. `BIT(M)` 的 `M` 到底表示什么。
2. `BIT` 能存什么值，不能存什么值。
3. 为什么查询 `BIT` 字段时经常要转换显示。
4. `BIT(1)`、`BOOLEAN`、`TINYINT(1)` 应该怎么区分。
5. 什么场景适合用 `BIT`，什么场景反而不建议用。

如果只能先记一句话：

> `BIT` 适合表达「位」本身；普通布尔值、业务状态码、经常查询的业务条件，通常用 `TINYINT` / `BOOLEAN` / 独立字段更直观。

---

## 关键词

- 主题：MySQL 位类型、BIT、位字段、位标志
- 英文：bit type、bit field、bit-value type、bitmask、flag、bitmap
- 常见搜索：
  - MySQL BIT 是什么
  - BIT(1) 和 BOOLEAN 区别
  - MySQL 怎么存布尔值
  - BIT 字段为什么显示乱码
  - BIT 字段怎么转成数字
  - BIT 字段怎么查询二进制
  - BIT 和 TINYINT 怎么选
  - MySQL 位运算怎么写
- 易混淆：
  - `BIT(1)` vs `BOOLEAN`
  - `BIT(1)` vs `TINYINT(1)`
  - 二进制位数 vs 十进制位数
  - 位标志 vs 状态码
  - 存储紧凑 vs 维护清晰
  - 直接查询原值 vs 转换成可读值

---

## 建议回查情境

遇到下面情况时，可以回到这一篇：

- 想确认 `BIT(1)`、`BIT(5)`、`BIT(8)`、`BIT(64)` 分别能存什么。
- 想知道 `BIT(M)` 的 `M` 是不是小数位、总位数或显示宽度。
- 想把多个开关状态压缩到一个字段里。
- 想判断布尔字段到底该用 `BIT(1)`、`BOOLEAN` 还是 `TINYINT(1)`。
- 查询 `BIT` 字段时看不懂结果，想知道怎么转成数字、二进制或十六进制。
- 想写类似 `flags & 1`、`flags | 2` 这种位运算条件。
- 想知道为什么把权限、状态、开关全部塞进一个字段可能会增加维护成本。

---

## 30 秒复习入口

- `BIT(M)` 用来存储 `M` 个二进制位。
- `M` 的范围是 `1 ~ 64`。
- 如果省略 `M`，`BIT` 默认等同于 `BIT(1)`。
- `BIT(1)` 只能表示 1 个 bit，也就是 `0` 或 `1`。
- `BIT(5)` 最多可表达二进制 `11111`，换成十进制是 `31`。
- `BIT(8)` 最多可表达二进制 `11111111`，换成十进制是 `255`。
- `BIT(M)` 的数值范围可以粗略理解为 `0 ~ 2^M - 1`。
- `BIT` 字面量可以写成 `b'101'` 或 `0b101`。
- 写入长度不足 `M` 的 bit 值时，MySQL 会在左侧补 `0`。
- `BIT` 字段直接查出来可能显示成二进制字符串或不可读字符，常要配合 `+ 0`、`CAST(... AS UNSIGNED)`、`BIN()`、`HEX()`、`LPAD()` 查看。
- `BIN()` 会去掉前导 `0`；如果要看完整位数，要用 `LPAD(BIN(col + 0), M, '0')`。
- `BOOLEAN` / `BOOL` 在 MySQL 中是 `TINYINT(1)` 的同义词，不是 `BIT(1)` 的同义词。
- 一般业务布尔字段，通常优先 `BOOLEAN` / `TINYINT(1)`，必要时加 `CHECK (col IN (0,1))`。
- 多个独立业务条件如果经常单独查询、统计、建索引，不建议全部压进一个 `BIT` 字段。
- `BIT` 更适合底层标志位、位掩码、协议字段、少量固定开关且访问方式明确的场景。

---

## 一、先讲结论

`BIT` 的核心用途是：

```text
保存固定长度的二进制位值。
```

它不是普通整数类型的默认替代品，也不是布尔类型的唯一选择。

### 1.1 最重要的判断原则

| 问题 | 如果答案是「是」 | 推荐方向 |
| --- | --- | --- |
| 只是普通数量、次数、年龄、编号？ | 是 | 用整数类型，如 `INT` / `BIGINT` |
| 只是普通业务布尔值？ | 是 | 优先 `BOOLEAN` / `TINYINT(1)` |
| 需要严格只有 `0` / `1`？ | 是 | `TINYINT(1)` + `CHECK (col IN (0,1))` |
| 一个字段要表达多个固定开关？ | 是 | 可考虑 `BIT(n)` 或整数 bitmask |
| 每个开关都要经常独立查询、筛选、统计？ | 是 | 优先拆成独立字段或关系表 |
| 权限项会经常增删？ | 是 | 优先权限表 / 角色权限表，不建议硬塞 bitmask |
| 来自底层协议、硬件、文件格式中的 bit 标志？ | 是 | `BIT(n)` 比较合理 |
| 需要强可读性、容易维护？ | 是 | 慎用 `BIT`，优先更直观的类型 |

### 1.2 一个简单选型流程

```text
这个字段要存的是数值吗？
  ├─ 不是：考虑 CHAR / VARCHAR / DATE / JSON 等类型
  └─ 是：继续问
        │
        ├─ 是否只是普通整数？
        │     └─ 是：优先 TINYINT / INT / BIGINT
        │
        ├─ 是否只是单个布尔语义？
        │     └─ 是：优先 BOOLEAN / TINYINT(1)
        │
        ├─ 是否需要把多个固定开关压到一个字段？
        │     └─ 是：可以考虑 BIT(n) 或整数 bitmask
        │
        ├─ 是否需要频繁按某个开关单独查询或建索引？
        │     └─ 是：不建议压成 BIT，优先独立字段
        │
        ├─ 是否是底层二进制协议、设备状态位、文件格式标志？
        │     └─ 是：BIT(n) 较合理
        │
        └─ 仍不确定：优先选择更可读、更容易维护的类型
```

### 1.3 常见业务字段选型速查

| 字段场景 | 推荐类型示例 | 说明 |
| --- | --- | --- |
| 是否启用 | `BOOLEAN` / `TINYINT(1)` | 语义直观，应用层好处理 |
| 是否删除 | `TINYINT(1)` | 软删除常见写法，可加 `CHECK` |
| 是否锁定 | `TINYINT(1)` | 比 `BIT(1)` 更容易调试 |
| 用户状态 | `TINYINT UNSIGNED` | 状态码不是 bit，通常不适合 `BIT` |
| 订单状态 | `TINYINT UNSIGNED` / 字典表 | 状态一般是互斥枚举，不是多个开关 |
| 性别代码 | `TINYINT` / `CHAR(1)` | 不适合用 `BIT` |
| 权限集合 | 角色权限表 | 权限会扩展时，不建议长期依赖 bitmask |
| 固定功能开关集合 | `BIT(8)` / `INT UNSIGNED` | 开关固定且低层使用时可考虑 |
| 设备状态位 | `BIT(16)` / `BIT(32)` | 若来源本来就是 bit flags，适合保留 |
| 协议标志字段 | `BIT(n)` | 适合表达协议层 bit 位 |
| 大量布尔列且极度关心空间 | `BIT(n)` | 但要评估可读性和查询成本 |

---

## 二、`BIT(M)` 是什么

`BIT` 是 MySQL 的位值类型，用来保存 bit values。

常见写法是：

```sql
BIT(M)
```

其中：

- `M` 表示位数；
- `M` 的范围是 `1 ~ 64`；
- 如果省略 `M`，默认是 `1`。

也就是说：

```sql
flag BIT;
```

基本可以理解成：

```sql
flag BIT(1);
```

### 2.1 `M` 是二进制位数，不是十进制位数

这是第一个容易误解的地方。

`BIT(5)` 不是最多存 5 位十进制数字。

它表示：

```text
这个字段保存 5 个二进制位。
```

所以：

```text
BIT(5) 最大二进制值：11111
BIT(5) 最大十进制值：31
```

因为：

```text
11111₂ = 31₁₀
```

### 2.2 `BIT(M)` 的可表达范围

可以用这个公式理解：

```text
BIT(M) 可表达范围：0 ~ 2^M - 1
```

常见例子：

| 类型 | 位数 | 最大二进制值 | 十进制范围 |
| --- | ---: | --- | ---: |
| `BIT(1)` | 1 | `1` | `0 ~ 1` |
| `BIT(2)` | 2 | `11` | `0 ~ 3` |
| `BIT(3)` | 3 | `111` | `0 ~ 7` |
| `BIT(4)` | 4 | `1111` | `0 ~ 15` |
| `BIT(5)` | 5 | `11111` | `0 ~ 31` |
| `BIT(8)` | 8 | `11111111` | `0 ~ 255` |
| `BIT(16)` | 16 | `16 个 1` | `0 ~ 65535` |
| `BIT(32)` | 32 | `32 个 1` | `0 ~ 4294967295` |
| `BIT(64)` | 64 | `64 个 1` | `0 ~ 18446744073709551615` |

注意：

`BIT(64)` 的最大值很大，已经超过 Java `long` 的正数上限。

所以如果后端要把 `BIT(64)` 当数值处理，要特别注意语言类型映射问题。

### 2.3 `BIT(M)` 的存储空间

从估算角度，可以这样理解：

```text
BIT(M) 大约需要 ceil(M / 8) 个字节。
```

也就是：

| 类型 | 估算字节数 |
| --- | ---: |
| `BIT(1)` | 1 byte |
| `BIT(5)` | 1 byte |
| `BIT(8)` | 1 byte |
| `BIT(9)` | 2 bytes |
| `BIT(16)` | 2 bytes |
| `BIT(32)` | 4 bytes |
| `BIT(64)` | 8 bytes |

不过这只是用于建模时的近似理解。

真正的磁盘占用还会受到：

- 存储引擎；
- 行格式；
- NULL bitmap；
- 对齐方式；
- 索引结构；
- 压缩方式；

等因素影响。

所以不要为了「理论上省几个 bit」就牺牲大量可读性。

---

## 三、`BIT` 字面量怎么写

写入 `BIT` 字段时，推荐使用位值字面量。

MySQL 支持两种常见写法：

```sql
b'101'
0b101
```

例如：

```sql
SELECT b'111' + 0;
```

结果可以理解为：

```text
7
```

因为：

```text
111₂ = 7₁₀
```

### 3.1 `b'...'` 写法

```sql
b'101'
B'101'
```

这两种写法都可以。

`b` 或 `B` 后面接的内容必须是二进制字符，也就是只能包含：

```text
0 或 1
```

下面是合法写法：

```sql
b'0'
b'1'
b'101'
B'000101'
```

下面是不合法写法：

```sql
b'102'
b'abc'
```

因为 `2`、`a`、`b`、`c` 都不是 bit literal 允许的二进制数字。

### 3.2 `0b...` 写法

```sql
0b101
```

这也是位值字面量。

注意：

```sql
0b101
```

可以；但下面这种不要写：

```sql
0B101
```

因为 `0b` 写法中的 `b` 对大小写比较敏感，建议统一写小写 `0b`。

### 3.3 位值不足长度时会左侧补 0

如果 `BIT(M)` 的字段长度是 6，但你写入的是 3 位：

```sql
b'101'
```

MySQL 会把它看成：

```text
b'000101'
```

也就是左侧补 0。

例如：

```sql
CREATE TABLE demo_bit_padding (
    flags BIT(6) NOT NULL
);

INSERT INTO demo_bit_padding (flags)
VALUES (b'101');

SELECT LPAD(BIN(flags + 0), 6, '0') AS flags_bin
FROM demo_bit_padding;
```

结果可以理解为：

```text
000101
```

这点非常重要。

因为 `BIT(6)` 关心的是固定 6 个 bit，而 `b'101'` 只是你写入时省略了左边的 0。

---

## 四、创建 `BIT` 字段

先看一个基础示例：

```sql
CREATE TABLE demo_bit (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    f1 BIT,
    f2 BIT(5),
    f3 BIT(8),
    f4 BIT(64)
);
```

可以这样理解：

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `f1` | `BIT` | 默认等同 `BIT(1)` |
| `f2` | `BIT(5)` | 5 个 bit |
| `f3` | `BIT(8)` | 8 个 bit |
| `f4` | `BIT(64)` | 64 个 bit |

### 4.1 插入 `BIT(1)`

```sql
INSERT INTO demo_bit (f1) VALUES (b'0');
INSERT INTO demo_bit (f1) VALUES (b'1');
```

这两种都合理。

但下面这个就不适合写入 `BIT(1)`：

```sql
INSERT INTO demo_bit (f1) VALUES (b'10');
```

因为 `b'10'` 需要 2 个 bit，而 `BIT(1)` 只有 1 个 bit。

如果写成数值：

```sql
INSERT INTO demo_bit (f1) VALUES (2);
```

也可以理解成超出了 `BIT(1)` 能表达的范围。

实务上，不要依赖数据库对这种超出长度或超出范围的隐式处理；应在应用层和数据库约束层提前限制。

### 4.2 插入 `BIT(5)`

```sql
INSERT INTO demo_bit (f2) VALUES (b'10111');
```

`b'10111'` 是 5 位，可以写入 `BIT(5)`。

它对应十进制：

```text
23
```

也可以写成：

```sql
INSERT INTO demo_bit (f2) VALUES (23);
```

但为了表达「我正在写 bit value」，在教学和低层字段中，`b'10111'` 通常更清楚。

下面这个不适合写入 `BIT(5)`：

```sql
INSERT INTO demo_bit (f2) VALUES (b'100000');
```

因为它需要 6 个 bit。

十进制角度就是：

```text
100000₂ = 32₁₀
```

而 `BIT(5)` 最大只能到：

```text
11111₂ = 31₁₀
```

### 4.3 插入 `BIT(8)`

```sql
INSERT INTO demo_bit (f3) VALUES (b'11111111');
```

这是 `BIT(8)` 的最大值。

对应十进制：

```text
255
```

如果写：

```sql
INSERT INTO demo_bit (f3) VALUES (b'1');
```

实际保存时可以理解成：

```text
00000001
```

因为不足 8 位时会左侧补 0。

---

## 五、为什么查询 `BIT` 字段时不直观

这是 `BIT` 最容易让人困惑的地方。

很多人以为：

```sql
SELECT f2 FROM demo_bit;
```

应该直接显示：

```text
23
```

但实际在不同客户端、不同驱动、不同显示环境中，可能会看到：

- 不可见字符；
- 类似二进制字符串的显示；
- 看起来像乱码；
- 被工具自动转成 `0` / `1`；
- 被驱动映射成 `byte[]`、`Boolean` 或其他形式。

原因是：

```text
BIT 字段本质上是 bit value，不是为了像普通整数那样直接展示。
```

所以查询时常需要显式转换。

---

## 六、如何把 `BIT` 查成可读结果

### 6.1 转成十进制数字：`+ 0`

最简单的方式是加 `0`，让它进入数值上下文：

```sql
SELECT f2 + 0 AS f2_num
FROM demo_bit;
```

如果 `f2` 是 `b'10111'`，结果就是：

```text
23
```

### 6.2 转成十进制数字：`CAST(... AS UNSIGNED)`

也可以写得更明确：

```sql
SELECT CAST(f2 AS UNSIGNED) AS f2_num
FROM demo_bit;
```

这种写法更适合正式 SQL，因为可读性比 `+ 0` 更好。

### 6.3 查看二进制：`BIN()`

```sql
SELECT BIN(f2 + 0) AS f2_bin
FROM demo_bit;
```

如果 `f2` 是 `b'10111'`，结果是：

```text
10111
```

注意：

`BIN()` 会去掉前导 `0`。

例如 `BIT(8)` 中保存的是：

```text
00000101
```

如果直接：

```sql
SELECT BIN(f3 + 0) AS f3_bin
FROM demo_bit;
```

结果可能只显示：

```text
101
```

这不代表左边的 0 没有保存，只是显示时被省略了。

### 6.4 查看固定长度二进制：`LPAD(BIN(...), M, '0')`

如果你想看完整的 `M` 位，应该这样写：

```sql
SELECT LPAD(BIN(f3 + 0), 8, '0') AS f3_bin
FROM demo_bit;
```

例如结果：

```text
00000101
```

这是查看 `BIT` 字段时非常实用的写法。

### 6.5 查看十六进制：`HEX()`

```sql
SELECT HEX(f3) AS f3_hex
FROM demo_bit;
```

或明确转成数值后：

```sql
SELECT HEX(f3 + 0) AS f3_hex
FROM demo_bit;
```

十六进制适合查看较长 bit 值，例如 `BIT(32)`、`BIT(64)`。

### 6.6 统计有几个 bit 为 1：`BIT_COUNT()`

如果你想知道一个 flags 字段中有几个开关被打开，可以使用：

```sql
SELECT BIT_COUNT(flags + 0) AS enabled_count
FROM user_feature_flags;
```

例如：

```text
flags = 00001101
```

其中有 3 个 `1`，表示 3 个开关开启。

---

## 七、`BIT`、`BOOLEAN`、`TINYINT(1)` 的区别

这是本篇最重要的实务判断。

### 7.1 MySQL 中的 `BOOLEAN` 是什么

在 MySQL 中：

```sql
BOOLEAN
BOOL
```

本质上是：

```sql
TINYINT(1)
```

也就是说，下面两个字段在语义上很接近：

```sql
is_enabled BOOLEAN
```

```sql
is_enabled TINYINT(1)
```

MySQL 中通常把：

```text
0        看成 false
非 0 值   看成 true
```

所以 `BOOLEAN` 不代表它只能存 `0` 或 `1`。

如果你想严格限制只能是 `0` 或 `1`，建议加约束：

```sql
is_enabled TINYINT(1) NOT NULL DEFAULT 1,
CONSTRAINT chk_is_enabled CHECK (is_enabled IN (0, 1))
```

### 7.2 `BIT(1)` 是什么

`BIT(1)` 是：

```text
一个 bit 的位字段。
```

它可以表示：

```text
0 或 1
```

从表达范围看，确实很像布尔值。

但从类型语义和工具兼容性看，它和 `BOOLEAN` / `TINYINT(1)` 不完全一样。

| 类型 | 本质 | 常见用途 | 可读性 | 应用层处理 |
| --- | --- | --- | --- | --- |
| `BOOLEAN` | `TINYINT(1)` 同义词 | 普通布尔语义 | 高 | 通常较方便 |
| `TINYINT(1)` | 1 byte 小整数 | 布尔、状态、标记 | 高 | 最常见 |
| `BIT(1)` | 1 个 bit | 位字段、底层标志 | 中低 | 可能需要转换 |

### 7.3 实务建议

普通业务布尔字段，建议优先写：

```sql
is_deleted TINYINT(1) NOT NULL DEFAULT 0,
CONSTRAINT chk_is_deleted CHECK (is_deleted IN (0, 1))
```

或：

```sql
is_deleted BOOLEAN NOT NULL DEFAULT FALSE
```

如果团队规范明确使用 `TINYINT(1)`，就遵守团队规范。

不建议为了「看起来更像布尔」就默认使用：

```sql
is_deleted BIT(1)
```

因为它可能带来：

- 查询显示不直观；
- ORM 映射差异；
- JDBC / MyBatis 类型处理额外配置；
- SQL 调试成本增加；
- 维护者误以为它就是普通布尔字段。

### 7.4 什么时候 `BIT(1)` 可以接受

下面场景可以考虑 `BIT(1)`：

- 字段来自底层协议，本来就是 1 个 bit。
- 大量记录中有极多固定 bit 标志，确实关心空间。
- 团队已经统一封装了类型映射和查询显示方式。
- 该字段不会频繁被业务人员直接查询或调试。

否则，普通业务系统中 `TINYINT(1)` 通常更直观。

---

## 八、`BIT(n)` 和位标志 flags

`BIT(n)` 比较有价值的场景是：

```text
一个字段表示多个开关。
```

例如：

```text
第 0 位：是否允许登录
第 1 位：是否开启通知
第 2 位：是否启用双因素认证
第 3 位：是否显示新手引导
```

可以用一个 `BIT(8)` 保存。

### 8.1 示例：功能开关字段

```sql
CREATE TABLE user_feature_flags (
    user_id BIGINT UNSIGNED PRIMARY KEY,
    flags BIT(8) NOT NULL DEFAULT b'00000000'
);
```

假设我们定义：

| 位 | 十进制掩码 | 二进制 | 含义 |
| ---: | ---: | --- | --- |
| bit 0 | 1 | `00000001` | 允许登录 |
| bit 1 | 2 | `00000010` | 开启通知 |
| bit 2 | 4 | `00000100` | 启用双因素认证 |
| bit 3 | 8 | `00001000` | 显示新手引导 |

注意：

这里采用的是「从右往左」数 bit 的常见习惯。

也就是：

```text
00000001 代表第 0 位
00000010 代表第 1 位
00000100 代表第 2 位
00001000 代表第 3 位
```

### 8.2 判断某个开关是否开启

判断 bit 0 是否开启：

```sql
SELECT user_id
FROM user_feature_flags
WHERE (flags + 0) & 1 <> 0;
```

判断 bit 2 是否开启：

```sql
SELECT user_id
FROM user_feature_flags
WHERE (flags + 0) & 4 <> 0;
```

其中：

```text
4 = 00000100₂
```

### 8.3 开启某个开关

开启 bit 1：

```sql
UPDATE user_feature_flags
SET flags = (flags + 0) | 2
WHERE user_id = 1001;
```

解释：

```text
| 是按位 OR
某一位只要其中一边是 1，结果就是 1
```

所以用 OR 可以把某个 bit 打开。

### 8.4 关闭某个开关

关闭 bit 1：

```sql
UPDATE user_feature_flags
SET flags = (flags + 0) & ~2
WHERE user_id = 1001;
```

解释：

```text
& 是按位 AND
~2 会把 bit 1 变成 0，其它位变成 1
再用 AND，就可以把 bit 1 清掉
```

为了避免 `~` 在不同数值宽度下造成理解成本，实务上也可以在应用层先算好掩码，再传入 SQL。

### 8.5 切换某个开关

切换 bit 1：

```sql
UPDATE user_feature_flags
SET flags = (flags + 0) ^ 2
WHERE user_id = 1001;
```

解释：

```text
^ 是按位 XOR
相同为 0，不同为 1
```

所以可以用 XOR 实现开关切换。

### 8.6 查看完整 flags

```sql
SELECT
    user_id,
    LPAD(BIN(flags + 0), 8, '0') AS flags_bin,
    flags + 0 AS flags_num
FROM user_feature_flags;
```

示例结果：

```text
+---------+-----------+-----------+
| user_id | flags_bin | flags_num |
+---------+-----------+-----------+
|    1001 | 00000101  |         5 |
+---------+-----------+-----------+
```

含义是：

```text
00000101 = bit 0 和 bit 2 开启
```

---

## 九、不要滥用 `BIT` 的原因

虽然 `BIT` 可以把多个状态压在一个字段里，但这不代表它永远更好。

数据库设计不是只看「能不能存」，还要看：

- 查询是否清楚；
- 索引是否好用；
- 团队是否容易维护；
- 业务是否会扩展；
- 后端、前端、报表系统是否容易理解。

### 9.1 可读性问题

下面这种字段：

```sql
flags BIT(8)
```

单独看表结构时，你不知道每一位是什么意思。

必须额外查文档：

```text
bit 0 是什么？
bit 1 是什么？
bit 2 是什么？
bit 3 是什么？
```

如果文档没有维护好，后面的人会很痛苦。

相比之下，下面这种虽然占更多字段，但语义更清楚：

```sql
allow_login TINYINT(1) NOT NULL DEFAULT 1,
notification_enabled TINYINT(1) NOT NULL DEFAULT 1,
two_factor_enabled TINYINT(1) NOT NULL DEFAULT 0,
onboarding_visible TINYINT(1) NOT NULL DEFAULT 1
```

### 9.2 查询条件不直观

用独立字段查询：

```sql
WHERE two_factor_enabled = 1
```

用 bit flags 查询：

```sql
WHERE (flags + 0) & 4 <> 0
```

第二种需要知道：

```text
4 代表第 2 位
第 2 位代表 two_factor_enabled
```

这增加了认知成本。

### 9.3 索引不友好

如果你经常按某个开关查询，例如：

```sql
WHERE two_factor_enabled = 1
```

独立字段可以直接建索引：

```sql
CREATE INDEX idx_two_factor_enabled
ON user_account(two_factor_enabled);
```

但如果条件写成：

```sql
WHERE (flags + 0) & 4 <> 0
```

这种表达式通常不像普通列等值条件那样直观地利用普通索引。

如果这个条件是高频查询条件，通常不建议塞进 `BIT` 字段。

### 9.4 扩展性问题

如果一开始定义：

```text
BIT(8)
```

后来业务开关越来越多，可能会出现：

- bit 位不够；
- 文档变复杂；
- 不同版本含义不一致；
- 历史数据解释困难；
- 多系统同步成本增加。

这时还不如一开始就用更清晰的设计。

### 9.5 权限系统不建议只靠 bitmask

很多人会想：

```text
权限很多，用 bitmask 很省空间。
```

但实际业务权限通常会变化：

- 新增权限；
- 删除权限；
- 权限分组；
- 角色继承；
- 菜单权限；
- API 权限；
- 数据权限；
- 机构权限；
- 多租户权限。

这类场景更适合：

```text
用户表
角色表
权限表
用户角色关联表
角色权限关联表
```

例如：

```sql
user_role(user_id, role_id)
role_permission(role_id, permission_code)
```

除非你的权限集合非常固定，而且只是底层高性能判断，否则不建议长期依赖 `BIT` 字段表达复杂权限系统。

---

## 十、`BIT` 和整数 bitmask 怎么选

有时你会遇到两种方案：

方案 A：

```sql
flags BIT(8)
```

方案 B：

```sql
flags TINYINT UNSIGNED
```

它们都可以表达 8 个 bit。

那应该怎么选？

### 10.1 对比表

| 方案 | 优点 | 缺点 | 适合场景 |
| --- | --- | --- | --- |
| `BIT(n)` | 类型语义明确表示 bit | 显示、驱动映射可能较麻烦 | 底层位字段、协议字段 |
| `TINYINT UNSIGNED` | 查询、显示、应用层处理直观 | 类型本身看不出 bit 长度语义 | 普通 bitmask、业务 flags |
| `INT UNSIGNED` | 位运算方便，可表达 32 位 | 需要文档说明每一位含义 | 常见 flags 设计 |
| `BIGINT UNSIGNED` | 可表达 64 位 | 后端语言类型要注意 | 大量固定 flags |
| 多个 `TINYINT(1)` | 可读性最好，易建索引 | 字段数量较多 | 业务开关、常查条件 |
| 关联表 | 扩展性最好 | 查询结构较多 | 权限、标签、多选关系 |

### 10.2 实务判断

如果你真的在表达底层 bit value：

```sql
protocol_flags BIT(16)
```

是合理的。

如果你只是想在业务系统中保存几个固定开关，下面这种也常见：

```sql
feature_flags INT UNSIGNED NOT NULL DEFAULT 0
```

因为它在应用层、SQL 调试、ORM 映射上往往更简单。

如果这些开关会经常被单独查询、统计或排序，建议拆成独立字段。

---

## 十一、完整建表示例

下面给出一个比较实务的示例。

假设我们有一张设备状态表，设备上报的是一个 16 位状态字。

这个状态字来自硬件协议，每一位都有固定含义。

这种场景使用 `BIT(16)` 是合理的。

```sql
CREATE TABLE device_status_report (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键 ID',
    device_id BIGINT UNSIGNED NOT NULL COMMENT '设备 ID',
    status_bits BIT(16) NOT NULL COMMENT '设备上报的 16 位状态字',
    reported_at DATETIME NOT NULL COMMENT '上报时间',

    INDEX idx_device_reported_at (device_id, reported_at)
);
```

查询时不要直接看 `status_bits`，而是转成可读格式：

```sql
SELECT
    id,
    device_id,
    LPAD(BIN(status_bits + 0), 16, '0') AS status_bits_bin,
    HEX(status_bits) AS status_bits_hex,
    status_bits + 0 AS status_bits_num,
    reported_at
FROM device_status_report
WHERE device_id = 1001
ORDER BY reported_at DESC;
```

如果第 3 位代表「温度异常」，则可以这样查：

```sql
SELECT
    id,
    device_id,
    reported_at
FROM device_status_report
WHERE (status_bits + 0) & 8 <> 0;
```

因为：

```text
8 = 0000000000001000₂
```

### 11.1 如果是普通业务开关，不一定要用 `BIT`

例如用户设置：

```text
是否接收邮件通知
是否接收短信通知
是否开启深色模式
是否显示新手引导
```

如果这些字段会被后台、报表、运营人员经常查看，下面这种反而更清楚：

```sql
CREATE TABLE user_settings (
    user_id BIGINT UNSIGNED PRIMARY KEY,
    email_notify_enabled TINYINT(1) NOT NULL DEFAULT 1,
    sms_notify_enabled TINYINT(1) NOT NULL DEFAULT 0,
    dark_mode_enabled TINYINT(1) NOT NULL DEFAULT 0,
    onboarding_visible TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chk_email_notify_enabled CHECK (email_notify_enabled IN (0, 1)),
    CONSTRAINT chk_sms_notify_enabled CHECK (sms_notify_enabled IN (0, 1)),
    CONSTRAINT chk_dark_mode_enabled CHECK (dark_mode_enabled IN (0, 1)),
    CONSTRAINT chk_onboarding_visible CHECK (onboarding_visible IN (0, 1))
);
```

这虽然字段多一点，但可读性和维护性更好。

---

## 十二、和 Java / MyBatis 的关系

如果你用 Java、JDBC、MyBatis 处理 MySQL `BIT` 字段，要特别小心类型映射。

不同驱动、不同配置、不同字段长度下，`BIT` 可能被处理成：

- `Boolean`；
- `Byte`；
- `byte[]`；
- `Integer`；
- `Long`；
- 需要自定义 TypeHandler。

尤其是：

```sql
BIT(1)
```

有些场景可能会被当成布尔值处理。

而：

```sql
BIT(8)
BIT(16)
BIT(64)
```

就不一定能直接用普通 Java 类型自然接收。

### 12.1 Java 中的实务建议

如果只是业务布尔值：

```sql
is_enabled TINYINT(1) NOT NULL DEFAULT 1
```

Java 中可以对应：

```java
private Boolean enabled;
```

或：

```java
private Integer enabled;
```

如果是 flags：

```sql
feature_flags INT UNSIGNED NOT NULL DEFAULT 0
```

Java 中可以对应：

```java
private Integer featureFlags;
```

或在值域较大时使用：

```java
private Long featureFlags;
```

如果数据库字段一定是：

```sql
status_bits BIT(16)
```

建议在 MyBatis 中明确处理：

- 查询时用 `status_bits + 0 AS status_bits_num`；
- 或使用 `CAST(status_bits AS UNSIGNED)`；
- 或自定义 TypeHandler；
- 不要让团队成员猜驱动会怎么映射。

例如：

```sql
SELECT
    id,
    device_id,
    CAST(status_bits AS UNSIGNED) AS status_bits
FROM device_status_report;
```

这样后端接收会更直观。

---

## 十三、常见错误写法与修正

### 13.1 错误：把 `BIT(1)` 当作所有布尔字段默认选择

不建议：

```sql
is_deleted BIT(1) NOT NULL DEFAULT b'0'
```

更常见：

```sql
is_deleted TINYINT(1) NOT NULL DEFAULT 0,
CONSTRAINT chk_is_deleted CHECK (is_deleted IN (0, 1))
```

原因：

- `TINYINT(1)` 更直观；
- 应用层映射更稳定；
- SQL 查询更容易读；
- 报表工具更容易处理。

### 13.2 错误：用 `BIT` 保存互斥状态

不建议：

```sql
order_status BIT(3)
```

如果订单状态是：

```text
0 待付款
1 已付款
2 已出货
3 已完成
4 已取消
```

这不是多个可以同时开启的开关，而是互斥状态码。

更建议：

```sql
order_status TINYINT UNSIGNED NOT NULL,
CONSTRAINT chk_order_status CHECK (order_status IN (0, 1, 2, 3, 4))
```

### 13.3 错误：用 `BIT` 保存会频繁扩展的权限

不建议：

```sql
permissions BIT(64)
```

如果权限体系会增长、分组、授权、回收、审计，建议拆表：

```sql
role_permission (
    role_id BIGINT UNSIGNED NOT NULL,
    permission_code VARCHAR(100) NOT NULL,
    PRIMARY KEY (role_id, permission_code)
);
```

### 13.4 错误：直接查询 `BIT` 字段给人看

不建议：

```sql
SELECT flags FROM user_feature_flags;
```

更建议：

```sql
SELECT
    LPAD(BIN(flags + 0), 8, '0') AS flags_bin,
    flags + 0 AS flags_num
FROM user_feature_flags;
```

### 13.5 错误：没有文档说明每一位含义

不建议只写：

```sql
flags BIT(8) NOT NULL
```

至少要在注释、文档或代码常量中说明：

```sql
flags BIT(8) NOT NULL COMMENT 'bit0=允许登录, bit1=通知开启, bit2=双因素认证, bit3=显示引导'
```

应用层也要有常量：

```java
public final class UserFeatureFlags {
    public static final int ALLOW_LOGIN = 1 << 0;
    public static final int NOTIFICATION_ENABLED = 1 << 1;
    public static final int TWO_FACTOR_ENABLED = 1 << 2;
    public static final int ONBOARDING_VISIBLE = 1 << 3;
}
```

---

## 十四、常见混淆点

### 14.1 `BIT(5)` 不是 5 位十进制数

`BIT(5)` 是 5 个二进制位。

它最大是：

```text
11111₂ = 31₁₀
```

不是：

```text
99999
```

### 14.2 `BIT` 默认是 `BIT(1)`

```sql
flag BIT
```

等同于：

```sql
flag BIT(1)
```

### 14.3 `BIT(1)` 不等于 `BOOLEAN`

从值域看，两者都可以表达 `0` / `1`。

但 MySQL 中：

```sql
BOOLEAN = TINYINT(1)
```

不是：

```sql
BOOLEAN = BIT(1)
```

### 14.4 `BOOLEAN` 不一定只允许 `0` 和 `1`

MySQL 中非 0 通常都可以被当成 true。

如果想严格限制布尔值，应加：

```sql
CHECK (col IN (0, 1))
```

### 14.5 `BIT` 查询显示可能不直观

直接：

```sql
SELECT flags FROM table_name;
```

不一定是你期待的显示。

建议：

```sql
SELECT flags + 0;
SELECT CAST(flags AS UNSIGNED);
SELECT LPAD(BIN(flags + 0), 8, '0');
SELECT HEX(flags);
```

### 14.6 `BIN()` 会丢掉前导 0

如果字段是 `BIT(8)`，实际值是：

```text
00000101
```

`BIN()` 可能显示：

```text
101
```

所以要看完整长度时，使用：

```sql
LPAD(BIN(flags + 0), 8, '0')
```

### 14.7 位标志不适合表达所有业务状态

如果多个状态互斥，例如订单状态、审核状态、流程状态，通常不适合用 bit flags。

bit flags 更适合多个条件可以同时成立的场景。

---

## 十五、练习示例

### 15.1 建表

```sql
CREATE TABLE demo_user_flags (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    flags BIT(8) NOT NULL DEFAULT b'00000000'
);
```

### 15.2 插入数据

```sql
INSERT INTO demo_user_flags (username, flags)
VALUES
    ('alice', b'00000001'),
    ('bob',   b'00000101'),
    ('cindy', b'00000000');
```

### 15.3 查询可读结果

```sql
SELECT
    id,
    username,
    LPAD(BIN(flags + 0), 8, '0') AS flags_bin,
    flags + 0 AS flags_num
FROM demo_user_flags;
```

结果可以理解为：

```text
+----+----------+-----------+-----------+
| id | username | flags_bin | flags_num |
+----+----------+-----------+-----------+
|  1 | alice    | 00000001  |         1 |
|  2 | bob      | 00000101  |         5 |
|  3 | cindy    | 00000000  |         0 |
+----+----------+-----------+-----------+
```

### 15.4 查询 bit 0 开启的人

```sql
SELECT username
FROM demo_user_flags
WHERE (flags + 0) & 1 <> 0;
```

结果：

```text
alice
bob
```

### 15.5 查询 bit 2 开启的人

```sql
SELECT username
FROM demo_user_flags
WHERE (flags + 0) & 4 <> 0;
```

结果：

```text
bob
```

### 15.6 开启 bit 1

```sql
UPDATE demo_user_flags
SET flags = (flags + 0) | 2
WHERE username = 'cindy';
```

查询：

```sql
SELECT
    username,
    LPAD(BIN(flags + 0), 8, '0') AS flags_bin
FROM demo_user_flags
WHERE username = 'cindy';
```

结果可以理解为：

```text
00000010
```

---

## 十六、自测问题

1. `BIT(5)` 最多可以表示到十进制多少？为什么？
2. `BIT` 不写长度时，默认等同于什么？
3. `BIT(8)` 中写入 `b'101'` 后，完整 8 位应该怎么理解？
4. 为什么 `BIN(flags + 0)` 可能看不到前导 `0`？
5. 如果想显示完整 8 位二进制，SQL 应该怎么写？
6. `BOOLEAN` / `BOOL` 在 MySQL 中本质上是什么类型？
7. 为什么普通业务布尔字段通常不优先使用 `BIT(1)`？
8. `BIT(n)` 比较适合什么场景？
9. 为什么订单状态不适合用 `BIT` 表达？
10. 如果一个字段需要经常按某个开关查询并建立索引，应该优先考虑 `BIT` 还是独立字段？

---

## 十七、面试与实务回答模板

### 17.1 面试题：`BIT(1)` 和 `TINYINT(1)` 有什么区别？

可以这样回答：

> `BIT(1)` 是位类型，表示 1 个二进制位；`TINYINT(1)` 是小整数类型，其中 `(1)` 是旧式显示宽度概念，不限制取值范围。MySQL 中 `BOOLEAN` / `BOOL` 实际上是 `TINYINT(1)` 的同义词，而不是 `BIT(1)`。实务上，普通布尔字段通常使用 `TINYINT(1)` 或 `BOOLEAN` 更直观；`BIT(1)` 更偏底层位字段，查询显示和应用层映射可能需要额外处理。

### 17.2 面试题：`BIT(5)` 能存多大？

可以这样回答：

> `BIT(5)` 表示 5 个二进制位，不是 5 位十进制数。它的最大二进制值是 `11111`，对应十进制 `31`，所以可以理解为范围是 `0 ~ 31`。

### 17.3 面试题：为什么不建议滥用 bitmask？

可以这样回答：

> bitmask 可以节省空间，也适合表达底层固定标志位。但它牺牲了可读性，查询条件不直观，单个位上的查询和索引也不如独立字段清楚。如果业务条件经常单独筛选、统计、扩展，通常应该拆成独立字段或关联表，而不是全部塞进一个 flags 字段。

---

## 十八、本节总结

`BIT` 是 MySQL 中比较特殊的一类数据类型。

它的关键不是：

```text
能不能存 0 和 1。
```

而是：

```text
能不能用固定长度的 bit 来表达底层标志或位集合。
```

你可以这样记：

| 场景 | 推荐方向 |
| --- | --- |
| 普通布尔值 | `BOOLEAN` / `TINYINT(1)` |
| 需要严格 0/1 | `TINYINT(1)` + `CHECK` |
| 普通状态码 | `TINYINT` / `SMALLINT` / 字典表 |
| 互斥流程状态 | 状态码，不用 bit flags |
| 多个固定底层开关 | 可考虑 `BIT(n)` |
| 经常按单个开关查询 | 独立字段更清楚 |
| 权限体系 | 角色权限表更可维护 |
| 协议、设备、文件格式 bit 字段 | `BIT(n)` 合理 |

最终原则是：

> 只有当你真的在表达「位」时，`BIT` 才值得优先考虑；如果只是业务布尔值或状态码，选择更直观、更好维护的类型通常更好。

---

## 一句话抓核心

`BIT` 的价值不在于「也能存 0 和 1」，而在于「用固定长度的二进制位表达底层标志」；普通业务布尔值和状态码，通常不要为了省空间而牺牲可读性。

---

## 返回导航

- [回到第十二章入口](./README.md)
- [上一节：4 定点数类型](./4%20定点数类型.md)
- [下一节：6 日期与时间类型](./6%20日期与时间类型.md)
- [回到 README](../../README.md)

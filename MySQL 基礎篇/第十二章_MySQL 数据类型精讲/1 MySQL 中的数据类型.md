# 1 MySQL 中的数据类型

所属章节：[第十二章_MySQL 数据类型精讲](./README.md)

## 本节导读

这一篇是第十二章的数据类型总览页，目标不是把每一种类型的细节一次背完，而是先建立一张「建表前的字段选型地图」。

学习 MySQL 数据类型时，真正要解决的不是「MySQL 有哪些类型」而已，而是：

> 当你准备定义一列字段时，能不能根据这列资料的业务含义、范围、精度、长度、查询方式与未来维护成本，选出相对合适的数据类型与字段属性。

所以这一页会先帮你整理三件事：

1. MySQL 常见数据类型可以分成哪些大类。
2. 每一类适合描述什么样的业务资料。
3. 定义字段时，除了类型本身，还要搭配哪些列属性与约束。

读完这一篇后，你不一定要马上记住所有类型的细节，但至少要能做到：看到一个字段需求时，先判断它应该往「数值、日期时间、字符串、二进制、JSON、空间数据」哪一类去想。

---

## 关键词

- 主题：MySQL 数据类型、字段类型、列类型、字段选型
- 英文：data type、column type、column attribute、constraint
- 常见搜索：MySQL 有哪些数据类型、MySQL 字段类型怎么分、MySQL 建表字段怎么选
- 易混淆：
  - 字段类型 vs 字段属性
  - 精确数值 vs 近似数值
  - 文本字符串 vs 二进制字符串
  - `NULL` vs 空字符串 `''` vs 数字 `0`
  - `VARCHAR` vs `TEXT`
  - `DATETIME` vs `TIMESTAMP`

---

## 建议回查情境

遇到下面情况时，可以优先回到这一页：

- 建表前不知道某个字段应该用哪一类数据类型。
- 忘记 `INT`、`DECIMAL`、`VARCHAR`、`TEXT`、`BLOB`、`JSON` 分别属于哪一类。
- 想快速确认字段定义时常见的 `NOT NULL`、`DEFAULT`、`PRIMARY KEY`、`AUTO_INCREMENT`、`UNSIGNED`、`CHARACTER SET`、`COLLATE` 是什么角色。
- 想先建立整体地图，再进入整数、浮点、定点数、日期时间、字符串、二进制、JSON、空间类型等细节。
- 看到旧系统建表语句很长，想拆解「类型、长度、是否为空、默认值、约束、字符集」各自的意义。

---

## 30 秒复习入口

- MySQL 数据类型可以先粗分为：数值类型、日期时间类型、字符串类型、JSON 类型、空间数据类型。
- 数值类型里面又可以拆成：整数、定点数、浮点数、位类型。
- 字符串类型里面又可以拆成：普通文本字符串、二进制字符串、枚举 `ENUM`、集合 `SET`。
- 选类型时不要只看「能不能存」，还要看：语义是否正确、范围是否足够、精度是否可靠、长度是否合理、查询是否方便、未来是否容易维护。
- 字段定义通常不是只有类型，还会搭配 `NOT NULL`、`DEFAULT`、`PRIMARY KEY`、`AUTO_INCREMENT`、`UNSIGNED`、`CHARACTER SET`、`COLLATE`、`COMMENT` 等属性或约束。

---

## 一、先建立整体分类地图

MySQL 的数据类型可以先从「资料本质」来分。

| 大类 | 代表类型 | 适合存什么 | 后续重点 |
| --- | --- | --- | --- |
| 整数类型 | `TINYINT`、`SMALLINT`、`MEDIUMINT`、`INT`、`BIGINT` | 编号、数量、年龄、状态码、次数 | 范围、是否 `UNSIGNED`、是否自增 |
| 定点数类型 | `DECIMAL` / `NUMERIC` | 金额、余额、税率、需要十进制精确计算的数值 | `M` 与 `D`、精确性 |
| 浮点类型 | `FLOAT`、`DOUBLE` | 测量值、统计值、科学计算、允许近似误差的小数 | 近似值、精度误差 |
| 位类型 | `BIT` | 位标记、二进制状态、权限压缩 | 位数、显示方式、可读性 |
| 日期时间类型 | `YEAR`、`DATE`、`TIME`、`DATETIME`、`TIMESTAMP` | 年份、日期、时间、业务时间、系统记录时间 | 时间语义、时区、自动更新时间 |
| 普通字符串类型 | `CHAR`、`VARCHAR`、`TINYTEXT`、`TEXT`、`MEDIUMTEXT`、`LONGTEXT` | 名称、邮箱、标题、地址、文章正文 | 固定长度、可变长度、索引、字符集 |
| 二进制字符串类型 | `BINARY`、`VARBINARY`、`TINYBLOB`、`BLOB`、`MEDIUMBLOB`、`LONGBLOB` | 原始 bytes、图片、文件、加密结果、Hash 值 | 是否需要字符集、是否适合放数据库 |
| 枚举类型 | `ENUM` | 稳定的小型单选集合 | 候选值固定、排序与维护成本 |
| 集合类型 | `SET` | 稳定的小型多选集合 | 多选、位标记、规范化取舍 |
| JSON 类型 | `JSON` | 半结构化资料、扩展属性、外部接口原始资料 | 验证、查询、索引、结构是否稳定 |
| 空间数据类型 | `GEOMETRY`、`POINT`、`LINESTRING`、`POLYGON` 等 | 地理位置、线段、区域、多边形 | SRID、空间函数、空间索引 |

### 这一页最重要的理解

数据类型不是为了「把资料塞进去」而已，而是为了让数据库知道：

- 这份资料是什么语义；
- 这份资料怎么存比较合理；
- 这份资料未来能不能正确比较、排序、计算、索引与维护。

例如：

| 需求 | 不建议的想法 | 较合理的方向 |
| --- | --- | --- |
| 金额 199.99 | 用 `DOUBLE`，因为它可以存小数 | 用 `DECIMAL`，因为金额需要十进制精确性 |
| 生日 1998-09-25 | 用 `VARCHAR(20)`，因为看起来像文字 | 用 `DATE`，因为它是日期语义 |
| 是否启用 | 用 `VARCHAR('Y'/'N')` 随便存 | 可用 `TINYINT`、`BOOLEAN` 语义，或稳定时用枚举策略 |
| 文章内容 | 用很大的 `VARCHAR` | 用 `TEXT` 系列，并注意索引与查询方式 |
| 上传图片 | 直接塞 `TEXT` | 若存原始 bytes 用 `BLOB`；实际项目常考虑对象存储 + URL |

---

## 二、字段定义不是只有「类型」

建表时常看到这种字段定义：

```sql
id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID'
```

这句话其实可以拆成几个层次：

| 部分 | 例子 | 作用 |
| --- | --- | --- |
| 字段名 | `id` | 这一列的名称 |
| 数据类型 | `BIGINT` | 这一列存什么类型的资料 |
| 类型属性 | `UNSIGNED` | 改变类型的取值范围或行为 |
| 是否允许空值 | `NOT NULL` | 是否必须有值 |
| 自动生成 | `AUTO_INCREMENT` | 插入资料时自动递增 |
| 约束 | `PRIMARY KEY` | 主键，要求唯一且不可为空 |
| 注释 | `COMMENT '用户ID'` | 给字段加说明，方便维护 |

所以读建表语句时，不要只看 `BIGINT`，还要一起看它后面搭配了什么。

---

## 三、常见字段属性与约束速查

| 关键字 | 角色 | 说明 | 常见场景 |
| --- | --- | --- | --- |
| `NULL` | 空值控制 | 允许这一列没有值 | 选填栏位、尚未产生的资料 |
| `NOT NULL` | 空值控制 | 不允许为空 | 必填栏位、核心业务字段 |
| `DEFAULT` | 默认值 | 插入时未指定值就使用默认值 | 状态、计数、创建时间 |
| `PRIMARY KEY` | 约束 | 主键，唯一识别一笔资料 | `id`、业务唯一键的一部分 |
| `UNIQUE` | 约束 | 不允许重复 | 邮箱、账号、身份证号、唯一编号 |
| `AUTO_INCREMENT` | 自动递增 | 通常用于整数主键 | 自增 ID |
| `UNSIGNED` | 数值属性 | 无符号，不允许负数，扩大正数范围 | ID、数量、库存、次数 |
| `CHARACTER SET` | 字符属性 | 指定字符集 | 字符串字段或表级设定 |
| `COLLATE` | 字符属性 | 指定排序与比较规则 | 是否区分大小写、排序规则 |
| `ON UPDATE CURRENT_TIMESTAMP` | 自动更新 | 行更新时自动刷新时间 | `updated_at` |
| `COMMENT` | 说明 | 字段注释 | 提升可维护性 |

### 字段属性的思考顺序

定义字段时可以按这个顺序问自己：

1. 这列资料本质是什么？数值、日期、文字、二进制、JSON、空间数据？
2. 这列是否一定要有值？要不要 `NOT NULL`？
3. 没传值时是否有合理默认值？要不要 `DEFAULT`？
4. 这列是否唯一？要不要 `PRIMARY KEY` 或 `UNIQUE`？
5. 这列是否会参与查询、排序、范围筛选或关联？类型会不会影响索引效率？
6. 这列未来是否可能扩充？如果会频繁变动，是否不适合用 `ENUM` / `SET`？

---

## 四、字段选型的核心判断流程

可以把字段选型想成下面这条路线。

### 第一步：先判断资料语义

| 资料语义 | 优先思考方向 |
| --- | --- |
| 编号、次数、数量、状态码 | 整数类型 |
| 金额、价格、税额、余额 | `DECIMAL` |
| 测量值、科学计算、统计近似值 | `FLOAT` / `DOUBLE` |
| 生日、交易日、有效期限 | `DATE` / `DATETIME` |
| 创建时间、更新时间、日志时间 | `DATETIME` / `TIMESTAMP` |
| 名称、标题、邮箱、手机号 | `VARCHAR` / `CHAR` |
| 文章、备注、长说明 | `TEXT` 系列 |
| 图片、文件、原始 bytes | `BLOB` 系列或外部存储 |
| 固定单选状态 | `ENUM` 或普通类型 + 字典表 |
| 固定多选标签 | `SET` 或关联表 |
| 弹性扩展属性 | `JSON` 或拆表设计 |
| 经纬度、区域、路径 | 空间数据类型 |

### 第二步：再判断范围、精度与长度

| 问题 | 对应影响 |
| --- | --- |
| 最大值可能到多少？ | 决定 `TINYINT`、`INT`、`BIGINT` 等范围 |
| 会不会出现负数？ | 决定是否使用 `UNSIGNED` |
| 小数是否必须精确？ | 决定用 `DECIMAL` 还是 `DOUBLE` |
| 字符长度是否固定？ | 决定用 `CHAR` 还是 `VARCHAR` |
| 文字会不会很长？ | 决定是否改用 `TEXT` 系列 |
| 是否需要按内容查询？ | 影响普通索引、前缀索引、全文索引或拆字段 |
| 结构是否稳定？ | 决定 JSON / ENUM / SET 是否合适 |

### 第三步：最后考虑维护性

类型选型不只影响现在，也会影响未来维护：

- 太小的整数类型，未来可能溢出。
- 金额使用浮点数，未来可能出现精度误差。
- 所有短文字都用 `TEXT`，会让索引、默认值、查询习惯变复杂。
- 状态值如果经常新增，用 `ENUM` 可能导致修改表结构频繁。
- 所有扩展资料都塞进 `JSON`，会让查询、约束、索引与报表统计变困难。

---

## 五、常见业务字段选型速查

| 字段 | 常见写法 | 说明 |
| --- | --- | --- |
| 自增主键 | `BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY` | 适合资料量可能成长的表 |
| 用户名 | `VARCHAR(50) NOT NULL` | 长度依业务限制，不要无脑设很大 |
| 邮箱 | `VARCHAR(255) NOT NULL UNIQUE` | 邮箱长度可放宽，但仍应有业务校验 |
| 手机号 | `VARCHAR(20)` | 电话号码不是拿来计算的数字，通常用字符串 |
| 年龄 | `TINYINT UNSIGNED` | 范围小且不为负数 |
| 库存数量 | `INT UNSIGNED NOT NULL DEFAULT 0` | 不应为负数，通常要有默认值 |
| 金额 | `DECIMAL(10,2) NOT NULL DEFAULT 0.00` | 需要精确小数 |
| 折扣率 | `DECIMAL(5,2)` | 例如 100.00 或 99.99 这类比例值 |
| 生日 | `DATE` | 只需要日期，不需要时间 |
| 创建时间 | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP` | 系统记录时间 |
| 更新时间 | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | 资料更新时刷新 |
| 文章标题 | `VARCHAR(200)` | 短文本 |
| 文章正文 | `TEXT` / `MEDIUMTEXT` | 长文本，注意索引策略 |
| 状态码 | `TINYINT` / `SMALLINT` | 常搭配代码表或枚举说明 |
| 固定单选值 | `ENUM(...)` | 候选值稳定时才适合 |
| 扩展属性 | `JSON` | 结构弹性高，但高频查询字段应谨慎放入 |
| 经纬度位置 | `POINT` | 需要搭配空间函数与 SRID 观念 |

---

## 六、一个简单建表示例

下面示例不是要你直接照抄，而是用来观察「字段类型 + 字段属性」如何一起出现。

```sql
CREATE TABLE user_profile (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    username VARCHAR(50) NOT NULL COMMENT '用户名',
    email VARCHAR(255) NOT NULL COMMENT '邮箱',
    age TINYINT UNSIGNED DEFAULT NULL COMMENT '年龄',
    balance DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '账户余额',
    birthday DATE DEFAULT NULL COMMENT '生日',
    status TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态：1启用，0停用',
    extra_info JSON DEFAULT NULL COMMENT '扩展资料',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_profile_email (email)
) COMMENT='用户资料表';
```

可以观察几个重点：

- `id` 是主键，所以使用整数、自增、非空、无符号。
- `username`、`email` 是短文本，所以使用 `VARCHAR`。
- `age` 不会是负数，所以可以使用 `UNSIGNED`。
- `balance` 是金额，所以使用 `DECIMAL`，不要用 `FLOAT` 或 `DOUBLE`。
- `birthday` 只需要日期，所以使用 `DATE`。
- `created_at`、`updated_at` 是系统记录时间，所以使用日期时间类型，并搭配默认值或自动更新时间。
- `extra_info` 是扩展资料，所以可以考虑 `JSON`；但如果里面某些字段经常被查询，就应考虑拆成普通列或建立相应索引策略。

---

## 七、常见混淆点

### 1. 字段类型不等于字段属性

`INT`、`VARCHAR(50)`、`DECIMAL(10,2)` 是字段类型。

`NOT NULL`、`DEFAULT`、`PRIMARY KEY`、`UNSIGNED`、`AUTO_INCREMENT` 是字段属性或约束。

读建表语句时，要把这两层拆开看。

### 2. `NULL` 不是空字符串，也不是 0

- `NULL`：没有值、不知道值、尚未产生值。
- `''`：有值，只是这个值是空字符串。
- `0`：有值，而且这个值是数字 0。

不要把三者混在一起，否则查询条件、统计结果和业务判断都会变得混乱。

### 3. 金额不要优先用浮点数

`FLOAT`、`DOUBLE` 是近似数值类型，适合允许误差的计算场景。

金额、余额、税额、价格这类字段通常更适合 `DECIMAL`，因为它强调十进制精确表示。

### 4. `VARCHAR` 和 `TEXT` 不是单纯看谁容量大

`VARCHAR` 适合普通短字符串，例如名称、邮箱、标题、地址。

`TEXT` 适合长文本，例如文章正文、备注说明、大段描述。

不要因为 `TEXT` 容量大就全部使用 `TEXT`，因为它在默认值、索引、排序、查询习惯上都和普通短字符串不完全一样。

### 5. `ENUM` / `SET` 适合稳定集合，不适合经常变化的业务选项

如果候选值很稳定，例如小型固定状态，`ENUM` 或 `SET` 可以考虑。

如果候选值会经常新增、下架、排序、国际化或需要后台维护，通常应考虑普通字段搭配字典表，或使用关联表来表达多选关系。

### 6. `JSON` 不是逃避表结构设计的万能方案

`JSON` 适合弹性扩展资料，但不代表所有不确定字段都应该塞进 JSON。

如果某个 JSON 内部字段经常用于查询、排序、筛选、报表统计或关联，通常要考虑拆成普通列，或进一步学习 generated column / expression index / multi-valued index 等索引策略。

### 7. 二进制资料和文本资料要分开理解

`TEXT` 是字符资料，会受到字符集与排序规则影响。

`BLOB` 是二进制资料，适合原始 bytes，不应拿来当普通文章内容使用。

---

## 八、这一页和后续章节的关系

这一篇是总览页，后续可以按照下面顺序继续深入：

1. [2 整数类型](./2%20整数类型.md)：范围、`UNSIGNED`、显示宽度、`ZEROFILL`。
2. [3 浮点类型](./3%20浮点类型.md)：`FLOAT`、`DOUBLE` 与近似误差。
3. [4 定点数类型](./4%20定点数类型.md)：`DECIMAL(M,D)` 与金额场景。
4. [5 位类型：BIT](./5%20位类型：BIT.md)：位标记与二进制显示。
5. [6 日期与时间类型](./6%20日期与时间类型.md)：`DATE`、`DATETIME`、`TIMESTAMP` 的语义。
6. [7 文本字符串类型](./7%20文本字符串类型.md)：`CHAR`、`VARCHAR`、`TEXT` 的选型边界。
7. [8 ENUM 类型](./8%20ENUM%20类型.md)：稳定单选集合。
8. [9 SET 类型](./9%20SET%20类型.md)：稳定多选集合。
9. [10 二进制字符串类型](./10%20二进制字符串类型.md)：`BINARY`、`VARBINARY`、`BLOB`。
10. [11 JSON 类型](./11%20JSON%20类型.md)：半结构化资料与查询边界。
11. [12 空间类型](./12%20空间类型.md)：地理位置与空间数据。
12. [13 小结及选择建议](./13%20小结及选择建议.md)：综合选型建议。

---

## 自测问题

1. MySQL 数据类型可以先粗分成哪几大类？
2. `INT`、`DECIMAL`、`DOUBLE`、`VARCHAR`、`TEXT`、`BLOB`、`JSON` 分别适合什么场景？
3. 字段类型和字段属性有什么不同？请用 `BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY` 拆解说明。
4. 为什么金额字段通常不建议使用 `FLOAT` 或 `DOUBLE`？
5. 为什么电话号码、身份证号、邮递区号通常不适合用整数类型？
6. `NULL`、空字符串 `''`、数字 `0` 有什么差异？
7. 什么情况下可以考虑 `ENUM`？什么情况下应该改用字典表？
8. 什么情况下可以考虑 `JSON`？什么情况下应该拆成普通字段？
9. 如果一个字段经常被查询和排序，选型时要额外注意什么？
10. 如果你要设计一个订单表，`order_id`、`amount`、`status`、`created_at`、`remark` 分别可以优先考虑什么类型？

---

## 一句话抓核心

MySQL 数据类型的学习重点，不是背出所有类型名称，而是建立「根据业务语义、范围、精度、长度、查询方式与维护成本来选择字段类型」的判断能力。

---

## 返回导航

- [回到第十二章入口](./README.md)
- [下一篇：2 整数类型](./2%20整数类型.md)
- [回到 README](../../README.md)

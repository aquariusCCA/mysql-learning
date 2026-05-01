# 第十一章_数据处理之增删改

这一章开始从“查询数据、定义表结构”，进入“直接处理数据内容”。

前面的章节主要解决：

```text
怎么把资料查出来？
怎么建立数据库和数据表？
```

到了这一章，重点会转成：

```text
资料已经存在于表中，接下来要如何新增、修改、删除？
```

也就是进入 DML：

```text
Data Manipulation Language
数据操作语言
```

本章的核心语句是：

```sql
INSERT
UPDATE
DELETE
```

这三类语句和 `SELECT` 最大的不同在于：

> `SELECT` 写错，通常只是查询结果不正确；  
> `INSERT`、`UPDATE`、`DELETE` 写错，可能真的改变数据库中的资料。

例如：

```sql
UPDATE employees
SET salary = 10000;
```

如果没有 `WHERE`，可能会把所有员工薪资都改成 `10000`。

又例如：

```sql
DELETE FROM employees;
```

如果没有 `WHERE`，可能会删除整张员工表中的所有资料。

所以本章重点不是只会写增删改语法，而是要开始建立：

```text
安全操作资料的思维
```

也就是：

```text
先确认范围，再执行变更。
先 SELECT 检查，再 UPDATE / DELETE。
重要操作用事务保护。
```

---

## 本章在整体学习地图中的位置

- 前面的查询章节解决“怎么把资料查出来”。
- 第十章解决“数据库、数据表、字段结构怎么定义”。
- 第十一章开始解决“资料本身怎么被新增、修改、删除”。
- 学到这里，SQL 才正式从“读数据”进入“改数据”。

可以把这一章理解成：

> 从“资料结构设计”过渡到“资料变更控制”的起点章节。

---

## 本章学习目标

学完这一章后，应能掌握：

1. 如何使用 `INSERT` 向表中插入数据。
2. 如何使用 `UPDATE` 修改表中已有数据。
3. 如何使用 `DELETE` 删除表中已有数据。
4. 为什么 `UPDATE` 和 `DELETE` 一定要特别注意 `WHERE`。
5. 如何在执行 DML 前使用 `SELECT` 检查影响范围。
6. 如何理解 `NULL`、`DEFAULT`、`AUTO_INCREMENT` 在插入数据时的作用。
7. 如何使用多行 `INSERT` 和 `INSERT ... SELECT` 处理批量新增。
8. 如何理解 `Rows matched`、`Changed`、`Warnings` 等执行结果。
9. 为什么更新或删除资料时可能发生外键约束错误。
10. 如何区分 `DELETE`、`TRUNCATE TABLE`、`DROP TABLE`。
11. 如何使用 `START TRANSACTION`、`COMMIT`、`ROLLBACK` 降低误操作风险。
12. 如何理解生成列 / 计算列和 `INSERT`、`UPDATE`、`DELETE` 的关系。

---

## 建议阅读顺序

### 1. [前言](./前言.md)

先建立整章主轴：DML 不只是语法，而是会改变资料的操作。

这一篇重点是：

- 什么是 DML；
- 为什么 `INSERT`、`UPDATE`、`DELETE` 的风险比 `SELECT` 高；
- 为什么执行 `UPDATE`、`DELETE` 前要先用 `SELECT` 检查；
- 为什么重要资料操作要配合事务；
- 本章各小节之间的关系。

适合刚进入第十一章时先读一遍，建立整体观念。

---

### 2. [1 插入数据](./1%20插入数据.md)

正式进入“新增资料”的基础实作页。

这一篇重点是：

- `INSERT INTO ... VALUES ...` 的基本写法；
- 全字段插入与指定字段插入的差异；
- 为什么实际开发中更推荐指定字段插入；
- `NULL`、`DEFAULT`、`AUTO_INCREMENT` 的差异；
- 如何一次插入多笔资料；
- 如何使用 `INSERT ... SELECT` 把查询结果插入另一张表；
- 插入时常见的字段数量、字段类型、主键重复问题。

适合准备开始写第一条 `INSERT`，或想比较不同插入方式时阅读。

---

### 3. [2 更新数据](./2%20更新数据.md)

进入“修改既有资料”的基础实作页。

这一篇重点是：

- `UPDATE ... SET ... WHERE ...` 的基本写法；
- 如何更新单个字段或多个字段；
- 如何使用表达式更新字段值；
- 为什么 `WHERE` 是 `UPDATE` 中最关键的安全条件；
- 省略 `WHERE` 会发生什么；
- 为什么更新前要先用 `SELECT` 检查范围；
- 如何理解 `Rows matched` 和 `Changed`；
- 更新失败时，为什么要考虑外键约束、非空约束、唯一约束；
- 如何使用事务降低误更新风险。

适合准备修改既有资料，或想快速确认 `WHERE` 风险与完整性错误时阅读。

---

### 4. [3 删除数据](./3%20删除数据.md)

进入“删除既有资料”的基础实作页。

这一篇重点是：

- `DELETE FROM ... WHERE ...` 的基本写法；
- 如何删除指定资料或符合条件的多笔资料；
- 省略 `WHERE` 会发生什么；
- 为什么删除前要先用 `SELECT` 检查范围；
- 删除父表资料前，为什么要检查子表外键依赖；
- 外键的 `ON DELETE RESTRICT`、`CASCADE`、`SET NULL` 差异；
- `DELETE`、`TRUNCATE TABLE`、`DROP TABLE` 的差异；
- 物理删除与逻辑删除的差异；
- 如何使用事务降低误删除风险。

适合准备删除资料，或想比较 `DELETE / TRUNCATE / DROP` 时阅读。

---

### 5. [4 生成列 / 计算列](./4%20MySQL8%20新特性：计算列.md)

这一篇介绍 MySQL 的 Generated Column，也就是生成列 / 计算列。

这里不再把它理解成单纯的“MySQL 8 新特性”，而是把重点放在：

> 某个字段的值，可以由同一行中的其他字段自动计算出来。

这一篇重点是：

- 什么是生成列 / 计算列；
- `GENERATED ALWAYS AS` 的基本写法；
- 为什么生成列不需要手动插入或更新；
- `VIRTUAL` 和 `STORED` 的差异；
- 更新基础字段后，生成列为什么会自动变化；
- 生成列适合哪些场景；
- 生成列不适合哪些场景；
- 生成列和普通字段、视图、触发器的差异。

适合学完基本增删改后，补强对“自动计算字段”的理解。

---

## 本章小节

- [前言](./前言.md)：建立第十一章整体定位，说明 DML 会改变资料，并建立安全操作观念。
- [1 插入数据](./1%20插入数据.md)：整理 `VALUES` 插入、多行插入、`INSERT ... SELECT`、`NULL`、`DEFAULT`、`AUTO_INCREMENT` 等新增资料重点。
- [2 更新数据](./2%20更新数据.md)：整理 `UPDATE` 的基本写法、`SET` 与 `WHERE` 的作用、执行结果判读，以及误更新防范方式。
- [3 删除数据](./3%20删除数据.md)：整理 `DELETE FROM` 的基本写法、`WHERE` 的作用、外键依赖、事务保护，以及 `DELETE / TRUNCATE / DROP` 差异。
- [4 生成列 / 计算列](./4%20MySQL8%20新特性：计算列.md)：整理 Generated Column 的概念、`VIRTUAL / STORED` 差异，以及它和 DML 的关系。

---

## 本章适合快速回查的主题

- 想知道第十一章到底在学什么：看 [前言](./前言.md)
- 想理解 DML 为什么比 `SELECT` 危险：看 [前言](./前言.md)
- 想建立安全操作资料流程：看 [前言](./前言.md)
- 想回查最基本的 `INSERT INTO ... VALUES ...` 语法：看 [1 插入数据](./1%20插入数据.md)
- 想比较全字段插入、指定字段插入、多行插入与 `INSERT ... SELECT`：看 [1 插入数据](./1%20插入数据.md)
- 想理解 `NULL`、`DEFAULT`、`AUTO_INCREMENT` 的差异：看 [1 插入数据](./1%20插入数据.md)
- 想回查 `UPDATE ... SET ... WHERE ...` 的基本语法：看 [2 更新数据](./2%20更新数据.md)
- 想确认省略 `WHERE` 会不会整表更新：看 [2 更新数据](./2%20更新数据.md)
- 想理解 `Rows matched` 和 `Changed` 的差异：看 [2 更新数据](./2%20更新数据.md)
- 想回查 `DELETE FROM ... WHERE ...` 的基本语法：看 [3 删除数据](./3%20删除数据.md)
- 想确认省略 `WHERE` 会不会删光整张表资料：看 [3 删除数据](./3%20删除数据.md)
- 想比较 `DELETE`、`TRUNCATE TABLE`、`DROP TABLE`：看 [3 删除数据](./3%20删除数据.md)
- 想理解物理删除和逻辑删除：看 [3 删除数据](./3%20删除数据.md)
- 想了解生成列 / 计算列，或确认 `GENERATED ALWAYS AS` 的基本概念：看 [4 生成列 / 计算列](./4%20MySQL8%20新特性：计算列.md)
- 想比较 `VIRTUAL` 和 `STORED`：看 [4 生成列 / 计算列](./4%20MySQL8%20新特性：计算列.md)

---

## 本章核心口诀

```text
INSERT 看字段和值是否对应。
UPDATE 看 SET 和 WHERE。
DELETE 看 WHERE 和外键。
TRUNCATE 是清空表。
DROP 是删除表。
重要操作先 SELECT。
危险操作包事务。
```

---

## 一句话抓核心

第十一章的重点不是只会写 `INSERT`、`UPDATE`、`DELETE`，而是开始把：

```text
资料怎么变更
变更范围怎么确认
变更能不能回滚
变更会不会破坏约束
```

放在一起理解。

---

## 推荐安全流程

执行 `UPDATE` 或 `DELETE` 时，推荐按照下面流程：

```text
1. 先写 SELECT 检查目标资料
2. 确认影响范围是否正确
3. 重要操作开启事务
4. 执行 UPDATE 或 DELETE
5. 再次 SELECT 确认结果
6. 正确就 COMMIT，错误就 ROLLBACK
```

示例：

```sql
START TRANSACTION;

SELECT *
FROM employees
WHERE employee_id = 113;

UPDATE employees
SET department_id = 70
WHERE employee_id = 113;

SELECT *
FROM employees
WHERE employee_id = 113;

COMMIT;
-- 如果发现错误，则使用 ROLLBACK;
```

---

## 返回导航

- [回到 README](../../README.md)
- [上一章：第十章_创建和管理表](../第十章_创建和管理表/README.md)

# 1 SQL 概述

> 所属章节：[第三章_基本的SELECT语句](./README.md)
> 建议回查情境：想快速确认 SQL 是什么、SQL 标准的发展背景、`DDL` / `DML` / `DCL` / `DQL` / `TCL` 分别代表什么，以及 `SELECT` 为什么是后续学习重点时

## 本节导读

这一节主要建立 SQL 的整体认识，包括它的历史背景、在关系型数据库中的作用，以及 DDL、DML、DCL、DQL、TCL 等常见分类。

如果你后面要正式进入 `SELECT` 查询，这一节的价值在于先把“SQL 到底是什么、解决什么问题、常见语句属于哪一类”这些基础框架搭起来。

如果你想先看最基础的 SQL 实际操作例子，例如 `create database`、`use`、`select`、`insert into`，可以搭配阅读 [第二章：4 MySQL 演示使用](../第二章_MySQL環境搭建/4%20MySQL%20演示使用.md)。

## 你会在这篇学到什么

- SQL 的基本含义：结构化查询语言。
- SQL 为什么会长期存在于关系型数据库体系中。
- SQL 标准与不同数据库厂商实现之间的关系。
- SQL 常见分类：`DDL`、`DML`、`DCL`、`DQL`、`TCL`。
- 为什么 `SELECT` 是 SQL 学习中的核心语句。

## 关键字

- `SQL`：Structured Query Language，结构化查询语言
- `关系模型`：SQL 主要服务于关系型数据库
- `IBM`：SQL 早期由 IBM 在 20 世纪 70 年代推动发展
- `ANSI`：美国国家标准局，参与制定 SQL 标准
- `SQL-86` `SQL-89` `SQL-92` `SQL-99`：常见 SQL 标准版本
- `DDL`：数据定义语言，如 `CREATE`、`DROP`、`ALTER`
- `DML`：数据操作语言，如 `INSERT`、`DELETE`、`UPDATE`、`SELECT`
- `DCL`：数据控制语言，如 `GRANT`、`REVOKE`
- `DQL`：数据查询语言，通常指 `SELECT`
- `TCL`：事务控制语言，如 `COMMIT`、`ROLLBACK`、`SAVEPOINT`

## 1.1 SQL背景知识

这一小节先从 SQL 的历史和使用场景切入，帮助你理解为什么后续学习数据库时一定绕不开 SQL。

- 1946 年，世界上第一台电脑诞生，如今，借由这台电脑发展起来的互联网已经自成江湖。在这几十年里，无数的技术、产业在这片江湖里沉浮，有的方兴未艾，有的已经几幕兴衰。但在这片浩荡的波动里，有一门技术从未消失，甚至「老当益壮」，那就是 SQL。
    - 45 年前，也就是 1974 年，IBM 研究员发布了一篇揭开数据库技术的论文《SEQUEL：一门结构化的英语查询语言》，直到今天这门结构化的查询语言并没有太大的变化，相比于其他语言，`SQL 的半衰期可以说是非常长`了。

- 不论是前端工程师，还是后端算法工程师，都一定会和数据打交道，都需要了解如何又快又准确地提取自己想要的数据。更别提数据分析师了，他们的工作就是和数据打交道，整理不同的报告，以便指导业务决策。

- SQL（Structured Query Language，结构化查询语言）是使用关系模型的数据库应用语言，`与数据直接打交道`，由`IBM`上世纪70年代开发出来。后由美国国家标准局（ANSI）开始着手制定SQL标准，先后有`SQL-86`，`SQL-89`，`SQL-92`，`SQL-99`等标准。
    - SQL 有两个重要的标准，分别是 SQL92 和 SQL99，它们分别代表了 92 年和 99 年颁布的 SQL 标准，我们今天使用的 SQL 语言依然遵循这些标准。

- 不同的数据库生产厂商都支持SQL语句，但都有特有内容。
    
    ![SQLisputonghua.jpg](./images/SQLisputonghua.jpg)
    

## 1.2 SQL语言排行榜

这一小节用排行榜说明 SQL 的使用热度。重点不是记排名，而是理解 SQL 仍然是非常常用的数据库语言。

自从 SQL 加入了 TIOBE 编程语言排行榜，就一直保持在 Top 10。

![image-20211014230114639.png](./images/image-20211014230114639.png)

## 1.3 SQL 分类

SQL 语言在功能上主要分为如下 3 大类：

- **DDL（Data Definition Languages、数据定义语言）**，这些语句定义了不同的数据库、表、视图、索引等数据库对象，还可以用来创建、删除、修改数据库和数据表的结构。
    - 主要的语句关键字包括`CREATE`、`DROP`、`ALTER`等。

- **DML（Data Manipulation Language、数据操作语言）**，用于添加、删除、更新和查询数据库记录，并检查数据完整性。
    - 主要的语句关键字包括`INSERT`、`DELETE`、`UPDATE`、`SELECT`等。
    - **SELECT是SQL语言的基础，最为重要。**

- **DCL（Data Control Language、数据控制语言）**，用于定义数据库、表、字段、用户的访问权限和安全级别。
    - 主要的语句关键字包括`GRANT`、`REVOKE`、`COMMIT`、`ROLLBACK`、`SAVEPOINT`等。

> 因为查询语句使用的非常的频繁，所以很多人把查询语句单拎出来一类：DQL（数据查询语言）。
> 还有单独将`COMMIT`、`ROLLBACK` 取出来称为 TCL （Transaction Control Language，事务控制语言）。

### 分类回查表

| 分类 | 全称 | 主要作用 | 常见关键字 |
| --- | --- | --- | --- |
| `DDL` | Data Definition Language | 定义数据库对象结构 | `CREATE`、`DROP`、`ALTER` |
| `DML` | Data Manipulation Language | 增删改查数据库记录 | `INSERT`、`DELETE`、`UPDATE`、`SELECT` |
| `DCL` | Data Control Language | 控制权限与安全级别 | `GRANT`、`REVOKE` |
| `DQL` | Data Query Language | 查询数据 | `SELECT` |
| `TCL` | Transaction Control Language | 控制事务提交与回滚 | `COMMIT`、`ROLLBACK`、`SAVEPOINT` |

> 注意：不同教材对分类边界的处理可能略有差异。例如有的教材会把 `SELECT` 放在 `DML` 中，有的会单独拆成 `DQL`；有的会先把事务控制语句放进控制类语言，再单独强调 `TCL`。学习时重点是知道这些关键字分别解决什么问题。

## 常见混淆点

- `SQL` 不是某个数据库产品，而是一种用于操作关系型数据库的语言。
- MySQL、Oracle、SQL Server 等数据库都支持 SQL，但各厂商可能有自己的扩展语法。
- `SELECT` 可以归入 `DML`，也常被单独归为 `DQL`，因为查询在实际使用中非常高频。
- `COMMIT`、`ROLLBACK`、`SAVEPOINT` 常被单独归为 `TCL`，因为它们关注的是事务控制。

## 常见回查问题

- SQL 的完整英文名称是什么？
- SQL 与关系型数据库是什么关系？
- SQL 标准和数据库厂商特有语法之间是什么关系？
- `CREATE`、`DROP`、`ALTER` 属于哪一类？
- `INSERT`、`DELETE`、`UPDATE`、`SELECT` 属于哪一类？
- 为什么很多资料会把 `SELECT` 单独归为 `DQL`？
- `COMMIT`、`ROLLBACK`、`SAVEPOINT` 为什么常被归为 `TCL`？

## 一句话抓核心

SQL 是关系型数据库中直接操作数据的核心语言；学好 `SELECT` 之前，先分清 SQL 的历史背景、标准化特点，以及不同语句分类分别负责定义结构、操作数据、控制权限、查询数据和控制事务。

## 小结

这一节你需要记住：

- SQL 的全称是 Structured Query Language，即结构化查询语言。
- SQL 主要服务于关系型数据库，用来和数据直接打交道。
- SQL 有标准版本，但不同数据库厂商会在标准 SQL 之外加入自己的特有内容。
- SQL 常见分类包括 `DDL`、`DML`、`DCL`、`DQL`、`TCL`。
- `SELECT` 是后续学习的核心语句，很多资料会把它从 `DML` 中单独拿出来归为 `DQL`。

## 延伸阅读

- [2 数据库与数据库管理系统](../第一章_數據庫概述/2%20数据库与数据库管理系统.md)
- [3 MySQL 介绍](../第一章_數據庫概述/3%20MySQL%20介绍.md)
- [2 SQL语言的规则与规范](./2%20SQL语言的规则与规范.md)
- [第二章：4 MySQL 演示使用](../第二章_MySQL環境搭建/4%20MySQL%20演示使用.md)

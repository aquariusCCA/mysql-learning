# 1 SQL 概述

> 所属章节：[第三章_基本的SELECT语句](./README.md)

## 本节导读

这一节主要建立 SQL 的整体认识，包括它的历史背景、在关系型数据库中的作用，以及 DDL、DML、DCL、DQL、TCL 等常见分类。

如果你后面要正式进入 `SELECT` 查询，这一节的价值在于先把“SQL 到底是什么、解决什么问题、常见语句属于哪一类”这些基础框架搭起来。

如果你想先看最基础的 SQL 实际操作例子，例如 `create database`、`use`、`select`、`insert into`，可以搭配阅读 [第二章：4 MySQL 演示使用](../第二章_MySQL環境搭建/4%20MySQL%20演示使用.md)。

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

- 1946 年，世界上第一台电脑诞生，如今，借由这台电脑发展起来的互联网已经自成江湖。在这几十年里，无数的技术、产业在这片江湖里沉浮，有的方兴未艾，有的已经几幕兴衰。但在这片浩荡的波动里，有一门技术从未消失，甚至「老当益壮」，那就是 SQL。
    - 45 年前，也就是 1974 年，IBM 研究员发布了一篇揭开数据库技术的论文《SEQUEL：一门结构化的英语查询语言》，直到今天这门结构化的查询语言并没有太大的变化，相比于其他语言，`SQL 的半衰期可以说是非常长`了。

- 不论是前端工程师，还是后端算法工程师，都一定会和数据打交道，都需要了解如何又快又准确地提取自己想要的数据。更别提数据分析师了，他们的工作就是和数据打交道，整理不同的报告，以便指导业务决策。

- SQL（Structured Query Language，结构化查询语言）是使用关系模型的数据库应用语言，`与数据直接打交道`，由`IBM`上世纪70年代开发出来。后由美国国家标准局（ANSI）开始着手制定SQL标准，先后有`SQL-86`，`SQL-89`，`SQL-92`，`SQL-99`等标准。
    - SQL 有两个重要的标准，分别是 SQL92 和 SQL99，它们分别代表了 92 年和 99 年颁布的 SQL 标准，我们今天使用的 SQL 语言依然遵循这些标准。

- 不同的数据库生产厂商都支持SQL语句，但都有特有内容。
    
    ![SQLisputonghua.jpg](./images/SQLisputonghua.jpg)
    

## 1.2 SQL语言排行榜

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

## 延伸阅读

- [2 数据库与数据库管理系统](../第一章_數據庫概述/2%20数据库与数据库管理系统.md)
- [3 MySQL 介绍](../第一章_數據庫概述/3%20MySQL%20介绍.md)
- [第二章：4 MySQL 演示使用](../第二章_MySQL環境搭建/4%20MySQL%20演示使用.md)

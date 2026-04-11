# MySQL 学习笔记

这份仓库用于整理 MySQL 课程笔记，目前内容以 `MySQL 基礎篇` 为主。整理方向不是把正文压缩成摘要，而是在保留教学型内容的前提下，补齐章节入口、阅读顺序与回查导航，让这份笔记同时适合顺读、跳读和后续扩充。

## 这份笔记怎么使用

- 第一次学习时，建议先从章節 `README.md` 进入，再按本章建议顺序阅读小节。
- 复习时，优先使用各章的“适合快速回查的主题”，能更快定位到具体问题。
- 图片资源统一放在各章的 `images/` 目录，小节文件使用相对路径引用，移动文件时要一起检查链接。

## 目前进度

- 已收录：`MySQL 基礎篇` 第 1 章到第 5 章。
- 已建立章节入口：第 1 章到第 5 章均已补齐 `README.md`。
- 当前学习主线已覆盖：数据库概念、环境搭建、基础 `SELECT`、运算符、排序。
- 第五章目前以“排序”内容为主，“分页”主题仍可继续补充。

## 章节导航

### MySQL 基礎篇

- [第一章_數據庫概述](./MySQL%20基礎篇/第一章_數據庫概述/README.md)
  先建立数据库、`DBMS`、MySQL、关系型数据库与表关系设计的基础概念。
- [第二章_MySQL環境搭建](./MySQL%20基礎篇/第二章_MySQL環境搭建/README.md)
  处理下载安装、登录、基础演示、图形化工具、目录结构与常见环境问题。
- [第三章_基本的SELECT语句](./MySQL%20基礎篇/第三章_基本的SELECT语句/README.md)
  从 SQL 分类、书写规范开始，进入最基础的 `SELECT`、表结构查看与 `WHERE` 过滤。
- [第四章_运算符](./MySQL%20基礎篇/第四章_运算符/README.md)
  补上算术运算、比较运算、空值判断、范围判断与模式匹配等查询条件基础。
- [第五章_排序与分页](./MySQL%20基礎篇/第五章_排序与分页/README.md)
  当前已整理查询排序与别名排序，后续可继续补齐分页相关内容。

## 建议阅读顺序

1. [第一章_數據庫概述](./MySQL%20基礎篇/第一章_數據庫概述/README.md)
2. [第二章_MySQL環境搭建](./MySQL%20基礎篇/第二章_MySQL環境搭建/README.md)
3. [第三章_基本的SELECT语句](./MySQL%20基礎篇/第三章_基本的SELECT语句/README.md)
4. [第四章_运算符](./MySQL%20基礎篇/第四章_运算符/README.md)
5. [第五章_排序与分页](./MySQL%20基礎篇/第五章_排序与分页/README.md)

## 快速回查入口

- 想确认为什么应用数据不能只放在内存里：看 [1 为什么要使用数据库](./MySQL%20基礎篇/第一章_數據庫概述/1%20为什么要使用数据库.md)
- 分不清 `DB`、`DBMS`、`SQL` 的关系：看 [2 数据库与数据库管理系统](./MySQL%20基礎篇/第一章_數據庫概述/2%20数据库与数据库管理系统.md)
- 需要重新安装或配置 MySQL：看 [2 MySQL 的下载、安装、配置](./MySQL%20基礎篇/第二章_MySQL環境搭建/2%20MySQL%20的下载、安装、配置.md)
- 忘了怎么启动服务、登录或退出 MySQL：看 [3 MySQL 的登录](./MySQL%20基礎篇/第二章_MySQL環境搭建/3%20MySQL%20的登录.md)
- 想先建立 SQL 的整体认识：看 [1 SQL 概述](./MySQL%20基礎篇/第三章_基本的SELECT语句/1%20SQL%20概述.md)
- 想回查 `SELECT`、列别名、`DISTINCT` 或 `NULL` 运算：看 [3 基本的 SELECT 语句](./MySQL%20基礎篇/第三章_基本的SELECT语句/3%20基本的%20SELECT%20语句.md)
- 想确认 `=`、`<=>`、`IN`、`LIKE`、`REGEXP` 该怎么用：看 [2 比较运算符](./MySQL%20基礎篇/第四章_运算符/2%20比较运算符.md)
- 忘了查询结果如何排序：看 [1 排序数据](./MySQL%20基礎篇/第五章_排序与分页/1%20排序数据.md)

## 参考资料

### 教学影片

- [MySQL数据库入门到大牛](https://www.bilibili.com/video/BV1iq4y1u7vj/?spm_id_from=333.337.search-card.all.click&vd_source=dd97ccca0358cc54d2813737943d2b54)

### 笔记来源

- [MySQL 基礎篇](https://www.cnblogs.com/chenguanqin/p/16366185.html#_label5)
- [MySQL 高級篇](https://www.cnblogs.com/chenguanqin/category/2173929.html)
- [MySql_Demo01](https://github.com/shuhongfan/MySql_Demo01)

### Markdown 参考

- [MarkDown語法大全](https://hackmd.io/@eMP9zQQ0Qt6I8Uqp2Vqy6w/SyiOheL5N/%2FBVqowKshRH246Q7UDyodFA)
- [Markdown 常見語法整理](https://austin72905.github.io/2023/08/05/markdown-syntax)
- [Markdown 常用語法整理](https://sam.webspace.tw/2020/01/10/Markdown%20%E5%B8%B8%E7%94%A8%E8%AA%9E%E6%B3%95%E6%95%B4%E7%90%86)
- [在線 LaTeX 公式編輯器](https://www.latexlive.com/)

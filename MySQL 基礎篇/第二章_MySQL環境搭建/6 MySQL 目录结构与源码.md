# 6 MySQL 目录结构与源码

> 所属章节：[第二章_MySQL環境搭建](./README.md)
> 建议回查情境：想确认 `bin`、`data`、`my.ini` 分别在哪里、需要理解 MySQL 安装目录和数据目录差异、想初步认识 MySQL 源码目录时

## 本节导读

这一节主要帮助你认识 MySQL 安装目录里常见的文件和文件夹分别是做什么的，并对源码目录建立一个基础印象。

这篇不一定是高频操作内容，但很适合在你想弄清楚 `bin`、`data`、`my.ini` 或源码目录分别承担什么角色时回来看。

如果你正在配置环境变量，可以搭配 [2 MySQL 的下载、安装、配置](./2%20MySQL%20的下载、安装、配置.md) 中的 `Path` 设置一起看；如果你是在排查字符集或配置文件问题，也可以回查 [7 常见问题的解决（课外内容）](./7%20常见问题的解决(课外内容).md)。

## 你会在这篇学到什么

- MySQL 安装目录中常见文件和目录的大致作用。
- `bin` 目录为什么常被加入 `Path` 环境变量。
- `data` 目录和用户创建的数据库文件有什么关系。
- `my.ini` 在 MySQL 配置中的作用。
- 如何在下载页面选择 MySQL 源代码。
- MySQL 源码目录中 `sql`、`libmysql`、`mysql-test`、`mysys` 等子目录的基本含义。

## 关键字

- `bin`：MySQL 可执行文件目录
- `mysql.exe`：常用的 MySQL 命令行客户端程序
- `data`：MySQL 数据文件目录
- `my.ini`：MySQL 主要配置文件
- `ProgramData`：Windows 下常见的数据目录位置
- `Source Code`：下载 MySQL 源代码时需要选择的类型
- `C++`：MySQL 主要使用的开发语言
- `sql`：MySQL 核心代码目录
- `libmysql`：客户端程序 API 相关目录
- `mysql-test`：测试工具目录
- `mysys`：操作系统相关函数和辅助函数目录

## 6.1 主要目录结构

| MySQL 的目录结构 | 说明 |
| --- | --- |
| bin 目录 | 所有 MySQL 的可执行文件。如：`mysql.exe` |
| MySQLInstanceConfig.exe | 数据库的配置向导，在安装时出现的内容 |
| data 目录 | 系统数据库所在的目录 |
| `my.ini` 文件 | MySQL 的主要配置文件 |
| `C:\ProgramData\MySQL\MySQL Server 8.0\data\` | 用户创建的数据库所在的目录 |

## 6.2 MySQL 源代码获取

首先，你要进入 MySQL 下载界面。这里你不要选择用默认的「Microsoft Windows」，而是要通过下拉栏，找到「Source Code」，在下面的操作系统版本里面，选择 Windows（Architecture Independent），然后点击下载。

接下来，把下载下来的压缩文件解压，我们就得到了 MySQL 的源代码。

![2402456-20220611182838668-2052351900.png](./images/2402456-20220611182838668-2052351900.png)

MySQL 是用 C++ 开发而成的，我简单介绍一下源代码的组成。

`mysql-8.0.22` 目录下的各个子目录，包含了 MySQL 各部分组件的源代码：

![image-20211007154113052.png](./images/image-20211007154113052.png)

- sql 子目录是 MySQL 核心代码；
- libmysql 子目录是客户端程序 API；
- mysql-test 子目录是测试工具；
- mysys 子目录是操作系统相关函数和辅助函数；

源代码可以用记事本打开查看，如果你有 C++ 的开发环境，也可以在开发环境中打开查看。

![image-20211007154213156.png](./images/image-20211007154213156.png)

如上图所示，源代码并不神秘，就是普通的 C++ 代码，跟你熟悉的一样，而且有很多注释，可以帮助你理解。阅读源代码就像在跟 MySQL 的开发人员对话一样，十分有趣。

## 常见回查问题

- `bin` 目录里通常放什么？为什么它和命令行登录有关？
- `data` 目录和 `C:\ProgramData\MySQL\MySQL Server 8.0\data\` 有什么关系？
- `my.ini` 是做什么用的？
- 想下载 MySQL 源码时，下载页面应该选择哪个类型？
- MySQL 源码中的 `sql`、`libmysql`、`mysql-test`、`mysys` 分别大致对应什么？

## 一句话抓核心

理解 MySQL 目录结构的关键，是先区分可执行程序、配置文件和数据文件分别放在哪里；源码目录则帮助你初步知道 MySQL 的核心代码、客户端 API、测试和系统辅助函数大致如何分布。

## 小结

这一节你需要记住：

- `bin` 目录存放 MySQL 可执行文件，命令行常用的 `mysql.exe` 就在这里。
- `my.ini` 是 MySQL 的主要配置文件，字符集等配置问题常会回到它。
- Windows 下用户创建的数据库常见位置是 `C:\ProgramData\MySQL\MySQL Server 8.0\data\`。
- 下载源码时需要在下载页面选择 `Source Code`，而不是默认的 Windows 安装包。
- MySQL 主要使用 C++ 开发，源码目录中的 `sql`、`libmysql`、`mysql-test`、`mysys` 分别对应不同组件。

## 延伸阅读

- [2 MySQL 的下载、安装、配置](./2%20MySQL%20的下载、安装、配置.md)
- [4 MySQL 演示使用](./4%20MySQL%20演示使用.md)
- [7 常见问题的解决（课外内容）](./7%20常见问题的解决(课外内容).md)

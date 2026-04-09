# 4 MySQL 演示使用

> 所属章节：[第二章_MySQL環境搭建](./README.md)

## 本节导读

这一节通过一组连续的 SQL 操作，演示如何查看数据库、创建数据库与表、插入数据、查询数据，以及处理使用过程中的常见报错。

这篇适合边看边敲命令。第一次学习建议跟着顺序实际操作一次；之后复习时，可以直接按命令名称或错误编号回查对应段落。

## 关键字

- `show databases`：查看当前服务器中的所有数据库
- `create database`：创建数据库
- `use`：切换当前默认数据库
- `show tables`：查看数据库中的所有表
- `create table`：创建数据表
- `select * from`：查询表中的数据
- `insert into`：向表中插入记录
- `show create table`：查看表的建表语句
- `show create database`：查看数据库的创建信息
- `drop table`：删除数据表
- `drop database`：删除数据库
- `ERROR 1046 (3D000)`：没有选择数据库
- `ERROR 1366 (HY000)`：字符集不匹配导致插入中文报错
- `character_%` `collation_%`：查看字符集与校对规则
- `my.ini`：修改 MySQL 默认编码的配置文件
- `latin1` `utf8` `utf8mb4`：常见字符集设置

## 4.1 MySQL的使用演示

## 4.1.1 查看所有的数据库

```sql
show databases;
```

- 「information_schema」是 MySQL 系统自带的数据库，主要保存 MySQL 数据库服务器的系统信息，比如数据库的名称、数据表的名称、字段名称、存取权限、数据文件 所在的文件夹和系统使用的文件夹，等等
- 「performance_schema」是 MySQL 系统自带的数据库，可以用来监控 MySQL 的各类性能指标。
- 「sys」数据库是 MySQL 系统自带的数据库，主要作用是以一种更容易被理解的方式展示 MySQL 数据库服务器的各类性能指标，帮助系统管理员和开发人员监控 MySQL 的技术性能。
- 「mysql」数据库保存了 MySQL 数据库服务器运行时需要的系统信息，比如数据文件夹、当前使用的字符集、约束检查信息，等等


> **✏️为什么 Workbench 里面我们只能看到「demo」和「sys」这 2 个数据库呢？**
> 这是因为，Workbench 是图形化的管理工具，主要面向开发人 员，「demo」和「sys」这 2 个数据库已经够用了。如果有特殊需求，比如，需要监控 MySQL 数据库各项性能指标、直接操作 MySQL 数据库系统文件等，可以由 DBA 通过 SQL 语句，查看其它的系统数据库。关于工具本身的使用入口，可以回看 [5 MySQL 图形化管理工具](./5%20MySQL%20%20图形化管理工具.md)。

## 4.1.2 创建自己的数据库

```sql
create database 数据库名;

#创建atguigudb数据库，该名称不能与已经存在的数据库重名。
create database atguigudb;
```

## 4.1.3 使用自己的数据库

```sql
use 数据库名;

#使用atguigudb数据库
use atguigudb;
```

> **✏️说明：**
> 如果没有使用 use 语句，后面针对数据库的操作也没有加「数据庫名」的限定，那么会报「`ERROR 1046 (3D000): No database selected`（没有选择数据库）」。如果你想集中查看这类报错的处理方式，可以回看 [7 常见问题的解决（课外内容）](./7%20常见问题的解决(课外内容).md) 中对应的问题。

使用完 use 语句之后，如果接下来的 SQL 都是针对一个数据库操作的，那就不用重复 use 了，如果要针对另一个数据库操作，那么要重新 use。

## 4.1.4 查看某个库的所有表格

```sql
show tables;  # 要求前面有 use 语句

show tables from 数据库名;
```

## 4.1.5 创建新的表

```sql
create table 表名称(
	字段名 数据类型,
	字段名 数据类型
);
```

> **✏️说明：如果是最后一个字段，后面就用加逗号，因为逗号的作用是分割每个字段。**

```sql
#创建学生表
create table student(
	id int,
  name varchar(20)  #说名字最长不超过20个字符
);
```

## 4.1.6 查看一个表的数据

```sql
select * from 数据库表名称;
```

```sql
#查看学生表的数据
select * from student;
```

## 4.1.7 添加一条记录

```sql
insert into 表名称 values(值列表);

#添加两条记录到student表中
insert into student values(1,'张三');
insert into student values(2,'李四');
```

报错：

```bash
mysql> insert into student values(1,'张三');
ERROR 1366 (HY000): Incorrect string value: '\\xD5\\xC5\\xC8\\xFD' for column 'name' at row 1
mysql> insert into student values(2,'李四');
ERROR 1366 (HY000): Incorrect string value: '\\xC0\\xEE\\xCB\\xC4' for column 'name' at row 1
mysql> show create table student;
```

字符集的问题。

更完整的字符集说明和排查方式，可以回看 [7 常见问题的解决（课外内容）](./7%20常见问题的解决(课外内容).md) 中关于 `ERROR 1366` 和编码修改的内容。

## 4.1.8 查看表的创建信息

```sql
show create table 表名称\G

#查看student表的详细创建信息
show create table student\G
```

```bash
#结果如下
*************************** 1. row ***************************
       Table: student
Create Table: CREATE TABLE `student` (
  `id` int(11) DEFAULT NULL,
  `name` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1
1 row in set (0.00 sec)
```

上面的结果显示 student 的表格的默认字符集是「latin1」不支持中文。

## 4.1.9 查看数据库的创建信息

```sql
show create database 数据库名\G

#查看atguigudb数据库的详细创建信息
show create database atguigudb\G
```

```sql
#结果如下
*************************** 1. row ***************************
       Database: atguigudb
Create Database: CREATE DATABASE `atguigudb` /*!40100 DEFAULT CHARACTER SET latin1 */
1 row in set (0.00 sec)
```

上面的结果显示 atguigudb 数据库也不支持中文，字符集默认是 latin1。

## 4.1.10 删除表格

```sql
drop table 表名称;
```

```sql
#删除学生表
drop table student;
```

## 4.1.11 删除数据库

```sql
drop database 数据库名;
```

```sql
#删除atguigudb数据库
drop database atguigudb;
```

## 4.2 MySQL的编码设置

## MySQL5.7 中

### 问题再现：命令行操作 sql 乱码问题

```sql
mysql> INSERT INTO t_stu VALUES(1,'张三','男');
ERROR 1366 (HY000): Incorrect string value: '\\xD5\\xC5\\xC8\\xFD' for column 'sname' at row 1
```

### 问题解决

步骤1：查看编码命令

```sql
show variables like 'character_%';
show variables like 'collation_%';
```

步骤2：修改 mysql 的数据目录下的 `my.ini` 配置文件

```sql
[mysql]  #大概在63行左右，在其下添加
...
default-character-set=utf8  #默认字符集

[mysqld]  # 大概在76行左右，在其下添加
...
character-set-server=utf8
collation-server=utf8_general_ci
```

> **⚠️注意：**
> 建议修改配置文件使用 notepad++ 等高级文本编辑器，使用记事本等软件打开修改后可能会导致文件编码修改为「含BOM头」的编码，从而服务重启失败。

步骤3：重启服务

步骤4：查看编码命令

```sql
show variables like 'character_%';
show variables like 'collation_%';
```

![MySQL编码1.jpg](./images/MySQL%E7%BC%96%E7%A0%811.jpg)

![MySQL编码2.jpg](./images/MySQL%E7%BC%96%E7%A0%812.jpg)

如果是以上配置就说明对了。接着我们就可以新创建数据库、新创建数据表，接着添加包含中文的数据了。

## MySQL8.0 中

在 `MySQL 8.0` 版本之前，默认字符集为 `latin1`，`utf8` 字符集指向的是 `utf8mb3`。

网站开发人员在数据库设计的时候往往会将编码修改为 `utf8` 字符集。如果遗忘修改默认的编码，就会出现乱码的问题。

从 `MySQL 8.0` 开始，数据库的默认编码改为 `utf8mb4`，从而避免了上述的乱码问题。

## 延伸阅读

- [3 MySQL 的登录](./3%20MySQL%20的登录.md)
- [5 MySQL 图形化管理工具](./5%20MySQL%20%20图形化管理工具.md)
- [7 常见问题的解决（课外内容）](./7%20常见问题的解决(课外内容).md)

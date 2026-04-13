## 进阶题批改结果

- 评分范围：第 `9` 到第 `20` 题。
- 总分：`77 / 120`

| 题号 | 得分 | 批改说明 |
| --- | --- | --- |
| 9 | 10 / 10 | 这题答对了。 |
| 10 | 8 / 10 | 改写方向对，但原因说明还可以更完整。 |
| 11 | 2 / 10 | 题目重点是“子查询不返回任何行”，你写成了“返回多行会报错”。 |
| 12 | 5 / 10 | 两版 SQL 核心方向对，但少了排除 `141`、`174` 本人，也没解释语义差异。 |
| 13 | 10 / 10 | SQL 正确。 |
| 14 | 5 / 10 | 能表达出条件判断，但没有按笔记中的单行子查询思路写，字段别名也写错。 |
| 15 | 3 / 10 | 子查询用错表了，题目要先从 `departments` 找部门编号。 |
| 16 | 7 / 10 | `ANY` 用对了，但漏了“其它 `job_id`”这个条件。 |
| 17 | 7 / 10 | `ALL` 用对了，但同样漏了排除 `IT_PROG`。 |
| 18 | 8 / 10 | 大意正确，但自然语言还能更精确。 |
| 19 | 2 / 10 | 题目要找“平均工资最低”，你写成了“最低工资最低”。 |
| 20 | 10 / 10 | 这题答对了。 |

### 主要错误

- 第 `11` 题：把“子查询为空”误判成“子查询返回多行”。
- 第 `12` 题：少了 `employee_id NOT IN (141, 174)`，也没说明成对与不成对比较的语义差异。
- 第 `14` 题：没有按笔记里的单行子查询写法处理，`location_tag` 别名也写成了 `location_ta`。
- 第 `15` 题：应该从 `departments` 表按部门名称找编号，不是从 `employees` 表按 `job_id` 推部门。
- 第 `16`、`17` 题：都漏了“其它 `job_id` 中”这句，应该排除 `job_id = 'IT_PROG'`。
- 第 `19` 题：把平均工资和最低工资混掉了。

## 进阶题

### 9. 单行比较操作符判断

说明为什么下面这些操作符通常适合搭配单行子查询：

- `=`
- `>`
- `>=`
- `<`
- `<=`
- `<>`

答：

- 因为单行子查询返回的是一个单独值，外层查询可以把它当成普通常量来比较。

### 10. 改错题：多行结果误用单行比较

下面 SQL 有问题，请说明原因并改写：

```sql
SELECT employee_id, last_name
FROM employees
WHERE salary = (
    SELECT MIN(salary)
    FROM employees
    GROUP BY department_id
);
```

问题说明：

- 子查询里用了 `GROUP BY department_id`，所以会返回多个部门各自的最低工资，也就是多行结果。
- 外层却用了 `salary = (...)` 这种单行比较写法，会造成“多行结果误用单行比较符”的问题。

改写：

```sql
SELECT employee_id, last_name
FROM employees
WHERE salary IN (
    SELECT MIN(salary)
    FROM employees
    GROUP BY department_id
);
```

### 11. 子查询为空时的判断

阅读下面 SQL，说明为什么它可能“语法没错，但查不到结果”：

```sql
SELECT last_name, job_id
FROM employees
WHERE job_id = (
    SELECT job_id
    FROM employees
    WHERE last_name = 'Haas'
);
```

答：

- 这题的重点不是“返回多行报错”，而是内层子查询可能根本找不到 `last_name = 'Haas'` 的记录。
- 如果子查询没有返回任何行，外层条件就拿不到一个实际可比较的值，因此整条 SQL 虽然语法没错，但可能查不到结果。

### 12. 成对比较与不成对比较

请分别写出两版 SQL，查询与 `141` 号或 `174` 号员工的 `manager_id`、`department_id` 相同的其他员工：

1. 使用不成对比较；
2. 使用成对比较。

并说明两者语义差异。

不成对比较：

```sql
SELECT
    e.employee_id,
    e.manager_id,
    e.department_id
FROM employees e
WHERE e.manager_id IN (
    SELECT
        e.manager_id
    FROM employees e
    WHERE e.employee_id IN (141, 174)
)
AND e.department_id IN (
    SELECT
        e.department_id
    FROM employees e
    WHERE e.employee_id IN (141, 174)
)
AND e.employee_id NOT IN (141, 174);
```

成对比较：

```sql
SELECT
    e.employee_id,
    e.manager_id,
    e.department_id
FROM employees e
WHERE (e.manager_id, e.department_id) IN (
    SELECT
        e.manager_id,
        e.department_id
    FROM employees e
    WHERE e.employee_id IN (141, 174)
)
AND e.employee_id NOT IN (141, 174);
```

语义差异：

- 不成对比较：`manager_id` 和 `department_id` 分开判断，只要各自落在目标集合里即可。
- 成对比较：把 `(manager_id, department_id)` 当成一个整体，必须整组匹配。

### 13. `HAVING` 中的单行子查询

查询最低工资大于 `50` 号部门最低工资的部门编号与该部门最低工资。

要求：

- 必须使用 `GROUP BY`；
- 过滤条件写在 `HAVING` 中；
- `HAVING` 中必须包含子查询。

```sql
SELECT
    e.department_id,
    MIN(e.salary)
FROM employees e
GROUP BY e.department_id
HAVING MIN(e.salary) > (
    SELECT
        MIN(e.salary)
    FROM employees e
    WHERE e.department_id = 50
);
```

### 14. `CASE` 中的子查询

根据第九章笔记思路，写一条 SQL：

显示员工的 `employee_id`、`last_name` 和一个自定义字段 `location_tag`。如果员工的 `department_id` 与 `location_id = 1800` 对应部门的 `department_id` 相同，则显示 `Canada`，否则显示 `USA`。

```sql
SELECT
    e.employee_id,
    e.last_name,
    CASE e.department_id
        WHEN (
            SELECT
                d.department_id
            FROM departments d
            WHERE d.location_id = 1800
        )
        THEN 'Canada'
        ELSE 'USA'
    END AS location_tag
FROM employees e;
```

### 15. `IN` 基础题

查询所有在 `IT` 或 `HR` 部门的员工姓名与部门编号。

要求：

- 先用子查询找出部门编号；
- 外层查询使用 `IN`。

```sql
SELECT
    e.last_name,
    e.department_id
FROM employees e
WHERE e.department_id IN (
    SELECT
        d.department_id
    FROM departments d
    WHERE d.department_name IN ('IT', 'Human Resources')
);
```

### 16. `ANY` 题型

查询其它 `job_id` 中，比 `job_id = 'IT_PROG'` 的员工里任意一个工资都低的员工 `employee_id`、`last_name`、`job_id`、`salary`。

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.job_id,
    e.salary
FROM employees e
WHERE e.job_id <> 'IT_PROG'
AND e.salary < ANY (
    SELECT
        e.salary
    FROM employees e
    WHERE e.job_id = 'IT_PROG'
);
```

### 17. `ALL` 题型

把上一题改成：

查询其它 `job_id` 中，比 `job_id = 'IT_PROG'` 的员工里所有工资都低的员工 `employee_id`、`last_name`、`job_id`、`salary`。

```sql
SELECT
    e.employee_id,
    e.last_name,
    e.job_id,
    e.salary
FROM employees e
WHERE e.job_id <> 'IT_PROG'
AND e.salary < ALL (
    SELECT
        e.salary
    FROM employees e
    WHERE e.job_id = 'IT_PROG'
);
```

### 18. `ANY` 与 `ALL` 比较题

说明下面两种条件在语义上有什么差别：

- `salary < ANY (子查询)`
- `salary < ALL (子查询)`

并分别用自然语言翻译这两种条件。

- `salary < ANY (子查询)`：
  只要工资小于子查询结果中的至少一个值，条件就成立。
- `salary < ALL (子查询)`：
  工资必须小于子查询结果中的每一个值，条件才成立。

### 19. 最低平均工资部门

查询平均工资最低的部门 `department_id`。

要求：

- 至少写出一种子查询解法；
- 如果你愿意，可以再补一版使用 `ALL` 的写法。

子查询解法：

```sql
SELECT
    e.department_id
FROM employees e
GROUP BY e.department_id
HAVING AVG(e.salary) = (
    SELECT
        MIN(t.avg_sal)
    FROM (
        SELECT
            AVG(e.salary) AS avg_sal
        FROM employees e
        WHERE e.department_id IS NOT NULL
        GROUP BY e.department_id
    ) t
);
```

`ALL` 解法：

```sql
SELECT
    e.department_id
FROM employees e
WHERE e.department_id IS NOT NULL
GROUP BY e.department_id
HAVING AVG(e.salary) <= ALL (
    SELECT
        AVG(e.salary)
    FROM employees e
    WHERE e.department_id IS NOT NULL
    GROUP BY e.department_id
);
```

### 20. `NOT IN` 空值问题

阅读下面 SQL，说明为什么它可能无法得到你直觉以为的结果：

```sql
SELECT last_name
FROM employees
WHERE employee_id NOT IN (
    SELECT manager_id
    FROM employees
);
```

请重点解释：子查询结果里如果出现 `NULL`，为什么会影响判断。

答：

- `NOT IN` 本质上等价于“不等于集合中的每一个值”。
- 一旦子查询结果里出现 `NULL`，其中一部分比较就会变成“未知”。
- 这样整条条件可能无法判断为 `TRUE`，于是很多你以为应该被保留的记录也不会被查出来，甚至整条查询查不到资料。

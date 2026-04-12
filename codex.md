## 基础题

### 1. 关联前提判断

`employees` 表和 `departments` 表可以做多表查詢，是因為它們之間存在可對應的關聯字段 `department_id`。這個關聯字段在概念上不一定要已經建立成外鍵，只要查詢時能用它建立正確的對應關係即可。

評語：原本把「能不能關聯」和「非等值連接」混在一起了，這題核心是表之間有可對應的關聯字段。

### 2. SQL92 基础等值连接

```sql
SELECT
    e.last_name,
    d.department_name
FROM employees e, departments d
WHERE e.department_id = d.department_id;
```

### 3. SQL99 基础等值连接

```sql
SELECT
    e.last_name,
    d.department_name
FROM employees e
    INNER JOIN departments d
    ON e.department_id = d.department_id;
```

### 4. 三表等值连接

```sql
SELECT
	e.last_name ,
	d.department_name ,
	l.city
FROM employees e
    INNER JOIN departments d
    ON e.department_id = d.department_id
    INNER JOIN locations l
    ON d.location_id =l.location_id;
```

至少需要兩個連接條件

### 5. 非等值连接

```sql
SELECT
	e.last_name ,
	e.salary ,
	jg.grade_level
FROM employees e
	INNER JOIN job_grades jg
	ON e.salary BETWEEN jg.lowest_sal AND jg.highest_sal;
```

### 6. 笛卡尔积排错

會產生這樣的錯誤是因為沒有正確的連接條件

```sql
SELECT
    e.last_name,
    d.department_name
FROM
    employees e,
    departments d
WHERE
    e.department_id = d.department_id;
```

評語：你抓到缺少連接條件這個根因了，但原本 SQL 把分號放錯位置，會直接造成語法錯誤。

## 进阶题

### 7. 重复列名与表别名


```sql
SELECT
	e.employee_id ,
	e.last_name ,
	e.department_id ,
	d.department_id ,
	d.department_name
FROM employees e
		INNER JOIN departments d
		ON e.department_id = d.department_id;
```

評語：原本少了 `e.department_id`，沒有完整滿足題目「兩邊的 department_id 都要保留」的要求。

### 8. 三表连接加普通筛选条件

```sql
SELECT
	e.last_name ,
	d.department_name ,
	l.city
FROM employees e
	INNER JOIN departments d
	ON e.department_id = d.department_id
	INNER JOIN locations l
	ON d.location_id = l.location_id
WHERE l.city = 'Seattle';
```

### 9. 员工、部门、岗位三表内连接

```sql
SELECT
	e.last_name ,
	d.department_name ,
	j.job_title
FROM employees e
	INNER JOIN departments d
	ON e.department_id = d.department_id
	INNER JOIN jobs j
	ON e.job_id = j.job_id;
```

### 10. 左外连接

```sql
SELECT
	e.employee_id ,
	e.last_name ,
	d.department_name
FROM employees e
	LEFT JOIN departments d
	ON e.department_id = d.department_id;
```

### 11. 右外连接

```sql
SELECT
	e.employee_id ,
	e.last_name ,
	d.department_name
FROM employees e
	RIGHT JOIN departments d
	ON e.department_id = d.department_id;
```

### 12. 左表独有数据

```sql
SELECT
	e.employee_id ,
	e.last_name ,
	d.department_name
FROM employees e
	LEFT JOIN departments d
	ON e.department_id = d.department_id
WHERE d.department_id IS NULL;
```

### 13. 右表独有数据

```sql
SELECT
	e.employee_id ,
	e.last_name ,
	d.department_name
FROM employees e
	RIGHT JOIN departments d
	ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;
```

### 14. 自连接基础题

```sql
SELECT
	CONCAT(e.last_name, ' works for ', m.last_name)
FROM employees e
	INNER JOIN employees m
	ON  e.manager_id = m.employee_id;
```

### 15. 自连接定位经理信息

```sql
SELECT
	e.last_name ,
	e.manager_id  ,
	m.last_name
FROM employees e
		INNER JOIN employees m
		ON e.manager_id = m.employee_id
	WHERE e.last_name = 'Chen';
```

評語：原本用 `LIKE '%Chen%'` 會放寬條件，這題題目指定的是精確匹配 `last_name = 'Chen'`。

## 挑战题

### 16. USING 写法

```sql
SELECT
	e.last_name ,
	j.job_title
FROM employees e
	INNER JOIN jobs j
    USING (job_id);
```

### 17. NATURAL JOIN 思考题

`employees` 和 `departments` 中不只一个同名字段。请你思考：

1. 如果直接写 `employees NATURAL JOIN departments`，数据库可能会按哪些同名字段自动连接？

`department_id`、`manager_id`都會參與連接

2. 为什么这种写法在这两张表上有风险？

因為大部分我們只需要靠 `department_id` 就能找到我們要的部門，多了一個 `manager_id` 很容易引發意想不到的錯誤

3. 请把它改写成更稳妥、更明确的 SQL。

```sql
SELECT
	*
FROM employees e
	INNER JOIN departments d
	ON e.department_id = d.department_id
```

### 18. UNION 与 UNION ALL

```sql
SELECT
	e.last_name ,
	e.email
FROM employees e
WHERE e.department_id > 90
UNION
SELECT
	e.last_name ,
	e.email
FROM employees e
WHERE e.email LIKE '%a%';

SELECT
	e.last_name ,
	e.email
FROM employees e
WHERE e.department_id > 90
UNION ALL
SELECT
	e.last_name ,
	e.email
FROM employees e
WHERE e.email LIKE '%a%';
```

差別在於 UNION 會去重

### 19. 模拟满外连接

```sql
SELECT
	e.employee_id,
	e.last_name ,
	d.department_name
FROM employees e
	LEFT JOIN departments d
	ON e.department_id = d.department_id
UNION ALL
SELECT
	e.employee_id,
	e.last_name ,
	d.department_name
FROM employees e
	RIGHT JOIN departments d
	ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;
```

### 20. 只保留左右两边各自独有的数据

```sql
SELECT
	e.employee_id ,
	e.last_name ,
	d.department_name
FROM employees e
LEFT JOIN departments d
ON e.department_id = d.department_id
	WHERE d.department_id IS NULL
UNION ALL
SELECT
	e.employee_id ,
	e.last_name ,
	d.department_name
FROM employees e
RIGHT JOIN departments d
ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;
```

評語：原本寫 `d.department_name IS NULL` 在這份資料下多半能用，但用關聯鍵 `d.department_id IS NULL` 判斷未匹配資料更穩、更貼近筆記寫法。

### 21. SQL92 改写为 SQL99

```sql
SELECT
    e.last_name,
    d.department_name,
    l.city
FROM employees e
INNER JOIN departments d
ON e.department_id = d.department_id
INNER JOIN locations l
ON d.location_id = l.location_id
WHERE l.city LIKE 'S%';
```

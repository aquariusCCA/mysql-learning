# SELECT 实务查询场景练习题参考答案

这份参考答案对应 [SELECT 实务查询场景练习题](./SELECT%20实务查询场景练习题.md)。

- 练习数据使用 `資料/select_practice_scenarios.sql`
- 默认数据库：`select_practice_db`
- 时间相关题按题目约定，把 `2025-04-15` 当作“当前日期”

## 基础题

### 1. 活跃用户查询

```sql
SELECT name, city, register_date
FROM app_users
WHERE status = 'active'
ORDER BY register_date DESC;
```

### 2. 缺货但仍上架的商品

```sql
SELECT product_name, price, category_id
FROM products
WHERE stock = 0
  AND is_active = 1;
```

### 3. 最近 10 笔已付款订单

```sql
SELECT order_id, user_id, order_date, total_amount
FROM customer_orders
WHERE status = 'paid'
ORDER BY order_date DESC
LIMIT 10;
```

### 4. 高价商品

```sql
SELECT product_name, price
FROM products
WHERE price > 1000
ORDER BY price DESC;
```

### 5. 商品名模糊匹配

```sql
SELECT product_name, price
FROM products
WHERE product_name LIKE '%Pro%';
```

### 6. 指定城市的活跃用户

```sql
SELECT user_id, name, city
FROM app_users
WHERE status = 'active'
  AND city IN ('Taipei', 'Taichung', 'Kaohsiung');
```

### 7. 每个分类的商品数

```sql
SELECT category_id, COUNT(*) AS product_count
FROM products
GROUP BY category_id;
```

### 8. 指定金额区间的订单

```sql
SELECT order_id, user_id
FROM customer_orders
WHERE total_amount BETWEEN 500 AND 2000;
```

## 进阶题

### 9. 从未下单的用户

```sql
SELECT au.user_id, au.name
FROM app_users au
LEFT JOIN customer_orders co
  ON au.user_id = co.user_id
WHERE co.order_id IS NULL;
```

### 10. 下单次数不少于 3 次的用户

```sql
SELECT au.user_id, au.name, COUNT(*) AS paid_order_count
FROM app_users au
JOIN customer_orders co
  ON au.user_id = co.user_id
WHERE co.status = 'paid'
GROUP BY au.user_id, au.name
HAVING COUNT(*) >= 3;
```

### 11. 每位用户最近一笔订单

```sql
SELECT co.order_id, co.user_id, co.order_date, co.total_amount
FROM customer_orders co
JOIN (
    SELECT user_id, MAX(order_date) AS max_order_date
    FROM customer_orders
    GROUP BY user_id
) t
  ON co.user_id = t.user_id
 AND co.order_date = t.max_order_date;
```

### 12. 从未卖出过的商品

```sql
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN order_items oi
  ON p.product_id = oi.product_id
WHERE oi.order_item_id IS NULL;
```

### 13. 平均价格较高的分类

```sql
SELECT category_id, AVG(price) AS avg_price
FROM products
GROUP BY category_id
HAVING AVG(price) > 800;
```

### 14. 付款金额不足的订单

```sql
SELECT
    co.order_id,
    co.total_amount - COALESCE(SUM(CASE WHEN p.pay_status = 'success' THEN p.amount END), 0) AS shortfall
FROM customer_orders co
LEFT JOIN payments p
  ON co.order_id = p.order_id
GROUP BY co.order_id, co.total_amount
HAVING COALESCE(SUM(CASE WHEN p.pay_status = 'success' THEN p.amount END), 0) < co.total_amount;
```

说明：只统计 `pay_status = 'success'` 的付款记录，没有成功付款时按 `0` 处理。

### 15. 买过 Laptop 商品的用户

```sql
SELECT au.user_id, au.name
FROM app_users au
WHERE au.user_id IN (
    SELECT DISTINCT co.user_id
    FROM customer_orders co
    JOIN order_items oi
      ON co.order_id = oi.order_id
    JOIN products p
      ON oi.product_id = p.product_id
    JOIN categories c
      ON p.category_id = c.category_id
    WHERE c.category_name = 'Laptop'
);
```

### 16. 同时买过两类商品的用户

```sql
SELECT au.user_id, au.name
FROM app_users au
WHERE au.user_id IN (
    SELECT co.user_id
    FROM customer_orders co
    JOIN order_items oi
      ON co.order_id = oi.order_id
    JOIN products p
      ON oi.product_id = p.product_id
    JOIN categories c
      ON p.category_id = c.category_id
    WHERE c.category_name IN ('Laptop', 'Accessory')
    GROUP BY co.user_id
    HAVING COUNT(DISTINCT c.category_name) = 2
);
```

### 17. 每位用户金额最高的一笔订单

```sql
SELECT co.order_id, co.user_id, co.total_amount
FROM customer_orders co
WHERE co.total_amount = (
    SELECT MAX(co2.total_amount)
    FROM customer_orders co2
    WHERE co2.user_id = co.user_id
);
```

### 18. 订单内高于平均购买数量的明细

```sql
SELECT oi.order_id, oi.product_id, oi.quantity
FROM order_items oi
WHERE oi.quantity > (
    SELECT AVG(oi2.quantity)
    FROM order_items oi2
    WHERE oi2.order_id = oi.order_id
);
```

### 19. 平均订单金额最低的用户

子查询解法：

```sql
SELECT t.user_id
FROM (
    SELECT user_id, AVG(total_amount) AS avg_amount
    FROM customer_orders
    GROUP BY user_id
) t
WHERE t.avg_amount = (
    SELECT MIN(t2.avg_amount)
    FROM (
        SELECT AVG(total_amount) AS avg_amount
        FROM customer_orders
        GROUP BY user_id
    ) t2
);
```

可选 `ALL` 写法：

```sql
SELECT user_id
FROM customer_orders
GROUP BY user_id
HAVING AVG(total_amount) <= ALL (
    SELECT AVG(total_amount)
    FROM customer_orders
    GROUP BY user_id
);
```

### 20. `NOT IN` 空值问题

答案：

- 这条 SQL 的风险在于：子查询结果中可能出现 `NULL`
- 一旦有 `NULL`，`NOT IN` 中的某一步比较就会变成未知
- 例如：

```sql
user_id NOT IN (1, 6, NULL)
```

- 可以理解为：

```sql
user_id <> 1
AND user_id <> 6
AND user_id <> NULL
```

- 最后一项无法得到 `TRUE`，所以结果可能比直觉少，甚至空集合

更稳妥的写法：

```sql
SELECT au.name
FROM app_users au
WHERE NOT EXISTS (
    SELECT 1
    FROM support_tickets st
    WHERE st.status = 'open'
      AND st.user_id = au.user_id
);
```

## 挑战题

### 21. 高于自己历史平均订单金额的订单

```sql
SELECT co.order_id, co.user_id, co.total_amount
FROM customer_orders co
WHERE co.total_amount > (
    SELECT AVG(co2.total_amount)
    FROM customer_orders co2
    WHERE co2.user_id = co.user_id
);
```

### 22. 没有提交过工单的活跃用户

```sql
SELECT au.user_id, au.name
FROM app_users au
WHERE au.status = 'active'
  AND NOT EXISTS (
        SELECT 1
        FROM support_tickets st
        WHERE st.user_id = au.user_id
    );
```

### 23. 每个分类中价格最高的商品

```sql
SELECT p.product_name, p.category_id, p.price
FROM products p
WHERE p.price = (
    SELECT MAX(p2.price)
    FROM products p2
    WHERE p2.category_id = p.category_id
);
```

说明：如果同分类有并列最高价，这种写法会一起保留。

### 24. 订单数高于全站平均订单数的用户

```sql
SELECT au.user_id, au.name, t.order_count
FROM app_users au
JOIN (
    SELECT user_id, COUNT(*) AS order_count
    FROM customer_orders
    GROUP BY user_id
) t
  ON au.user_id = t.user_id
WHERE t.order_count > (
    SELECT AVG(x.order_count)
    FROM (
        SELECT COUNT(*) AS order_count
        FROM customer_orders
        GROUP BY user_id
    ) x
);
```

### 25. 连续下单间隔不超过 7 天的用户

```sql
SELECT DISTINCT au.user_id, au.name
FROM app_users au
JOIN customer_orders o1
  ON au.user_id = o1.user_id
JOIN customer_orders o2
  ON au.user_id = o2.user_id
 AND o1.order_date < o2.order_date
WHERE DATEDIFF(o2.order_date, o1.order_date) <= 7
  AND NOT EXISTS (
        SELECT 1
        FROM customer_orders o3
        WHERE o3.user_id = au.user_id
          AND o3.order_date > o1.order_date
          AND o3.order_date < o2.order_date
    );
```

说明：`NOT EXISTS` 这一段用来保证 `o1` 和 `o2` 是相邻订单，而不是中间还夹着别的订单。

### 26. 有订单且有未关闭工单的用户

```sql
SELECT DISTINCT au.user_id, au.name
FROM app_users au
WHERE EXISTS (
        SELECT 1
        FROM customer_orders co
        WHERE co.user_id = au.user_id
    )
  AND EXISTS (
        SELECT 1
        FROM support_tickets st
        WHERE st.user_id = au.user_id
          AND st.status <> 'closed'
    );
```

### 27. 没有任何上架商品的分类

```sql
SELECT c.category_id, c.category_name
FROM categories c
WHERE NOT EXISTS (
    SELECT 1
    FROM products p
    WHERE p.category_id = c.category_id
      AND p.is_active = 1
);
```

### 28. 买齐某分类全部上架商品的用户

```sql
SELECT au.user_id, au.name
FROM app_users au
WHERE NOT EXISTS (
    SELECT 1
    FROM products p
    JOIN categories c
      ON p.category_id = c.category_id
    WHERE c.category_name = 'Laptop'
      AND p.is_active = 1
      AND NOT EXISTS (
            SELECT 1
            FROM customer_orders co
            JOIN order_items oi
              ON co.order_id = oi.order_id
            WHERE co.user_id = au.user_id
              AND oi.product_id = p.product_id
        )
);
```

说明：外层 `NOT EXISTS` 表示“不存在任何一件还没买到的上架 Laptop 商品”。

## 综合题

### 29. 购买总件数最多的前 5 张已付款订单

```sql
SELECT
    co.order_id,
    co.user_id,
    SUM(oi.quantity) AS total_quantity
FROM customer_orders co
JOIN order_items oi
  ON co.order_id = oi.order_id
WHERE co.status = 'paid'
GROUP BY co.order_id, co.user_id
ORDER BY total_quantity DESC, co.order_id
LIMIT 5;
```

### 30. 注册后 30 天内从未下单的用户

```sql
SELECT au.user_id, au.name, au.register_date
FROM app_users au
WHERE NOT EXISTS (
    SELECT 1
    FROM customer_orders co
    WHERE co.user_id = au.user_id
      AND DATE(co.order_date) >= au.register_date
      AND DATE(co.order_date) <= DATE_ADD(au.register_date, INTERVAL 30 DAY)
);
```

### 31. 高价值用户名单

```sql
SELECT
    au.user_id,
    au.name,
    COUNT(*) AS paid_order_count,
    SUM(co.total_amount) AS paid_total_amount,
    MAX(co.order_date) AS last_paid_order_time
FROM app_users au
JOIN customer_orders co
  ON au.user_id = co.user_id
WHERE au.status = 'active'
  AND co.status = 'paid'
GROUP BY au.user_id, au.name
HAVING SUM(co.total_amount) > 10000;
```

### 32. 异常订单名单

```sql
SELECT
    co.order_id,
    co.user_id,
    co.status,
    co.total_amount
FROM customer_orders co
LEFT JOIN (
    SELECT
        order_id,
        SUM(CASE WHEN pay_status = 'success' THEN amount ELSE 0 END) AS success_paid_amount
    FROM payments
    GROUP BY order_id
) p
  ON co.order_id = p.order_id
LEFT JOIN (
    SELECT order_id, COUNT(*) AS item_count
    FROM order_items
    GROUP BY order_id
) oi
  ON co.order_id = oi.order_id
LEFT JOIN app_users au
  ON co.user_id = au.user_id
WHERE co.status = 'paid'
  AND (
        COALESCE(p.success_paid_amount, 0) <> co.total_amount
        OR COALESCE(oi.item_count, 0) = 0
        OR au.status <> 'active'
      );
```

说明：这题本质上是把三个异常条件并在一起判断。

### 33. 滞销商品名单

```sql
SELECT p.product_id, p.product_name, p.stock
FROM products p
WHERE p.is_active = 1
  AND p.stock > 20
  AND NOT EXISTS (
        SELECT 1
        FROM order_items oi
        JOIN customer_orders co
          ON oi.order_id = co.order_id
        WHERE oi.product_id = p.product_id
          AND co.status = 'paid'
          AND co.order_date >= DATE_SUB('2025-04-15', INTERVAL 90 DAY)
    );
```

说明：这里把“卖出过”按已付款订单来判断，更贴近业务语义。

### 34. 客服风险名单

```sql
SELECT au.user_id, au.name
FROM app_users au
WHERE (
    SELECT COUNT(*)
    FROM support_tickets st
    WHERE st.user_id = au.user_id
      AND st.status <> 'closed'
) >= 2
  AND EXISTS (
        SELECT 1
        FROM customer_orders co
        WHERE co.user_id = au.user_id
          AND co.order_date >= DATE_SUB('2025-04-15', INTERVAL 30 DAY)
    );
```

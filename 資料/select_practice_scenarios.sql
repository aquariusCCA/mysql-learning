SET NAMES utf8mb4;

DROP DATABASE IF EXISTS select_practice_db;
CREATE DATABASE select_practice_db DEFAULT CHARACTER SET utf8mb4;
USE select_practice_db;

DROP TABLE IF EXISTS support_tickets;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS customer_orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS app_users;

CREATE TABLE app_users (
    user_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    register_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL
);

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INT NOT NULL,
    is_active TINYINT(1) NOT NULL,
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE customer_orders (
    order_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id) REFERENCES app_users(user_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES customer_orders(order_id),
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    pay_time DATETIME NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    pay_status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES customer_orders(order_id)
);

CREATE TABLE support_tickets (
    ticket_id INT PRIMARY KEY,
    user_id INT,
    created_at DATETIME NOT NULL,
    closed_at DATETIME NULL,
    status VARCHAR(20) NOT NULL,
    priority VARCHAR(20) NOT NULL,
    CONSTRAINT fk_tickets_user
        FOREIGN KEY (user_id) REFERENCES app_users(user_id)
);

INSERT INTO app_users (user_id, name, city, register_date, status) VALUES
(1, 'Alice', 'Taipei', '2024-12-20', 'active'),
(2, 'Bob', 'Taichung', '2024-12-25', 'active'),
(3, 'Carol', 'Kaohsiung', '2024-11-10', 'inactive'),
(4, 'David', 'Taipei', '2025-01-05', 'active'),
(5, 'Erin', 'Tainan', '2025-01-10', 'active'),
(6, 'Frank', 'Taichung', '2024-12-15', 'active'),
(7, 'Grace', 'Hsinchu', '2025-01-18', 'active'),
(8, 'Henry', 'Kaohsiung', '2024-12-28', 'active'),
(9, 'Ivy', 'Taipei', '2025-02-01', 'active'),
(10, 'Jack', 'Tainan', '2024-12-30', 'active'),
(11, 'Mia', 'Taipei', '2025-02-15', 'active'),
(12, 'Leo', 'Taichung', '2025-03-01', 'active');

INSERT INTO categories (category_id, category_name) VALUES
(1, 'Laptop'),
(2, 'Accessory'),
(3, 'Phone'),
(4, 'HomeOffice'),
(5, 'Tablet'),
(6, 'Clearance');

INSERT INTO products (product_id, product_name, category_id, price, stock, is_active) VALUES
(101, 'ThinkPad X1', 1, 48000.00, 8, 1),
(102, 'MacBook Air', 1, 36000.00, 5, 1),
(103, 'USB-C Hub', 2, 1200.00, 30, 1),
(104, 'Mechanical Keyboard', 2, 3200.00, 25, 1),
(105, 'Wireless Mouse', 2, 900.00, 0, 1),
(106, 'iPhone Case', 3, 800.00, 40, 1),
(107, 'Android Phone', 3, 18000.00, 12, 1),
(108, 'Office Chair', 4, 7500.00, 6, 1),
(109, 'Standing Desk', 4, 15000.00, 3, 1),
(110, 'Laptop Sleeve', 2, 1500.00, 18, 0),
(111, 'Noise Cancelling Headphones', 2, 6800.00, 22, 1),
(112, 'Webcam Pro', 4, 2600.00, 28, 1),
(113, 'Tablet Pro', 5, 22000.00, 9, 1),
(114, '4K Monitor', 4, 12000.00, 15, 1),
(115, 'Old Router', 6, 2500.00, 50, 1),
(116, 'Legacy Dock', 6, 300.00, 10, 0);

INSERT INTO customer_orders (order_id, user_id, order_date, status, total_amount) VALUES
(1001, 1, '2025-01-10 10:00:00', 'paid', 49200.00),
(1002, 1, '2025-03-02 14:20:00', 'paid', 39200.00),
(1003, 1, '2025-04-10 09:30:00', 'paid', 8000.00),
(1004, 2, '2025-02-05 11:15:00', 'paid', 18000.00),
(1005, 2, '2025-04-05 16:40:00', 'pending', 12700.00),
(1006, 3, '2025-02-14 13:00:00', 'paid', 900.00),
(1007, 4, '2025-01-20 18:00:00', 'paid', 14400.00),
(1008, 4, '2025-03-18 12:10:00', 'cancelled', 12000.00),
(1009, 6, '2025-01-25 09:00:00', 'paid', 8700.00),
(1010, 6, '2025-02-01 10:30:00', 'paid', 900.00),
(1011, 6, '2025-02-07 20:00:00', 'paid', 900.00),
(1012, 8, '2025-03-22 15:00:00', 'paid', 22000.00),
(1013, 8, '2025-04-01 08:45:00', 'paid', 2400.00),
(1014, 9, '2025-04-12 19:20:00', 'paid', 15000.00),
(1015, 11, '2025-03-30 17:00:00', 'paid', 5000.00),
(1016, 12, '2025-04-08 11:50:00', 'paid', 3800.00);

INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
(1, 1001, 101, 1, 48000.00),
(2, 1001, 103, 1, 1200.00),
(3, 1002, 102, 1, 36000.00),
(4, 1002, 104, 1, 3200.00),
(5, 1003, 111, 1, 6800.00),
(6, 1003, 103, 1, 1200.00),
(7, 1004, 107, 1, 18000.00),
(8, 1005, 108, 1, 7500.00),
(9, 1005, 112, 2, 2600.00),
(10, 1006, 105, 1, 900.00),
(11, 1007, 104, 2, 3200.00),
(12, 1007, 103, 1, 1200.00),
(13, 1007, 111, 1, 6800.00),
(14, 1008, 114, 1, 12000.00),
(15, 1009, 108, 1, 7500.00),
(16, 1009, 103, 1, 1200.00),
(17, 1010, 105, 1, 900.00),
(18, 1011, 105, 1, 900.00),
(19, 1012, 113, 1, 22000.00),
(20, 1013, 103, 2, 1200.00),
(21, 1014, 109, 1, 15000.00),
(22, 1016, 103, 1, 1200.00),
(23, 1016, 112, 1, 2600.00);

INSERT INTO payments (payment_id, order_id, pay_time, amount, pay_status) VALUES
(1, 1001, '2025-01-10 10:05:00', 49200.00, 'success'),
(2, 1002, '2025-03-02 14:30:00', 39200.00, 'success'),
(3, 1003, '2025-04-10 09:35:00', 3000.00, 'success'),
(4, 1003, '2025-04-10 09:40:00', 5000.00, 'success'),
(5, 1004, '2025-02-05 11:20:00', 18000.00, 'success'),
(6, 1005, '2025-04-05 16:50:00', 2000.00, 'pending'),
(7, 1006, '2025-02-14 13:05:00', 900.00, 'success'),
(8, 1007, '2025-01-20 18:05:00', 10000.00, 'success'),
(9, 1007, '2025-01-20 18:10:00', 3000.00, 'success'),
(10, 1008, '2025-03-18 12:15:00', 12000.00, 'failed'),
(11, 1009, '2025-01-25 09:05:00', 8700.00, 'success'),
(12, 1010, '2025-02-01 10:35:00', 900.00, 'success'),
(13, 1011, '2025-02-07 20:05:00', 900.00, 'success'),
(14, 1012, '2025-03-22 15:05:00', 22000.00, 'success'),
(15, 1013, '2025-04-01 08:50:00', 2400.00, 'success'),
(16, 1014, '2025-04-12 19:25:00', 15000.00, 'success'),
(17, 1015, '2025-03-30 17:05:00', 5000.00, 'success'),
(18, 1016, '2025-04-08 11:55:00', 3800.00, 'success');

INSERT INTO support_tickets (ticket_id, user_id, created_at, closed_at, status, priority) VALUES
(1, 1, '2025-04-12 09:00:00', NULL, 'open', 'high'),
(2, 1, '2025-03-05 14:00:00', '2025-03-06 10:00:00', 'closed', 'medium'),
(3, 2, '2025-02-20 08:30:00', '2025-02-21 09:00:00', 'closed', 'low'),
(4, 6, '2025-04-10 10:00:00', NULL, 'open', 'medium'),
(5, 6, '2025-04-11 11:00:00', NULL, 'open', 'high'),
(6, 7, '2025-01-15 12:00:00', NULL, 'open', 'low'),
(7, 8, '2025-04-02 15:00:00', '2025-04-03 16:00:00', 'closed', 'medium'),
(8, 12, '2025-04-09 13:00:00', NULL, 'open', 'medium'),
(9, NULL, '2025-04-13 09:30:00', NULL, 'open', 'low');

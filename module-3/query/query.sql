-- Active: 1764398840767@@127.0.0.1@5432@mydatabase
CREATE TABLE customer_orders (
    order_id INT NOT NULL, -- ใช้ INT เพราะ order_id มาจาก SERIAL ในตารางหลัก
    order_total DECIMAL(10, 2) NOT NULL,
    order_date DATE NOT NULL,
    customer_id INT NOT NULL
);



-- --- Seed ข้อมูลสุ่ม 100,000 รายการสำหรับเดือนมกราคม 2023 ---
-- ข้อมูลจะถูกสร้างให้สอดคล้องกับเงื่อนไข WHERE ของ Query ต้นฉบับ
INSERT INTO customer_orders (order_id, order_total, order_date, customer_id)
SELECT
    s AS order_id, 
    (random() * 10000 + 50)::DECIMAL(10, 2) AS order_total, 
    ('2023-01-01'::DATE + (random() * 30)::int)::DATE AS order_date,
    (random() * 10000 + 50)::INT as customer_id
FROM generate_series(1, 100000) s; 

CREATE INDEX idx_customer_orders_date ON customer_orders (order_date);

EXPLAIN ANALYSE SELECT order_id, order_total
FROM customer_orders
WHERE order_date = '2023-01-01'
ORDER BY customer_id;

SELECT order_id, order_total
FROM customer_orders
WHERE order_date >= '2022-01-01';


SELECT p.product_name, SUM(oi.quantity * oi.price) AS total_sales
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
WHERE p.category = 'Electronics' -- กรองหมวดหมู่ก่อน Join
GROUP BY p.product_name
HAVING SUM(oi.quantity * oi.price) > 1000;



-- ถ้า order_date มี Index
EXPLAIN ANALYZE SELECT *
FROM customer_orders
WHERE order_date = '2023-01-01' 



-- ถ้า order_date มี Index
EXPLAIN ANALYZE 
SELECT *
FROM customer_orders
WHERE TO_CHAR(order_date, 'YYYY-MM-DD') = '2023-01-01';


CREATE INDEX idx_order_date_YYYY_MM_DD ON customer_orders (TO_CHAR(order_date, 'YYYY-MM-DD')); 

CREATE INDEX idx_order_date_YYYY_MM_DD ON customer_orders (TO_CHAR(order_date, 'YYYY-MM-DD'));


CREATE INDEX idx_orders_month_year ON customer_orders (TO_CHAR(order_timestamp, 'YYYY-MM'));
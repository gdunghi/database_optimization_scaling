Drop table if exists customers;
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name TEXT
);

-- สร้างข้อมูลลูกค้า 1000000 ราย
INSERT INTO customers (name)
SELECT 'Customer ' || i FROM generate_series(1, 1000000) i;



SELECT * FROM customers WHERE name = 'customer 999'; -- ไม่เจอ เพราะข้อมูลเป็น case sensitive
-- จะพบว่า ใช้ Seq scan แสดงว่ายังไม่มี index สำหรับ column name

SELECT * FROM customers WHERE lower(name) = 'customer 999'; -- เจอข้อมูล

EXPLAIN ANALYSE SELECT * FROM customers WHERE lower(name) = 'customer 999';
-- จะพบว่า ใช้ Seq scan แสดงว่ายังไม่มี index สำหรับ column name


CREATE INDEX idx_name ON customers (name);

-- query ดูอีกครั้ง
EXPLAIN ANALYSE SELECT * FROM customers WHERE lower(name) = 'customer 999'; 
-- พบว่า ยังใช้ Seq scan อยู่ แสดงว่า index ที่สร้างมาไม่ได้ถูกใช้งาน



--- สร้าง expression index
CREATE INDEX idx_lower_name ON customers (lower(name));

EXPLAIN ANALYSE SELECT * FROM customers WHERE lower(name) = 'customer 999'; 
-- จะพบว่าใช้ index scan แล้ว
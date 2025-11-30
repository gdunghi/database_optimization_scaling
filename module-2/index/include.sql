
Drop table if exists customers;
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name varchar(100),
    last_name varchar(100),
    age smallint
);

-- สร้างข้อมูลลูกค้า 1000000 ราย
INSERT INTO customers (name)
SELECT 'Customer ' || i FROM generate_series(1, 1000000) i;


CREATE INDEX idx_customer_name
ON customers (name);

EXPLAIN (ANALYSE,BUFFERS)  SELECT name FROM customers WHERE name = 'Customer 100000';
-- จะเห็นว่า ถ้าเราถึงแค่ name ใช้ Index Only Scan คือจะไม่วิ่งไปที่ table จริงเลยใช้ข้อมูลใน index เท่านั้น


EXPLAIN(ANALYSE,BUFFERS) SELECT name,age FROM customers WHERE name = 'Customer 100000';
-- จะเห็นว่า ถ้าเราถึง name กับ age ใช้ Index Scan คือใช้ index ในการหา record แล้ววิ่งกลับไปดึงข้อมูลที่ Table จริงอีกครั้ง เพื่อดึงข้อมูล age
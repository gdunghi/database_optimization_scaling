--- extension db Database client

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INT,
    amount NUMERIC,
    created_at TIMESTAMP
);


-- สร้างข้อมูลลูกค้า 10,000 ราย
INSERT INTO customers (name)
SELECT 'Customer ' || i FROM generate_series(1, 10000) i;

-- สร้างข้อมูล orders 1,000,000 รายการ
INSERT INTO orders (customer_id, amount, created_at)
SELECT (random()*10000)::INT, (random()*1000)::NUMERIC, NOW() - (random()*interval '100 days')
FROM generate_series(1, 1000000);


--- สร้าง Index
CREATE INDEX idx_orders_customer ON orders(customer_id);


EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE amount > 900;



EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE customer_id = 500;

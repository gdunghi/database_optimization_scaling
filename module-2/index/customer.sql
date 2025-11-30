CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name TEXT
);

INSERT INTO customers (id, name)
SELECT i,'Customer ' || i FROM generate_series(1, 20000) i;


CREATE TABLE customer_orders (
    order_id SERIAL PRIMARY KEY, 
    order_total DECIMAL(10, 2) NOT NULL,
    order_date DATE NOT NULL,
    customer_id INT NOT NULL
);


INSERT INTO customer_orders (order_id, order_total, order_date, customer_id)
SELECT
    s AS order_id, 
    (random() * 10000 + 50)::DECIMAL(10, 2) AS order_total, 
    ('2023-01-01'::DATE + (random() * 30)::int)::DATE AS order_date,
    (random() * 10000 + 50)::INT as customer_id
FROM generate_series(1, 5000000) s; 



--- unkonw
create index customer_orders_idx on customer_orders (customer_id);


EXPLAIN ANALYZE
SELECT c.name
FROM customers c
WHERE c.id IN (SELECT customer_id FROM customer_orders);


EXPLAIN ANALYZE
SELECT c.name
FROM customers c
WHERE EXISTS (SELECT 1 FROM customer_orders o WHERE o.customer_id = c.id);


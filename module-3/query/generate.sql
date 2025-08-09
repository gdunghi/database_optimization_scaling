CREATE TABLE orders_with_generated_date (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_timestamp TIMESTAMP NOT NULL
);

DROP table orders_with_generated_date;

ALTER table orders_with_generated_date add COLUMN order_date DATE GENERATED ALWAYS AS (order_timestamp::date) STORED;

drop index idx_order_date_fn;
CREATE INDEX idx_order_date_fn ON orders_with_generated_date ((order_timestamp::date));

CREATE INDEX idx_order_date ON orders_with_generated_date (order_timestamp);

DROP table  idx_order_date_fn;



INSERT INTO orders_with_generated_date (customer_id, order_timestamp)
SELECT
    (random() * 1000 + 1)::int AS customer_id,
    timestamp '2024-01-01 00:00:00' + (random() * interval '365 days') AS order_timestamp
FROM generate_series(1, 10000);



EXPLAIN ANALYZE SELECT * FROM orders_with_generated_date WHERE order_timestamp::date = DATE '2024-08-01';


EXPLAIN ANALYZE SELECT * FROM orders_with_generated_date WHERE order_date =  '2024-08-01';


SELECT * FROM orders_with_generated_date WHERE order_timestamp::date = DATE '2024-08-01';


CREATE INDEX idx_order_date ON orders_with_generated_date (order_date);
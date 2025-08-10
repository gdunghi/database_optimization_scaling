
DROP table if EXISTS ip_data;
CREATE TABLE ip_data (
    ip inet
);



INSERT INTO ip_data (ip)
SELECT
    (192 || '.' ||
     168 || '.' ||
     trunc(random() * 255)::int || '.' ||
     trunc(random() * 255)::int)::inet
FROM generate_series(1, 100000);

INSERT INTO ip_data (ip)
SELECT
    (10 || '.' ||
     0 || '.' ||
     trunc(random() * 255)::int || '.' ||
     trunc(random() * 255)::int)::inet
FROM generate_series(1, 100000);


INSERT INTO ip_data (ip)
SELECT
    (172 || '.' ||
     16 || '.' ||
     trunc(random() * 255)::int || '.' ||
     trunc(random() * 255)::int)::inet
FROM generate_series(1, 100000);


INSERT INTO ip_data (ip)
SELECT
    (172 || '.' ||
     31 || '.' ||
     trunc(random() * 255)::int || '.' ||
     trunc(random() * 255)::int)::inet
FROM generate_series(1, 100000);

CREATE INDEX idx_ip_spgist
ON ip_data
USING spgist (ip inet_ops);


EXPLAIN ANALYSE SELECT * FROM ip_data
WHERE ip << '192.168.0.0/16'
LIMIT 10;



EXPLAIN ANALYSE SELECT * FROM customers WHERE lower(name) = 'customer 999'; 



WITH recent_orders AS (
    SELECT order_id, customer_id, order_total
    FROM customer_orders
    WHERE order_date >= '2023-06-01'
),
high_value_recent_orders AS (
    SELECT customer_id, SUM(order_total) AS total_spent
    FROM recent_orders
    GROUP BY customer_id
    HAVING SUM(order_total) > 500
)

SELECT c.customer_name, hvo.total_spent
FROM customer c
JOIN (
    SELECT customer_id, SUM(order_total) AS total_spent
    FROM recent_orders
    GROUP BY customer_id
    HAVING SUM(order_total) > 500
) hvo ON c.customer_id = hvo.customer_id;

)

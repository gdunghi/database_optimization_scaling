WITH recent_orders AS (
    SELECT order_id, customer_id, order_total
    FROM customer_orders
    WHERE order_date >= '2023-01-01'
),
high_value_recent_orders AS (
    SELECT customer_id, SUM(order_total) AS total_spent
    FROM recent_orders
    GROUP BY customer_id
    HAVING SUM(order_total) > 500
)
SELECT c.name, hvo.total_spent
FROM customers c
JOIN high_value_recent_orders hvo ON c.id = hvo.customer_id;


SELECT order_id, customer_id, order_total ,order_date
    FROM customer_orders co INNER join customers c on c.id = co.customer_id
    WHERE order_date >= '2023-01-01';


SELECT * from customers ORDER BY id desc;
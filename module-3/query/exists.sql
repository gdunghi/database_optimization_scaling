CREATE TABLE customer_7 (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL
);

CREATE TABLE customer_orders_7 (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL
);

drop table customer_7;
drop table customer_orders_7;

TRUNCATE table customer_7;
TRUNCATE table customer_orders_7;

SELECT * FROM customer_7;
SELECT * FROM customer_orders_7;


INSERT INTO customer_7 (customer_id, customer_name)
SELECT s, 'Customer ' || i
FROM generate_series(1, 1000000) AS s(i);


INSERT INTO customer_orders_7 (customer_id)
SELECT (random() * 1000000 + 1)::int
FROM generate_series(1, 2000000);


CREATE INDEX idx_customer_orders_7_customer_id ON customer_orders_7(customer_id);

ANALYSE customer_7;
ANALYSE customer_orders_7;

SELECT customer_id, count(1) FROM customer_orders_7 GROUP BY customer_id ORDER BY count(1) desc;;

DISCARD ALL;
EXPLAIN (ANALYSE,BUFFERS) SELECT c.customer_name
FROM customer_7 c
WHERE c.customer_id IN (SELECT customer_id FROM customer_orders_7)
    -- and c.customer_id = 7261;
    ;
Merge Semi Join  (cost=7.00..106291.51 rows=675426 width=15) (actual time=6.127..489.927 rows=864868 loops=1)
  Merge Cond: (c.customer_id = customer_orders_7.customer_id)
  Buffers: shared hit=9259 read=3942
  ->  Index Scan using customer_7_pkey on customer_7 c  (cost=0.42..32353.42 rows=1000000 width=19) (actual time=0.139..159.320 rows=1000000 loops=1)
        Buffers: shared hit=6385 read=2720
  ->  Index Only Scan using idx_customer_orders_7_customer_id on customer_orders_7  (cost=0.43..46440.43 rows=2000000 width=4) (actual time=0.023..140.154 rows=1999998 loops=1)
        Heap Fetches: 0
        Buffers: shared hit=2874 read=1222
Planning:
  Buffers: shared hit=172 read=27
Planning Time: 6.238 ms
JIT:
  Functions: 5
  Options: Inlining false, Optimization false, Expressions true, Deforming true
  Timing: Generation 0.271 ms (Deform 0.118 ms), Inlining 0.000 ms, Optimization 0.420 ms, Emission 5.531 ms, Total 6.223 ms
Execution Time: 549.333 ms


DISCARD ALL;

EXPLAIN (ANALYSE,BUFFERS) SELECT c.customer_name
FROM customer_7 c
WHERE EXISTS (SELECT 1 FROM customer_orders_7 o WHERE o.customer_id = c.customer_id);
-- and c.customer_id = 7261;
Merge Semi Join  (cost=7.00..106291.51 rows=675426 width=15) (actual time=5.342..505.003 rows=864868 loops=1)
  Merge Cond: (c.customer_id = o.customer_id)
  Buffers: shared hit=306 read=12895 written=239
  ->  Index Scan using customer_7_pkey on customer_7 c  (cost=0.42..32353.42 rows=1000000 width=19) (actual time=0.013..140.396 rows=1000000 loops=1)
        Buffers: shared hit=302 read=8803 written=165
  ->  Index Only Scan using idx_customer_orders_7_customer_id on customer_orders_7 o  (cost=0.43..46440.43 rows=2000000 width=4) (actual time=0.036..146.827 rows=1999998 loops=1)
        Heap Fetches: 0
        Buffers: shared hit=4 read=4092 written=74
Planning:
  Buffers: shared hit=14 read=2
Planning Time: 0.295 ms
JIT:
  Functions: 5
  Options: Inlining false, Optimization false, Expressions true, Deforming true
  Timing: Generation 0.341 ms (Deform 0.151 ms), Inlining 0.000 ms, Optimization 0.360 ms, Emission 4.921 ms, Total 5.622 ms
Execution Time: 528.662 ms


SELECT count(1) FROM customer_orders_7;



EXPLAIN ANALYZE SELECT count(c.customer_name)
FROM customer_7 c
WHERE EXISTS (SELECT 1 FROM customer_orders_7 o WHERE o.customer_id = c.customer_id)
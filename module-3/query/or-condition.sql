

-- Or condition


-- 1. สร้างตาราง customers (ถ้ายังไม่มี)
--    เพิ่มคอลัมน์ registration_date และ birth_date
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    registration_date DATE, 
    birth_date DATE      
);

TRUNCATE table customers;

INSERT INTO customers (name, email, registration_date, birth_date)
SELECT
    CASE
        WHEN s % 5=0 THEN 'Alis'
        WHEN s % 4=0 THEN 'Bob'
        WHEN s % 3=0 THEN 'John'
        WHEN s % 2=0 THEN 'Pareena'
        ELSE 'Customer ' || LPAD(s::text, 6, '0')
    END AS name,
    'user' || LPAD(s::text, 6, '0') || '@example.com' AS email,
    CASE
        WHEN random() < 0.5 THEN ('2023-01-01'::DATE + (random() * 365)::int)::DATE 
        ELSE ('2022-01-01'::DATE + (random() * 365)::int)::DATE 
    END AS registration_date,

    CASE
        WHEN random() < 0.001 THEN '2023-01-01'::DATE
        ELSE ('1980-01-01'::DATE + (random() * 14610)::int)::DATE 
    END AS birth_date
FROM generate_series(1, 10000000) s; -- สร้าง 10,000,000 รายการ


-- ตรวจสอบจำนวนรายการทั้งหมด
SELECT COUNT(*) FROM customers;

-- ตรวจสอบข้อมูลตัวอย่าง 10 แถวแรก
SELECT customer_id, name, email, registration_date, birth_date FROM customers LIMIT 10;


create index customer_name_idx on customers (name);
create index customer_birth_date_idx on customers ( birth_date);
create index customer_registration_date_idx on customers ( registration_date);

DROP index customer_name_idx;
DROP index customer_birth_date_idx;
DROP index customer_registration_date_idx;

DROP index registration_search_idx;

-- 6037689
EXPLAIN ANALYSE 
SELECT *
FROM customers
WHERE registration_date = '2023-01-01' and (
     name = 'Alis'
    OR birth_date = '2023-01-01');





EXPLAIN ANALYSE 
SELECT c.name
    FROM customers c
WHERE c.registration_date = '2023-01-01' 

UNION

SELECT c.name
    FROM customers c
WHERE c.name = 'Alis'

UNION	

SELECT c.name
    FROM customers c
WHERE c.birth_date = '2023-01-01';

-- 2018952
SELECT count(1) from (
    SELECT c.*
    FROM customers c
WHERE c.registration_date = '2023-01-01' 

UNION

SELECT c.*
    FROM customers c
WHERE c.name = 'Alis'

UNION	

SELECT c.*
    FROM customers c
WHERE c.birth_date = '2023-01-01'
);

--2018952
SELECT count(1)
FROM customers
WHERE (registration_date = '2023-01-01'
    OR name = 'Alis'
    OR birth_date = '2023-01-01');


Unique  (cost=6036328.16..6071535.35 rows=7041438 width=516) (actual time=6408.296..7555.907 rows=764208 loops=1)
  ->  Sort  (cost=6036328.16..6053931.76 rows=7041438 width=516) (actual time=6408.294..7225.014 rows=7014622 loops=1)
        Sort Key: c.name
        Sort Method: external merge  Disk: 77208kB
        ->  Append  (cost=0.00..325696.77 rows=7041438 width=516) (actual time=47.546..1469.558 rows=7014622 loops=1)
              ->  Seq Scan on customers c  (cost=0.00..215091.00 rows=5059771 width=8) (actual time=47.545..911.566 rows=5004705 loops=1)
                    Filter: (registration_date >= '2023-01-01'::date)
                    Rows Removed by Filter: 4995295
              ->  Index Only Scan using customer_name_idx on customers c_1  (cost=0.43..44215.11 rows=1970667 width=8) (actual time=1.334..114.951 rows=2000000 loops=1)
                    Index Cond: (name = 'Alis'::text)
                    Heap Fetches: 0
              ->  Bitmap Heap Scan on customers c_2  (cost=125.69..31183.47 rows=11000 width=8) (actual time=2.444..89.079 rows=9917 loops=1)
                    Recheck Cond: (birth_date = '2023-01-01'::date)
                    Heap Blocks: exact=9402
                    ->  Bitmap Index Scan on customer_birth_date_idx  (cost=0.00..122.94 rows=11000 width=0) (actual time=1.541..1.541 rows=9917 loops=1)
                          Index Cond: (birth_date = '2023-01-01'::date)
Planning Time: 0.234 ms
JIT:
  Functions: 10
  Options: Inlining true, Optimization true, Expressions true, Deforming true
  Timing: Generation 0.929 ms (Deform 0.297 ms), Inlining 11.326 ms, Optimization 20.448 ms, Emission 15.772 ms, Total 48.476 ms
Execution Time: 7576.296 ms
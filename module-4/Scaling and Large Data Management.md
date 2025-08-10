# Scaling and Large Data Management

### initial Database
```bash
    docker compose up -d
```

### 1. Range Partitioning

สมมติว่าเรามีตาราง orders ที่เก็บข้อมูลยอดขายรายวัน และต้องการแบ่งตามปีและเดือน

```sql

-- สร้างตารางหลัก (Parent Table) ที่มีการแบ่งพาร์ทิชันตามวันที่
CREATE TABLE orders (
    order_id SERIAL,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_total DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

-- สร้างพาร์ทิชันย่อยสำหรับแต่ละเดือนของปี 2023 และปี 2024
-- พาร์ทิชันสำหรับมกราคม 2023
CREATE TABLE orders_2023_01 PARTITION OF orders
FOR VALUES FROM ('2023-01-01') TO ('2023-02-01');

-- พาร์ทิชันสำหรับกุมภาพันธ์ 2023
CREATE TABLE orders_2023_02 PARTITION OF orders
FOR VALUES FROM ('2023-02-01') TO ('2023-03-01');

-- พาร์ทิชันสำหรับมีนาคม 2023
CREATE TABLE orders_2023_03 PARTITION OF orders
FOR VALUES FROM ('2023-03-01') TO ('2023-04-01');

-- พาร์ทิชันสำหรับอนาคต (เพื่อรองรับข้อมูลใหม่)
CREATE TABLE orders_default PARTITION OF orders DEFAULT;

-- Seed ข้อมูลตัวอย่าง 1M
INSERT INTO orders (customer_id, order_date, order_total, status)
SELECT
    (random() * 100000)::int + 1 AS customer_id, -- customer_id ระหว่าง 1 ถึง 100,000
    ('2023-01-01'::DATE + (random() * 120)::int)::DATE AS order_date, -- วันที่ระหว่าง 2023-01-01 + 120 วัน
    (random() * 10000 + 50)::DECIMAL(10, 2) AS order_total, -- order_total ระหว่าง 50 ถึง 10050
    CASE floor(random() * 3)
        WHEN 0 THEN 'Completed'
        WHEN 1 THEN 'Pending'
        ELSE 'Cancelled'
    END AS status
FROM generate_series(1, 1000000); -- 

-- ตรวจสอบว่าข้อมูลถูกเก็บในพาร์ทิชันใด
SELECT * FROM orders_2023_01;
SELECT * FROM orders_2023_02;
SELECT * FROM orders_2023_03;
SELECT * FROM orders_default;

SELECT * FROM orders; -- จะแสดงค่า order ทั้งหมด
```

ต้องการ Query ข้อมูลยอดขายเฉพาะเดือน 01-02  สแกนเฉพาะพาร์ติชัน  orders_2023_01,orders_2023_02 เท่านั้น 

```sql
EXPLAIN ANALYSE SELECT * FROM orders WHERE order_date BETWEEN '2023-01-01' and '2023-02-10';

Append  (cost=0.00..33.82 rows=4 width=146) (actual time=0.020..0.030 rows=4 loops=1)
  ->  Seq Scan on orders_2023_01 orders_1  (cost=0.00..16.90 rows=2 width=146) (actual time=0.020..0.021 rows=3 loops=1)
        Filter: ((order_date >= '2023-01-01'::date) AND (order_date <= '2023-02-10'::date))
  ->  Seq Scan on orders_2023_02 orders_2  (cost=0.00..16.90 rows=2 width=146) (actual time=0.008..0.008 rows=1 loops=1)
        Filter: ((order_date >= '2023-01-01'::date) AND (order_date <= '2023-02-10'::date))
        Rows Removed by Filter: 1
Planning Time: 0.146 ms
Execution Time: 0.045 ms
```

ต้องการเฉพาะเดือน มกราคา 2023

```sql
EXPLAIN ANALYSE SELECT * FROM orders WHERE order_date BETWEEN '2023-01-01' and '2023-01-31';

Seq Scan on orders_2023_01 orders  (cost=0.00..16.90 rows=2 width=146) (actual time=0.018..0.021 rows=3 loops=1)
  Filter: ((order_date >= '2023-01-01'::date) AND (order_date <= '2023-01-31'::date))
Planning Time: 0.156 ms
Execution Time: 0.035 ms
```

2. List Partitioning 
สมมติว่าเรามีตาราง `user_accounts` และต้องการแบ่งตามประเทศของผู้ใช้

```sql
-- สร้างตารางหลัก
CREATE TABLE user_accounts (
    user_id SERIAL ,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL,
    registration_date DATE,
    PRIMARY KEY (user_id, country_code)
) PARTITION BY LIST (country_code); -- กำหนด Partition Key เป็น country_code

-- สร้างพาร์ติชันย่อย
CREATE TABLE user_accounts_th PARTITION OF user_accounts
    FOR VALUES IN ('TH'); -- ผู้ใช้จากประเทศไทย

CREATE TABLE user_accounts_us_ca PARTITION OF user_accounts
    FOR VALUES IN ('US', 'CA'); -- ผู้ใช้จากสหรัฐอเมริกาและแคนาดา

CREATE TABLE user_accounts_eu PARTITION OF user_accounts
    FOR VALUES IN ('DE', 'FR', 'GB', 'IT'); -- ผู้ใช้จากบางประเทศในยุโรป

-- พาร์ติชันสำหรับค่าอื่นๆ ที่ไม่ตรงกับรายการที่กำหนด
CREATE TABLE user_accounts_other PARTITION OF user_accounts DEFAULT;

INSERT INTO user_accounts (username, email, country_code, registration_date)
SELECT
    'user_' || LPAD(s::text, 5, '0') AS username, -- สร้าง username เช่น user_00001
    'user' || LPAD(s::text, 5, '0') || '@example.com' AS email, -- สร้าง email
    CASE floor(random() * 8) -- สุ่มค่าเพื่อกระจายไปตาม country_code ที่กำหนด
        WHEN 0 THEN 'TH'
        WHEN 1 THEN 'US'
        WHEN 2 THEN 'CA'
        WHEN 3 THEN 'DE'
        WHEN 4 THEN 'FR'
        WHEN 5 THEN 'GB'
        WHEN 6 THEN 'IT'
        ELSE 'JP' *-- ค่าอื่นๆ ที่จะไปอยู่ใน user_accounts_other*
        END AS country_code,
    ('2022-01-01'::DATE + (random() * 730)::int)::DATE AS registration_date -- วันที่ระหว่าง 2022-01-01 ถึง 2023-12-31
FROM generate_series(1, 10000) s; -- สร้าง 10,000 รายการ

-- --- ตรวจสอบจำนวนรายการในแต่ละพาร์ติชัน (อาจใช้เวลานานสำหรับข้อมูลจำนวนมาก) ---
SELECT 'user_accounts_th' AS partition_name, COUNT(*) FROM user_accounts_th UNION ALL
SELECT 'user_accounts_us_ca' AS partition_name, COUNT(*) FROM user_accounts_us_ca UNION ALL
SELECT 'user_accounts_eu' AS partition_name, COUNT(*) FROM user_accounts_eu UNION ALL
SELECT 'user_accounts_other' AS partition_name, COUNT(*) FROM user_accounts_other;

-- --- ตรวจสอบจำนวนรวมทั้งหมด ---
SELECT COUNT(*) FROM user_accounts;
```

ต้องการ Query หาผู้ใช้จากประเทศไทย (`WHERE country_code = 'TH'`) ฐานข้อมูลจะสแกนเฉพาะพาร์ติชัน `user_accounts_th` เท่านั้น

```sql
explain analyse select * from user_accounts where country_code = 'TH';

Seq Scan on user_accounts_th user_accounts  (cost=0.00..27.27 rows=1222 width=44) (actual time=0.026..0.274 rows=1222 loops=1)
  Filter: (country_code = 'TH'::bpchar)
Planning Time: 1.259 ms
Execution Time: 0.393 ms
```

3. Hash Partitioning 
สมมติว่าเรามีตาราง `large_events` ที่มีข้อมูลจำนวนมาก และต้องการกระจายข้อมูลอย่างสม่ำเสมอโดยใช้ `event_id`

```sql
-- สร้างตารางหลัก
CREATE TABLE large_events (
    event_id UUID , -- UUID เป็นตัวอย่างของ ID ที่กระจายตัว
    event_type VARCHAR(50) NOT NULL,
    event_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    payload JSONB
) PARTITION BY HASH (event_id); -- กำหนด Partition Key เป็น event_id

-- สร้างพาร์ติชันย่อย (จำนวนพาร์ติชันที่กำหนดจะกระจายข้อมูลอย่างสม่ำเสมอ)
CREATE TABLE large_events_p0 PARTITION OF large_events FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE large_events_p1 PARTITION OF large_events FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE large_events_p2 PARTITION OF large_events FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE large_events_p3 PARTITION OF large_events FOR VALUES WITH (MODULUS 4, REMAINDER 3);

-- --- Seed ข้อมูลสุ่ม 10,000 รายการ ---

INSERT INTO large_events (event_id, event_type, event_timestamp, payload)
SELECT
    gen_random_uuid() AS event_id, -- สร้าง UUID แบบสุ่ม
    CASE floor(random() * 4) -- สุ่มประเภท Event
        WHEN 0 THEN 'LOGIN'
        WHEN 1 THEN 'LOGOUT'
        WHEN 2 THEN 'PURCHASE'
        ELSE 'VIEW_PRODUCT'
        END AS event_type,
    NOW() - (random() * INTERVAL '30 days') AS event_timestamp, -- สุ่ม timestamp ในช่วง 30 วันที่ผ่านมา
    jsonb_build_object( -- สร้าง JSONB payload แบบสุ่ม
            'user_id', floor(random() * 10000)::int + 1,
            'session_id', md5(random()::text),
            'value', (random() * 1000)::int,
            'is_success', (random() > 0.5)
    ) AS payload
FROM generate_series(1, 10000) s; -- สร้าง 10,000 รายการ

-- --- ตรวจสอบจำนวนรายการในแต่ละพาร์ติชัน ---
-- เนื่องจากเป็น Hash Partitioning ข้อมูลควรจะกระจายตัวค่อนข้างสม่ำเสมอ
SELECT 'large_events_p0' AS partition_name, COUNT(*) FROM large_events_p0 UNION ALL
SELECT 'large_events_p1' AS partition_name, COUNT(*) FROM large_events_p1 UNION ALL
SELECT 'large_events_p2' AS partition_name, COUNT(*) FROM large_events_p2 UNION ALL
SELECT 'large_events_p3' AS partition_name, COUNT(*) FROM large_events_p3;

-- --- ตรวจสอบจำนวนรวมทั้งหมด ---
SELECT COUNT(*) FROM large_events;
```

- **การจัดการพาร์ทิชัน:**
    - DETACH
        
        
        ```sql
        -- ถอด table ออกจาก partition
        ALTER TABLE orders DETACH PARTITION orders_2023_01;
        ```
        
    - ATTACH
        
        ```sql
        
        -- นำ table กลับคืน partition
        ALTER TABLE orders ATTACH PARTITION orders_2023_01
            FOR VALUES FROM ('2023-01-01') TO ('2023-02-01');
        ```
        
    
    - Index for partition table
        
        ```sql
        
        -- --- ขั้นตอนการสร้าง Index เพิ่มเติม (เช่น บน customer_id) ---
        
        -- 1. สร้าง Index บนตารางแม่ (Parent Table) โดยใช้ ON ONLY
        --    Index นี้จะถูกสร้างขึ้น แต่จะถูกทำเครื่องหมายว่า 'invalid' และยังไม่ถูกนำไปใช้กับพาร์ทิชันย่อย

        CREATE INDEX idx_orders_customer_id ON ONLY orders (customer_id);
        
        -- 2. สร้าง Index บนแต่ละพาร์ทิชันย่อยโดยใช้ CONCURRENTLY
        --    วิธีนี้ช่วยให้การสร้าง Index ไม่บล็อกการทำงานของตาราง
        
        CREATE INDEX CONCURRENTLY idx_orders_2023_01_customer_id ON orders_2023_01 (customer_id);
        CREATE INDEX CONCURRENTLY idx_orders_2023_02_customer_id ON orders_2023_02 (customer_id);
        CREATE INDEX CONCURRENTLY idx_orders_2023_03_customer_id ON orders_2023_03 (customer_id);
        CREATE INDEX CONCURRENTLY idx_orders_default_customer_id ON orders_default (customer_id);
        
        -- 3. แนบ Index ของพาร์ทิชันย่อยเข้ากับ Index บนตารางแม่
        --    เมื่อแนบ Index ของพาร์ทิชันย่อยทั้งหมดแล้ว Index บนตารางแม่จะถูกทำเครื่องหมายว่า 'valid' โดยอัตโนมัติ
        
        ALTER INDEX idx_orders_customer_id ATTACH PARTITION idx_orders_2023_01_customer_id;
        ALTER INDEX idx_orders_customer_id ATTACH PARTITION idx_orders_2023_02_customer_id;
        ALTER INDEX idx_orders_customer_id ATTACH PARTITION idx_orders_2023_03_customer_id;
        ALTER INDEX idx_orders_customer_id ATTACH PARTITION idx_orders_default_customer_id;
        ```
        
    
    - Alter table
        
        หากต้องการเพิ่มคอลัมน์ `delivery_address` (TEXT) ลงในตาราง `orders`
        
        ```sql
        ALTER TABLE orders
        ADD COLUMN delivery_address TEXT;
        ```
        
        **ผลลัพธ์:**
        
        - คอลัมน์ `delivery_address` จะถูกเพิ่มลงในตาราง `orders` (ตารางแม่)
        - คอลัมน์ `delivery_address` จะถูกเพิ่มลงในพาร์ทิชันย่อยทั้งหมดโดยอัตโนมัติ เช่น `orders_2023_01`, `orders_2023_02`, `orders_default` ฯลฯ
        - ข้อมูลที่มีอยู่เดิมในคอลัมน์นี้ในทุกพาร์ทิชันจะถูกตั้งค่าเป็น `NULL` (หากไม่ได้ระบุ `DEFAULT` value)
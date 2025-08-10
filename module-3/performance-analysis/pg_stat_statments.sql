--- create extension
CREATE EXTENSION pg_stat_statements;


-- สร้างตาราง product_logs
CREATE TABLE product_logs (
    log_id BIGSERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_id INT,
    details JSONB
);

-- สร้าง Index บน product_id เพื่อการค้นหาที่เร็วขึ้น
CREATE INDEX idx_product_logs_product_id ON product_logs (product_id);

-- สร้าง Index บน event_timestamp เพื่อการค้นหาตามช่วงเวลา
CREATE INDEX idx_product_logs_timestamp ON product_logs (event_timestamp);

-- --- Seed ข้อมูลสุ่ม 10,000,000 รายการ ---
-- การ INSERT ข้อมูลจำนวนมากนี้อาจใช้เวลาสักครู่
INSERT INTO product_logs (product_id, event_type, user_id, details, event_timestamp)
SELECT
    (random() * 100000)::int + 1 AS product_id, -- product_id ระหว่าง 1 ถึง 100,000
    CASE floor(random() * 4)
        WHEN 0 THEN 'VIEW'
        WHEN 1 THEN 'ADD_TO_CART'
        WHEN 2 THEN 'PURCHASE'
        ELSE 'WISHLIST'
    END AS event_type,
    (random() * 50000)::int + 1 AS user_id, -- user_id ระหว่าง 1 ถึง 50,000
    jsonb_build_object(
        'browser', CASE floor(random() * 3) WHEN 0 THEN 'Chrome' WHEN 1 THEN 'Firefox' ELSE 'Safari' END,
        'os', CASE floor(random() * 2) WHEN 0 THEN 'Windows' ELSE 'macOS' END,
        'duration_ms', (random() * 5000)::int
    ) AS details,
    ('2024-01-01'::DATE + (random() * 365)::int)::DATE AS  event_timestamp
FROM generate_series(1, 10000000); -- สร้าง 10,000,000 รายการ

-- ตรวจสอบจำนวนรายการทั้งหมด
SELECT COUNT(*) FROM product_logs;


SELECT * FROM product_logs WHERE event_type LIKE 'UNKNOWN%';


SELECT log_id, event_type, event_timestamp FROM product_logs WHERE product_id = 12345;

SELECT COUNT(*) FROM product_logs WHERE event_timestamp BETWEEN '2024-06-01' AND '2024-06-02';

UPDATE product_logs SET details = jsonb_set(details, '{is_processed}', 'true') WHERE event_type = 'VIEW' AND log_id % 10 = 0;


SELECT count(*) from (
    SELECT * FROM product_logs  order by user_id desc
);


SELECT
    query,
    calls,
    total_exec_time AS total_time_ms,
    mean_exec_time AS avg_time_ms,
    shared_blks_hit,
    shared_blks_read,
    local_blks_hit,
    local_blks_read,
    shared_blks_written,
    local_blks_written,
    temp_blks_read,
    temp_blks_written
FROM
    pg_stat_statements
ORDER BY
    (shared_blks_read + local_blks_read + temp_blks_read) DESC -- เรียงตามการอ่านดิสก์รวม
LIMIT 10;


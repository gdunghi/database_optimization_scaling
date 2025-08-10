### ขั้นตอนที่ 1: ตั้งค่า PostgreSQL เพื่อเปิดใช้งาน `pg_stat_statements`

วิธีเปิดการใช้งาน

1. **แก้ไขไฟล์ `postgresql.conf`:**
    
    ```bash
    docker exec -it performance-analysis-db-1 bash
    
    echo "shared_preload_libraries = 'pg_stat_statements'" >> /var/lib/postgresql/data/postgresql.conf
    echo "pg_stat_statements.track = all" >> /var/lib/postgresql/data/postgresql.conf
    
    exit
    docker compose restart
    ```
    postgresql.conf ที่ได้
    ```text
    shared_preload_libraries = 'pg_stat_statements'
    pg_stat_statements.track = all # สามารถเปลี่ยนเป็น 'top' เพื่อลดโหลดได้
    
    ```

    
2. **สร้าง Extension ในฐานข้อมูล:**
เชื่อมต่อกับฐานข้อมูลที่คุณต้องการใช้สำหรับ Lab นี้ (เช่น `psql -U your_user -d your_database` หรือ ใช้ vs code) แล้วรันคำสั่ง:
    
    ```sql
    CREATE EXTENSION pg_stat_statements;
    
    ```
    

### ขั้นตอนที่ 2: สร้างตารางและใส่ข้อมูล

เราจะสร้างตาราง `product_logs` ที่มีข้อมูลจำนวนมาก เพื่อจำลอง Workload ที่มีการอ่าน/เขียนข้อมูลเยอะๆ

```sql
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

```

### ขั้นตอนที่ 3: รัน Query ตัวอย่างเพื่อสร้างสถิติ I/O

หลังจากใส่ข้อมูลแล้ว ให้รัน Query เหล่านี้ซ้ำๆ กันหลายครั้ง เพื่อให้ `pg_stat_statements` เก็บสถิติ:

**Query A: Full Scan (High I/O Read)**

- Query นี้จะอ่านข้อมูลทั้งหมดในตารางเพื่อหา `event_type` ที่ไม่ตรงกับค่าทั่วไป ซึ่งจะทำให้เกิดการอ่านดิสก์จำนวนมาก

```sql
SELECT * FROM product_logs WHERE event_type LIKE 'UNKNOWN%';
```

**Query B: Index Scan (Low I/O Read)**

- Query นี้จะใช้ Index บน `product_id` เพื่อค้นหาข้อมูลเฉพาะ ทำให้มีการอ่านดิสก์น้อยลง

```sql
SELECT log_id, event_type, event_timestamp FROM product_logs WHERE product_id = 12345;
```

**Query C: Range Scan on Indexed Timestamp (Moderate I/O Read)**

- Query นี้จะใช้ Index บน `event_timestamp` เพื่อค้นหาข้อมูลในช่วงเวลาหนึ่ง

```sql
SELECT COUNT(*) FROM product_logs WHERE event_timestamp BETWEEN '2024-06-01' AND '2024-06-02';
```

**Query D: Update Operation (High I/O Write)**

- Query นี้จะทำการอัปเดตข้อมูลจำนวนมาก ซึ่งจะทำให้เกิดการเขียนลงดิสก์ (WAL และ Data Files)

```sql
UPDATE product_logs SET details = jsonb_set(details, '{is_processed}', 'true') WHERE event_type = 'VIEW' AND log_id % 10 = 0;
```

**Query E: Count data ขนาดใหญ่ (อาจมี Temp Files และ I/O สูง)**

- Query นี้จะทำการรวมข้อมูลที่ซับซ้อน ซึ่งอาจทำให้เกิดการใช้ `work_mem` และอาจ Spill to Disk หาก `work_mem` ไม่พอ

```sql
SELECT count(*) from (
    SELECT * FROM product_logs  order by user_id desc
);
```

**แนะนำให้รันแต่ละ Query ซ้ำๆ กันอย่างน้อย 5-10 ครั้ง** เพื่อให้ `pg_stat_statements` เก็บสถิติที่น่าเชื่อถือ

### ขั้นตอนที่ 4: ตรวจสอบสถิติใน `pg_stat_statements`

หลังจากรัน Query ตัวอย่างไปแล้ว คุณสามารถใช้ Query ที่เราได้พูดคุยกันเพื่อดูสถิติ I/O:

```sql
SELECT
    query, -- คำสั่ง SQL ที่เคยถูกรัน
    calls, --- จำนวนครั้งที่ query นั้นถูกรัน
    total_exec_time AS total_time_ms,  --- เวลารวม (มิลลิวินาที) ที่ใช้รัน query นี้ทั้งหมด
    mean_exec_time AS avg_time_ms, --- เวลาเฉลี่ยต่อการรัน 1 ครั้ง
    shared_blks_hit, --- จำนวน block ที่อ่านจาก shared buffer cache (ไม่ต้องอ่านจากดิสก์)
    shared_blks_read, --- จำนวน block ที่อ่านจากดิสก์ (หรือ OS cache) ของตาราง/อินเด็กซ์ที่แชร์กัน
    shared_blks_written, --- block ที่เขียนลงดิสก์จาก shared buffer
    local_blks_hit, --- block ที่อ่านจาก local buffer cache (ใช้ใน temporary table หรือ unlogged table)
    local_blks_read, --- block ที่อ่านจากดิสก์สำหรับ local buffer
    local_blks_written, --- block ที่เขียนลงดิสก์จาก local buffer
    temp_blks_read, --- block ชั่วคราวที่อ่านจากดิสก์ (เช่นจาก temp file ของการ sort/join ขนาดใหญ่)
    temp_blks_written --- block ชั่วคราวที่เขียนไปยังดิสก์
FROM
    pg_stat_statements
ORDER BY
    (shared_blks_read + local_blks_read + temp_blks_read) DESC -- เรียงตามการอ่านดิสก์รวม
LIMIT 10;

```

ดูสถิติในมุมของการใช้เวลา และความถี่

```sql
SELECT round((100 * total_exec_time /
    sum(total_exec_time)
    OVER ())::numeric, 2) percent,
    round(total_exec_time::numeric, 2) AS total,
    calls,
    round(mean_exec_time::numeric, 2) AS mean,
    substring(query, 1, 100)
FROM  pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;
```

**ผลลัพธ์ที่คุณคาดว่าจะเห็น:**

- **Query A (`UNKNOWN%`)**: ควรมีค่า shared_blks_read สูง
- **Query B (`product_id = 12345`)**: ควรมีค่า shared_blks_hit สูง และ shared_blks_read ต่ำ (เพราะใช้ Index และข้อมูลอาจอยู่ใน Cache)
- **Query D (`UPDATE`)**: ควรมีค่า shared_blks_written สูง เพราะมีการ เขียนข้อมูลลง disk
- **Query E (Count)**: shared_blks_read สูง และ temp_blks_read,temp_blks_written หาก work_mem ไม่เพียงพอ

สามารถรีเซ็ตสถิติได้ตลอดเวลาด้วย `SELECT pg_stat_statements_reset();` ก่อนที่จะรันชุด Query ใหม่เพื่อการทดลองที่แม่นยำขึ้นครับ

*** การที่ใช้ pg_stat_statements นั้นมี over head เพิ่มมากขึ้นจากปกติเล็ก  การเปิดปิดเป็นช่วง ๆ เพื่อทำการเก็บสถิติและนำไปทำการ tunning  เป็นทางเลือกที่ดี ***
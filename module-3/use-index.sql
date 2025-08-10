
CREATE TABLE customer_orders (
    order_id INT NOT NULL, -- ใช้ INT เพราะ order_id มาจาก SERIAL ในตารางหลัก
    order_total DECIMAL(10, 2) NOT NULL,
    order_date DATE NOT NULL,
    customer_id INT NOT NULL
);


-- --- Seed ข้อมูลสุ่ม 100,000 รายการสำหรับเดือนมกราคม 2023 ---
-- ข้อมูลจะถูกสร้างให้สอดคล้องกับเงื่อนไข WHERE ของ Query ต้นฉบับ
INSERT INTO customer_orders (order_id, order_total, order_date, customer_id)
SELECT
    s AS order_id, -- ใช้ generate_series เป็น order_id แบบง่ายๆ
    (random() * 10000 + 50)::DECIMAL(10, 2) AS order_total, -- order_total ระหว่าง 50 ถึง 10050
    -- สุ่มวันที่ให้อยู่ในช่วง 2023-01-01 ถึง 2023-01-31
    ('2023-01-01'::DATE + (random() * 30)::int)::DATE AS order_date,
    (random() * 10000 + 50)::INT as customer_id
FROM generate_series(1, 100000) s; -- สร้าง 100,000 รายการ

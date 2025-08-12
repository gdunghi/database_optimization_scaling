
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


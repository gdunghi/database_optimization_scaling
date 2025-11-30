
DROP table if EXISTS ip_data;
CREATE TABLE ip_data (
    id serial,
    ip inet
);



INSERT INTO ip_data (ip)
SELECT
    (192 || '.' ||
     168 || '.' ||
     trunc(random() * 255)::int || '.' ||
     trunc(random() * 255)::int)::inet
FROM generate_series(1, 3000000);

INSERT INTO ip_data (ip)
SELECT
    (10 || '.' ||
     0 || '.' ||
     trunc(random() * 255)::int || '.' ||
     trunc(random() * 255)::int)::inet
FROM generate_series(1, 3000000);


INSERT INTO ip_data (ip)
SELECT
    (172 || '.' ||
     16 || '.' ||
     trunc(random() * 255)::int || '.' ||
     trunc(random() * 255)::int)::inet
FROM generate_series(1, 3000000);


INSERT INTO ip_data (ip)
SELECT
    (172 || '.' ||
     31 || '.' ||
     trunc(random() * 255)::int || '.' ||
     trunc(random() * 255)::int)::inet
FROM generate_series(1, 3000000);

CREATE INDEX idx_ip_spgist
ON ip_data
USING spgist (ip inet_ops);


EXPLAIN (ANALYSE,BUFFERS) 
SELECT ip FROM ip_data
WHERE ip << '192.168.0.0/16';



drop index idx_ip_spgist;

--- create b-tree index
CREATE INDEX idx_ip_btree
ON ip_data (ip inet_ops);

EXPLAIN (ANALYSE,BUFFERS) 
SELECT ip FROM ip_data
WHERE ip << '192.168.0.0/16';

drop index idx_ip_btree;


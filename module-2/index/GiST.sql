CREATE INDEX idx_gist ON customers USING GIST(to_tsvector('english', name));

SELECT *
FROM customers
WHERE to_tsvector('english', name) @@ plainto_tsquery('english', 'Customer 13');


-- run file customer.sql


CREATE INDEX idx_gist ON customers USING GIST(to_tsvector('english', name));

SELECT *
FROM customers
WHERE to_tsvector('english', name) @@ plainto_tsquery('english', 'Customer 13');


SELECT to_tsvector('watches'),
       to_tsvector('watched'),
       to_tsvector('watching');



CREATE EXTENSION pg_trgm;

SET pg_trgm.similarity_threshold = 0.3;
SELECT similarity('pgsql', 'pg sql');  -- 0.44

SELECT 'pgsql' % 'pg sql'; -- true

SET pg_trgm.similarity_threshold = 0.5;
SELECT 'pgsql' % 'pg sql'; -- false 

CREATE INDEX idx_customers_name_gist_trgm ON customers USING GIST (name gist_trgm_ops);
SELECT * FROM customers
WHERE name % 'Customer 13'
ORDER BY similarity(name, 'Customer 13') DESC;


-- lookup contries.sql


CREATE INDEX idx_name_gist_trgm ON countries USING GIST (name gist_trgm_ops);
SELECT * FROM countries WHERE name % 'indon';


-- like ไม่เจอ
SELECT * FROM countries WHERE name like '%United Sa%'

CREATE TABLE bookings (
    id BIGSERIAL PRIMARY KEY,
    start_time TIMESTAMP NOT NULL,
    end_time   TIMESTAMP NOT NULL
);




INSERT INTO bookings (start_time, end_time)
SELECT 
    ts AS start_time,
    ts + (interval '30 minutes' + (random() * interval '2 hours')) AS end_time
FROM generate_series(
    now() - interval '180 days',
    now(),
    interval '10 seconds'
) AS g(ts)
LIMIT 1000000;


EXPLAIN (ANALYSE,BUFFERS)
SELECT *
FROM bookings
WHERE tsrange(start_time, end_time)
      && tsrange('2025-06-03 10:00', '2025-06-05 12:00');

CREATE INDEX idx_range_gist
ON bookings USING GIST (tsrange(start_time, end_time));


EXPLAIN (ANALYSE,BUFFERS)
SELECT *
FROM bookings
WHERE tsrange(start_time, end_time)
      && tsrange('2025-06-03 10:00', '2025-06-05 12:00');
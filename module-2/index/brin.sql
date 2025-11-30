Drop table if EXISTS app_logs;

CREATE TABLE app_logs (
    id BIGSERIAL PRIMARY KEY,
    log_time TIMESTAMPTZ NOT NULL,
    message TEXT
);


INSERT INTO app_logs (log_time, message)
SELECT
    now() - interval '180 days' + (i * interval '1 minute') AS log_time,
    'Log message ' || i
FROM generate_series(1, 10000000) AS s(i);


EXPLAIN ANALYZE
SELECT *
FROM app_logs
WHERE log_time BETWEEN now() - interval '7 days' AND now();


CREATE INDEX idx_logs_log_time_brin
ON app_logs USING BRIN (log_time);

EXPLAIN ANALYZE
SELECT *
FROM app_logs
WHERE log_time BETWEEN now() - interval '7 days' AND now();

-- check size of index
CREATE INDEX idx_logs_log_time_btree
ON app_logs USING BTREE (log_time);
drop index idx_logs_log_time_btree;


-- compare size
SELECT 
    indexrelname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND relname = 'app_logs';



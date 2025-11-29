CREATE TABLE logs (
    id BIGSERIAL PRIMARY KEY,
    log_time TIMESTAMPTZ NOT NULL,
    message TEXT
);


INSERT INTO logs (log_time, message)
SELECT
    now() - interval '180 days' + (i * interval '1 minute') AS log_time,
    'Log message ' || i
FROM generate_series(1, 1000000) AS s(i);



EXPLAIN ANALYZE
SELECT *
FROM logs
WHERE log_time BETWEEN now() - interval '7 days' AND now();



CREATE INDEX idx_logs_log_time_brin
ON logs USING BRIN (log_time);


CREATE INDEX idx_logs_log_time_btree
ON logs USING BTREE (log_time);
drop index idx_logs_log_time_btree;

SELECT 
    indexrelname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND relname = 'logs';



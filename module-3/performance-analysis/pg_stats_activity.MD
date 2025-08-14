```
CREATE TABLE test_pg_stat (
    event_type VARCHAR(50) NOT NULL
);

begin;
insert into test_pg_stat(event_type)values ('test');


```



```
---terminal3
SELECT
    pid,
    datname,
    usename,
    client_addr,
    application_name,
    backend_start,
    query_start,
    state,
    wait_event_type,
    wait_event,
    query
FROM
    pg_stat_activity
```

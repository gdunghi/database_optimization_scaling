```SQL
--- terminal 1
CREATE TABLE test_pg_stat (
    event_type VARCHAR(50) NOT NULL
);

insert into test_pg_stat(event_type)values ('test');
begin;
update test_pg_stat set event_type = 'test_1';

```


```SQL
--- terminal  2

begin;
update test_pg_stat set event_type = 'test_2';

```


```SQL
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
    pg_stat_activity;
```


```SQL
 pid |  datname   | usename | client_addr  | application_name |         backend_start         |          query_start          |        state        | wait_event_type |     wait_event      |                                                query
-----+------------+---------+--------------+------------------+-------------------------------+-------------------------------+---------------------+-----------------+---------------------+-----------------------------------------------------------------------------------------------------
  81 | mydatabase | myuser  |              | psql             | 2025-08-02 14:49:05.932854+07 | 2025-08-02 15:00:55.273289+07 | idle in transaction | Client          | ClientRead          | update test_pg_stat set event_type = 'test_2';
  97 | mydatabase | myuser  | 192.168.65.1 |                  | 2025-08-02 14:54:06.294071+07 | 2025-08-02 15:01:22.011076+07 | active              | Lock            | transactionid       | update test_pg_stat set event_type = 'test_3'
 121 | mydatabase | myuser  | 192.168.65.1 |                  | 2025-08-02 15:01:38.294783+07 | 2025-08-02 15:01:38.30698+07  | idle                | Client          | ClientRead          | SELECT
 ```


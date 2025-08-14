```
CREATE TABLE test_pg_stat (
    event_type VARCHAR(50) NOT NULL
);

begin;
insert into test_pg_stat(event_type)values ('test');


```

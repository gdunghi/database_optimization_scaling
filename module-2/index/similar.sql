CREATE TABLE t_test_1 (
    v1 varchar (100),
    i1 int,
    v2 varchar (100),
    i2 int,
    v3 varchar (100),
    i3 int
)

CREATE TABLE t_test_2 (
    i1 int,
    i2 int,
    i3 int,
    v1 varchar (100),
    v2 varchar (100),
    v3 varchar (100)
);

INSERT INTO t_test_1 SELECT 'abcd', 10, 'abcd', 20, 'abcd', 30
FROM generate_series (1,20000000) ;


INSERT INTO t_test_2 SELECT  10,  20,  30,'abcd','abcd','abcd'
FROM generate_series (1,20000000) ;


SELECT 't_test_1' as table_name ,pg_size_pretty (pg_relation_size ('t_test_1')) 
UNION
SELECT 't_test_2' as table_name ,pg_size_pretty (pg_relation_size ('t_test_2')) ;


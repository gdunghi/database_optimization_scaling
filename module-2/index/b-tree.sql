CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    department_id INT,
    salary INT
);



INSERT INTO employees (name, department_id, salary)
SELECT
    'Employee_' || gs AS name,
    (1 + random()*10)::int AS department_id,  -- 1–10
    (30000 + random()*170000)::int AS salary
FROM generate_series(1,100000) AS gs;



CREATE index emp_idx on employees(department_id, salary);

-- effective index
EXPLAIN ANALYSE SELECT department_id FROM employees WHERE department_id = 10 AND salary > 5000;

-- non effective index
EXPLAIN ANALYSE SELECT department_id FROM employees WHERE salary > 5000;
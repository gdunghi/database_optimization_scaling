DROP index IF EXISTS idx_name_gist_trgm ;
DROP index IF EXISTS idx_name_gin_trgm ;


CREATE INDEX idx_name_gin_trgm ON countries USING GIN (name gin_trgm_ops);

SELECT * FROM countries WHERE name % 'indon';


ALTER TABLE countries ADD COLUMN tsv tsvector;

update countries set tsv = to_tsvector('english', coalesce(name,''));

EXPLAIN ANALYZE 
select *
FROM countries
WHERE tsv @@ to_tsquery('english', 'United & Outlying');

CREATE INDEX idx_countries_tsv_gin
ON countries USING GIN(tsv);


EXPLAIN ANALYZE 
select *
FROM countries
WHERE tsv @@ to_tsquery('english', 'United & Outlying');
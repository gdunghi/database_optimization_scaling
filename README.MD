docker compose down --volumes --rmi all



[INSERT / UPDATE / DELETE]
           ↓
 ┌─────────────────────┐
 │    Table Data       │
 └─────────────────────┘
           ↓
   (Autovacuum / Manual ANALYZE)
           ↓
 ┌──────────────────────────┐
 │ Collect Column Statistics│
 │  - n_distinct            │
 │  - NULL fraction         │
 │  - Histogram bounds      │
 │  - Most common values    │
 └──────────────────────────┘
           ↓
   Store in pg_statistic
           ↓
  Query Planner uses:
   - Row Estimate
   - Join Selectivity
   - Filter Selectivity
           ↓
    Choose Best Plan:
    [Seq Scan / Index Scan / Hash Join / Merge Join]
           ↓
       Query Execution

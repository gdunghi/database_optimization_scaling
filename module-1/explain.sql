Hash Join  (cost=1743.10..88789.12 rows=104181 width=24) (actual time=45.132..1146.707 rows=111288 loops=1)
  Hash Cond: (o.customer_id = c.id)
  Buffers: shared read=60808 dirtied=55108 written=55072
  ->  Bitmap Heap Scan on orders o  (cost=1454.10..88226.06 rows=104358 width=15) (actual time=36.607..1106.256 rows=111288 loops=1)
        Recheck Cond: ((customer_id >= 100) AND (customer_id <= 200))
        Heap Blocks: exact=60641
        Buffers: shared read=60744 dirtied=55108 written=55066
        ->  Bitmap Index Scan on idx_orders_customer  (cost=0.00..1428.01 rows=104358 width=0) (actual time=25.012..25.015 rows=111288 loops=1)
              Index Cond: ((customer_id >= 100) AND (customer_id <= 200))
              Buffers: shared read=103
  ->  Hash  (cost=164.00..164.00 rows=10000 width=17) (actual time=8.369..8.373 rows=10000 loops=1)
        Buckets: 16384  Batches: 1  Memory Usage: 636kB
        Buffers: shared read=64 written=6
        ->  Seq Scan on customers c  (cost=0.00..164.00 rows=10000 width=17) (actual time=0.566..6.671 rows=10000 loops=1)
              Buffers: shared read=64 written=6
Planning:
  Buffers: shared hit=8 read=10 dirtied=1 written=1
Planning Time: 2.303 ms
Execution Time: 1152.943 ms
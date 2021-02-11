
DISCARD ALL;
EXPLAIN ANALYZE
SELECT  	tc.category_name ,
			t.transaction_date ,
			EXTRACT (YEAR FROM t.transaction_date) AS transaction_year,
			t.transaction_value 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
	WHERE  EXTRACT (YEAR FROM t.transaction_date)  = '2015' 
		   AND  tc.category_name = 'JEDZENIE' ;
	
/*
Nested Loop  (cost=0.00..209.13 rows=3 width=136) (actual time=0.034..1.930 rows=286 loops=1)
  Join Filter: (t.id_trans_cat = tc.id_trans_cat)
  Rows Removed by Join Filter: 418
  ->  Seq Scan on transaction_category tc  (cost=0.00..1.14 rows=1 width=122) (actual time=0.020..0.022 rows=1 loops=1)
        Filter: ((category_name)::text = 'JEDZENIE'::text)
        Rows Removed by Filter: 10
  ->  Seq Scan on transactions t  (cost=0.00..207.53 rows=36 width=14) (actual time=0.013..1.756 rows=704 loops=1)
        Filter: (date_part('year'::text, (transaction_date)::timestamp without time zone) = '2015'::double precision)
        Rows Removed by Filter: 6412
Planning Time: 0.203 ms
Execution Time: 1.958 ms
 */
		  
CREATE INDEX idx_transaction_year ON expense_tracker.transactions USING btree (EXTRACT (YEAR FROM transaction_date));
CREATE INDEX idx_transaction_category_name ON expense_tracker.transaction_category USING btree (category_name);
CREATE INDEX idx_bank_account_owner_name ON expense_tracker.bank_account_owner USING btree (owner_name);

DISCARD ALL;
EXPLAIN ANALYZE
SELECT  	tc.category_name ,
			t.transaction_date ,
			EXTRACT (YEAR FROM t.transaction_date) AS transaction_year,
			t.transaction_value 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
	WHERE  EXTRACT (YEAR FROM t.transaction_date)  = '2015' 
		   AND  tc.category_name = 'JEDZENIE' ;

/*
Nested Loop  (cost=4.56..72.69 rows=3 width=136) (actual time=0.105..0.308 rows=286 loops=1)
  Join Filter: (t.id_trans_cat = tc.id_trans_cat)
  Rows Removed by Join Filter: 418
  ->  Seq Scan on transaction_category tc  (cost=0.00..1.14 rows=1 width=122) (actual time=0.019..0.020 rows=1 loops=1)
        Filter: ((category_name)::text = 'JEDZENIE'::text)
        Rows Removed by Filter: 10
  ->  Bitmap Heap Scan on transactions t  (cost=4.56..71.08 rows=36 width=14) (actual time=0.074..0.133 rows=704 loops=1)
        Recheck Cond: (date_part('year'::text, (transaction_date)::timestamp without time zone) = '2015'::double precision)
        Heap Blocks: exact=8
        ->  Bitmap Index Scan on idx_transaction_year  (cost=0.00..4.55 rows=36 width=0) (actual time=0.067..0.067 rows=704 loops=1)
              Index Cond: (date_part('year'::text, (transaction_date)::timestamp without time zone) = '2015'::double precision)
Planning Time: 1.184 ms
Execution Time: 0.353 ms
*/

		  
-- Tigram
DISCARD ALL;
EXPLAIN ANALYZE
SELECT  	tc.category_name ,
			ts.subcategory_name,
			t.transaction_date ,
			EXTRACT (YEAR FROM t.transaction_date) AS transaction_year,
			t.transaction_value 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
	JOIN expense_tracker.transaction_subcategory ts ON t.id_trans_subcat = ts.id_trans_subcat 
													AND tc.id_trans_cat = ts.id_trans_cat 
	WHERE   ts.subcategory_name LIKE '%Jedz%' ;

/*
Seq Scan on transaction_subcategory ts
Planning Time: 0.419 ms
Execution Time: 1.739 ms
 */

CREATE EXTENSION pg_trgm;
CREATE INDEX idx_subcategory_name ON expense_tracker.transaction_subcategory USING GIN(subcategory_name gin_trgm_ops);

DISCARD ALL;

EXPLAIN ANALYZE
SELECT  	tc.category_name ,
			ts.subcategory_name,
			t.transaction_date ,
			EXTRACT (YEAR FROM t.transaction_date) AS transaction_year,
			t.transaction_value 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
	JOIN expense_tracker.transaction_subcategory ts ON t.id_trans_subcat = ts.id_trans_subcat 
													AND tc.id_trans_cat = ts.id_trans_cat 
	WHERE   ts.subcategory_name @@ '%Jed%' ;

/*
Nested Loop  (cost=15.45..209.04 rows=12 width=145) (actual time=0.293..0.294 rows=0 loops=1)
  ->  Hash Join  (cost=15.32..206.99 rows=13 width=27) (actual time=0.293..0.293 rows=0 loops=1)
        Hash Cond: ((t.id_trans_cat = ts.id_trans_cat) AND (t.id_trans_subcat = ts.id_trans_subcat))
        ->  Seq Scan on transactions t  (cost=0.00..154.16 rows=7116 width=18) (actual time=0.022..0.022 rows=1 loops=1)
        ->  Hash  (cost=15.30..15.30 rows=1 width=17) (actual time=0.261..0.261 rows=0 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 8kB
              ->  Seq Scan on transaction_subcategory ts  (cost=0.00..15.30 rows=1 width=17) (actual time=0.261..0.261 rows=0 loops=1)
                    Filter: ((subcategory_name)::text @@ '%Jed%'::text)
                    Rows Removed by Filter: 55
  ->  Index Scan using transaction_category_pkey on transaction_category tc  (cost=0.14..0.15 rows=1 width=122) (never executed)
        Index Cond: (id_trans_cat = t.id_trans_cat)
Planning Time: 25.334 ms
Execution Time: 0.339 ms
*/


-- Partycjonowanie tableli transactions 

CREATE TABLE IF NOT EXISTS expense_tracker.transactions_partittioned(
	id_transaction serial ,
	id_trans_ba integer references expense_tracker.transaction_bank_accounts (id_trans_ba), 
	id_trans_cat integer references expense_tracker.transaction_category (id_trans_cat),
	id_trans_subcat integer references expense_tracker.transaction_subcategory (id_trans_subcat),
	id_trans_type integer references expense_tracker.transaction_type (id_trans_type),
 	id_user integer references expense_tracker.users (id_user),
	transaction_date date DEFAULT current_date,
	transaction_value NUMERIC(9,2),
	transaction_description TEXT,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp,
	primary key (id_transaction, transaction_date)
) PARTITION BY RANGE(transaction_date);

CREATE TABLE transactions_2015 PARTITION OF expense_tracker.transactions_partittioned 
	FOR VALUES FROM ('2015-01-01') TO ('2016-01-01'); 

CREATE TABLE transactions_2016 PARTITION OF expense_tracker.transactions_partittioned 
	FOR VALUES FROM ('2016-01-01') TO ('2017-01-01'); 

CREATE TABLE transactions_2017 PARTITION OF expense_tracker.transactions_partittioned 
	FOR VALUES FROM ('2017-01-01') TO ('2018-01-01'); 

CREATE TABLE transactions_2018 PARTITION OF expense_tracker.transactions_partittioned 
	FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE transactions_2019 PARTITION OF expense_tracker.transactions_partittioned 
	FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');


EXPLAIN ANALYZE
INSERT INTO expense_tracker.transactions_partittioned
SELECT id_transaction , id_trans_ba , id_trans_cat, id_trans_subcat, id_trans_type ,
 	id_user , transaction_date , transaction_value , transaction_description , insert_date , update_date
FROM expense_tracker.transactions
WHERE transaction_date BETWEEN '2015-01-01' AND '2019-12-30'
;
/*
  Insert on transactions_partittioned  (cost=0.00..189.74 rows=6344 width=54) (actual time=32.008..32.009 rows=0 loops=1)
  ->  Seq Scan on transactions  (cost=0.00..189.74 rows=6344 width=54) (actual time=0.032..1.658 rows=6374 loops=1)
        Filter: ((transaction_date >= '2015-01-01'::date) AND (transaction_date <= '2019-12-30'::date))
        Rows Removed by Filter: 742
Execution Time: 431.158 ms
 */

-- tabela transactions 
DISCARD ALL;
EXPLAIN ANALYZE
SELECT  	tc.category_name ,
			ts.subcategory_name,
			t.transaction_date ,
			EXTRACT (YEAR FROM t.transaction_date) AS transaction_year,
			t.transaction_value 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
	JOIN expense_tracker.transaction_subcategory ts ON t.id_trans_subcat = ts.id_trans_subcat 
													AND tc.id_trans_cat = ts.id_trans_cat 
	WHERE transaction_date BETWEEN '2016-01-01' AND '2016-04-30';
 -- Execution Time: 1.192 ms


-- tabela transactions_partittioned
DISCARD ALL;
EXPLAIN ANALYZE
SELECT  	tc.category_name ,
			ts.subcategory_name,
			tp.transaction_date ,
			EXTRACT (YEAR FROM tp.transaction_date) AS transaction_year,
			tp.transaction_value 
	FROM expense_tracker.transactions_partittioned tp 
	JOIN expense_tracker.transaction_category tc ON tp.id_trans_cat = tc.id_trans_cat
	JOIN expense_tracker.transaction_subcategory ts ON tp.id_trans_subcat = ts.id_trans_subcat 
													AND tc.id_trans_cat = ts.id_trans_cat 
	WHERE transaction_date BETWEEN '2016-01-01' AND '2016-04-30';

-- Execution Time: 0.972 ms


--- Widoki vs select 
DISCARD ALL;
EXPLAIN ANALYZE
	SELECT  bao.owner_name,
			tc.category_name ,
			ts.subcategory_name ,
			tt.transaction_type_name ,
			t.transaction_date ,
			EXTRACT (YEAR FROM t.transaction_date) AS transaction_year,
			t.transaction_value ,
			bat.ba_type 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
	JOIN expense_tracker.transaction_subcategory ts ON t.id_trans_subcat = ts.id_trans_subcat 
													AND tc.id_trans_cat = ts.id_trans_cat 
	JOIN expense_tracker.transaction_type tt ON t.id_trans_type = tt.id_trans_type 
	JOIN expense_tracker.transaction_bank_accounts tba ON t.id_trans_ba = tba.id_trans_ba 
	JOIN expense_tracker.bank_account_types bat ON tba.id_ba_type = bat.id_ba_type 
	JOIN expense_tracker.bank_account_owner bao ON tba.id_ba_own = bao.id_ba_own 
	AND  bao.owner_name = 'Janusz Kowalski'
	WHERE EXTRACT (YEAR FROM t.transaction_date) = '2016';
-- Execution Time: 8.200 ms


CREATE  MATERIALIZED VIEW JK_mat_view AS 
	SELECT  bao.owner_name,
			tc.category_name ,
			ts.subcategory_name ,
			tt.transaction_type_name ,
			t.transaction_date ,
			EXTRACT (YEAR FROM t.transaction_date) AS transaction_year,
			t.transaction_value ,
			bat.ba_type 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
	JOIN expense_tracker.transaction_subcategory ts ON t.id_trans_subcat = ts.id_trans_subcat 
													AND tc.id_trans_cat = ts.id_trans_cat 
	JOIN expense_tracker.transaction_type tt ON t.id_trans_type = tt.id_trans_type 
	JOIN expense_tracker.transaction_bank_accounts tba ON t.id_trans_ba = tba.id_trans_ba 
	JOIN expense_tracker.bank_account_types bat ON tba.id_ba_type = bat.id_ba_type 
	JOIN expense_tracker.bank_account_owner bao ON tba.id_ba_own = bao.id_ba_own 
	AND  bao.owner_name = 'Janusz Kowalski'
	WHERE EXTRACT (YEAR FROM t.transaction_date) = '2016';
	

DISCARD ALL;
EXPLAIN ANALYZE 
SELECT *
FROM JK_mat_view;

-- Execution Time: 0.108 ms

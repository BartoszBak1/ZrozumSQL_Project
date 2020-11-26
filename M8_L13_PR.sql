-- 1

SELECT 
	tc.category_name,
	sum(t.transaction_value) sum_of_transaction_value
FROM expense_tracker.transactions t 
JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat 
GROUP BY tc.category_name;

-- 2
SELECT  tc.category_name,
	   sum(t.transaction_value) sum_of_expenses
FROM expense_tracker.transactions t 
JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat
											AND EXTRACT (YEAR FROM t.transaction_date) = '2020'
											AND tc.category_name = 'U¯YWKI'
JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba 
											AND tba.bank_account_name = 'ROR - Janusz'
GROUP BY tc.category_name


-- 3
SELECT 
		EXTRACT (YEAR FROM t.transaction_date) AS YEAR,
		EXTRACT (YEAR FROM t.transaction_date) ||'_'|| EXTRACT (QUARTER FROM t.transaction_date) YEAR_and_QUARTER,
 		EXTRACT (YEAR FROM t.transaction_date) ||'_'|| EXTRACT (MONTH FROM t.transaction_date) YEAR_and_MONTH,
 		sum(t.transaction_value)
FROM expense_tracker.transactions t 
JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type 
										 AND EXTRACT (YEAR FROM t.transaction_date) = '2019'
										 AND tt.transaction_type_name = 'Obci¹¿enie'
JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba 
											AND tba.bank_account_name = 'ROR - Janusz i Gra¿ynka'
GROUP BY ROLLUP (EXTRACT (YEAR FROM t.transaction_date),
				(EXTRACT (YEAR FROM t.transaction_date)) ||'_'|| (EXTRACT (QUARTER FROM t.transaction_date)),
 				(EXTRACT (YEAR FROM t.transaction_date)) ||'_'|| (EXTRACT (MONTH FROM t.transaction_date)) )
ORDER BY  YEAR_and_QUARTER;

-- 4

WITH sum_transactions AS (
				SELECT 
						EXTRACT(YEAR FROM t.transaction_date) AS transaction_year,
						sum(t.transaction_value) AS sum_transactions_value
				FROM expense_tracker.transactions t 
				JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type
										                 AND tt.transaction_type_name = 'Obci¹¿enie'
	            										 AND EXTRACT(YEAR FROM t.transaction_date) >= 2015
	            JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba  
				JOIN expense_tracker.bank_account_types bat ON bat.id_ba_type = tba.id_ba_type 
											                AND bat.ba_type = 'ROR - WSPÓLNY'
			    GROUP BY transaction_year 
			    ), previous_year_transactions AS 
			   (SELECT *,
		 			lag(sum_transactions_value) OVER (ORDER BY transaction_year) AS previous_year_expenses
    		    FROM sum_transactions
) SELECT transaction_year,
		 sum_transactions_value,
		 previous_year_expenses,
		 previous_year_expenses-sum_transactions_value AS balance
    FROM previous_year_transactions;
											              


-- 5
   
WITH transactions_query AS (
						SELECT 
							   t.id_transaction,
							   t.transaction_value,
							   ts.subcategory_name,
							   t.transaction_date
						FROM expense_tracker.transactions t
						JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba
																		   AND tba.bank_account_name = 'ROR - Janusz'
																		   AND EXTRACT (YEAR FROM t.transaction_date) = '2020'
																		   AND EXTRACT (QUARTER FROM t.transaction_date) = '1'
						JOIN expense_tracker.transaction_subcategory ts  ON ts.id_trans_subcat = t.id_trans_subcat 
																	     AND ts.subcategory_name = 'Technologie'
)
SELECT *,
   		  LAST_VALUE(transaction_date) OVER (ORDER BY transaction_date 
   		  								GROUPS BETWEEN CURRENT ROW AND 1 FOLLOWING 
   		  									EXCLUDE CURRENT ROW) AS next_tech_transaction,
          LAST_VALUE(transaction_date) OVER (ORDER BY transaction_date
   		  							   GROUPS BETWEEN CURRENT ROW AND 1 FOLLOWING 
   		  									EXCLUDE CURRENT ROW) - transaction_date AS days_since_previous_tech_transactions
FROM transactions_query;
	


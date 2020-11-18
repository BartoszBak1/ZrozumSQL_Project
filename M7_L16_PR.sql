-- 1

SELECT bao.owner_name, bao.owner_desc, bao.user_login,
	   bat.ba_type, bat.ba_desc, bat.active,
	   tba.bank_account_name 
FROM expense_tracker.bank_account_owner bao 
JOIN expense_tracker.bank_account_types bat ON bat.id_ba_own = bao.id_ba_own
											AND bao.owner_name = 'Janusz Kowalski'
JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_ba_type = bat.id_ba_type;
									


-- 2

SELECT tc.category_name,
	   ts.subcategory_name 
FROM expense_tracker.transaction_category tc 
LEFT JOIN expense_tracker.transaction_subcategory ts ON tc.id_trans_cat = ts.id_trans_cat
												AND tc.active = TRUE 
ORDER BY tc.id_trans_cat;

-- 3

SELECT *
FROM expense_tracker.transactions t 
JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
											 AND EXTRACT(YEAR FROM t.transaction_date) = '2016'
											 AND tc.category_name = 'JEDZENIE';
											
-- 4
									
INSERT INTO expense_tracker.transaction_subcategory (id_trans_subcat ,id_trans_cat,subcategory_name,subcategory_description)	 
VALUES (54,1,'warzywa', 'warzywa');

WITH transactions_jedzenie_2016 AS (
	SELECT t.id_transaction
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
											 AND EXTRACT(YEAR FROM t.transaction_date) = '2016'
											 AND tc.category_name = 'JEDZENIE'
											 AND t.id_trans_subcat = -1)
UPDATE expense_tracker.transactions t
SET id_trans_subcat = 54
WHERE EXISTS (SELECT 1
	FROM transactions_jedzenie_2016
	WHERE transactions_jedzenie_2016.id_transaction = t.id_transaction);



SELECT t.id_transaction,tc.category_name,t.id_trans_subcat,t.transaction_date
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
											 AND EXTRACT(YEAR FROM t.transaction_date) = '2016'
											 AND tc.category_name = 'JEDZENIE'
											 AND t.id_trans_subcat = 54;

											
-- 5
											
SELECT tc.category_name,
	   ts.subcategory_name,
	   tt.transaction_type_name,
	   t.transaction_date,
	   t.transaction_value
FROM expense_tracker.transactions t 
JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat 
JOIN expense_tracker.transaction_subcategory ts ON t.id_trans_subcat = ts.id_trans_subcat 
JOIN expense_tracker.transaction_type tt ON t.id_trans_type = tt.id_trans_type 
JOIN expense_tracker.transaction_bank_accounts tba ON t.id_trans_ba = tba.id_trans_ba 
												   AND EXTRACT(YEAR FROM t.transaction_date) = '2020'
JOIN expense_tracker.bank_account_types bat ON tba.id_ba_type = bat.id_ba_type 
											AND bat.ba_type = 'OSZCZ - WSPÓLNY'
JOIN expense_tracker.bank_account_owner bao ON tba.id_ba_own = bao.id_ba_own 
											AND bao.owner_name = 'Janusz i Gra¿ynka';

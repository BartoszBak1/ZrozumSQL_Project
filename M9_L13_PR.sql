/*1. Stwórz 3 osobne widoki dla wszystkich transakcji z podziałem na rodzaj właściciela
konta. W widokach wyświetl informacje o nazwie kategorii, nazwie podkategorii, typie
transakcji, dacie transakcji, roku z daty transakcji, wartości transakcji i type konta. */

DROP VIEW JK_view;
CREATE OR REPLACE VIEW JK_view AS 
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
	JOIN expense_tracker.transaction_type tt ON t.id_trans_type = tt.id_trans_type 
	JOIN expense_tracker.transaction_bank_accounts tba ON t.id_trans_ba = tba.id_trans_ba 
	JOIN expense_tracker.bank_account_types bat ON tba.id_ba_type = bat.id_ba_type 
	JOIN expense_tracker.bank_account_owner bao ON tba.id_ba_own = bao.id_ba_own 
	AND  bao.owner_name = 'Janusz Kowalski';

DROP VIEW GK_view;
CREATE OR REPLACE VIEW JK_view AS 
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
	JOIN expense_tracker.transaction_type tt ON t.id_trans_type = tt.id_trans_type 
	JOIN expense_tracker.transaction_bank_accounts tba ON t.id_trans_ba = tba.id_trans_ba 
	JOIN expense_tracker.bank_account_types bat ON tba.id_ba_type = bat.id_ba_type 
	JOIN expense_tracker.bank_account_owner bao ON tba.id_ba_own = bao.id_ba_own 
	AND  bao.owner_name = 'Grażyna Kowalska';


CREATE OR REPLACE VIEW JiG_view AS 
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
	JOIN expense_tracker.transaction_type tt ON t.id_trans_type = tt.id_trans_type 
	JOIN expense_tracker.transaction_bank_accounts tba ON t.id_trans_ba = tba.id_trans_ba 
	JOIN expense_tracker.bank_account_types bat ON tba.id_ba_type = bat.id_ba_type 
	JOIN expense_tracker.bank_account_owner bao ON tba.id_ba_own = bao.id_ba_own 
	AND  bao.owner_name = 'Janusz i Grażynka';	


DROP VIEW JK_view;
DROP VIEW GK_view;
DROP VIEW JiG_view;

/*2. Korzystając z widoku konta dla Janusza i Grażynki z zadania 1 przygotuj zapytanie, w
którym wyświetlisz, rok transakcji, typ transakcji, nazwę kategorii, zgrupowaną listę
unikatowych (DISTINCT) podkategorii razem z sumą transakcji dla grup rok transakcji,
typ transakcji, nazwę kategorii. */


SELECT category_name ,
       transaction_type_name ,
	   transaction_year,
	   sum(transaction_value) AS sum_trans_value ,
	   array_agg(DISTINCT subcategory_name) AS list_subscategory
FROM JiG_view
GROUP BY category_name ,
		 transaction_type_name ,
		 transaction_year;

/*3. Dodaj do schematu nową tabelę MONTHLY_BUDGET_PLANNED o atrybutach
? YEAR_MONTH VARCHAR(7) PRIMARY_KEY,
? BUDGET_PLANNED NUMERIC(10,2)
? LEFT_BUDGET NUMERIC(10,2)
Dodaj do tej tabeli nowy rekord z planowanym budżetem na dany miesiąc obecnego
roku (do obu atrybutów BUDGET_PLANNED, LEFT_BUDGET ta sama wartość) */
		
DROP TABLE IF EXISTS expense_tracker.monthly_budget_planned;		   
CREATE TABLE IF NOT EXISTS expense_tracker.monthly_budget_planned	 (
   month_year VARCHAR(7) PRIMARY KEY,
   budget_planned NUMERIC(10,2),
   left_budget NUMERIC(10,2)
);

INSERT INTO expense_tracker.monthly_budget_planned(month_year, budget_planned, left_budget) VALUES ('12-2020', 1000, 1000);


/*4. Dodaj nowy Wyzwalacz do tabeli TRANSACTIONS, który przy każdorazowym dodaniu
zaktualizowaniu lub usunięciu wartości zmieni wartość LEFT_BUDGET odpowiednio
w tabeli expense_tracker.monthly_budget_planned. */

CREATE OR REPLACE FUNCTION update_monthly_budget()
	RETURNS TRIGGER 
	LANGUAGE plpgsql
	AS $$
	 BEGIN 
		IF (TG_OP = 'DELETE') THEN 
		  UPDATE expense_tracker.monthly_budget_planned  SET left_budget = left_budget - OLD.transaction_value
		  WHERE expense_tracker.monthly_budget_planned.month_year = (EXTRACT ( MONTH FROM OLD.transaction_date) ||'-'||  EXTRACT (YEAR FROM OLD.transaction_date));
		ELSIF (TG_OP = 'UPDATE') THEN 
		  UPDATE expense_tracker.monthly_budget_planned  SET left_budget = left_budget - OLD.transaction_value + NEW.transaction_value
		  WHERE expense_tracker.monthly_budget_planned.month_year = (EXTRACT ( MONTH FROM  OLD.transaction_date) ||'-'||  EXTRACT (YEAR FROM OLD.transaction_date));
		ELSIF (TG_OP = 'INSERT') THEN 
		  UPDATE expense_tracker.monthly_budget_planned  SET left_budget = left_budget + NEW.transaction_value
		  WHERE expense_tracker.monthly_budget_planned.month_year = (EXTRACT ( MONTH FROM NEW.transaction_date) ||'-'||  EXTRACT (YEAR FROM NEW.transaction_date));
		
		END IF; 
	RETURN NULL;
	 END;
	$$;

CREATE TRIGGER uptade_monthly_budget_trigger
	AFTER INSERT OR UPDATE OR DELETE 
	ON expense_tracker.transactions 
	FOR EACH ROW 
	EXECUTE PROCEDURE update_monthly_budget();

/*5. Przetestuj działanie wyzwalacza dla kilku przykładowych operacji. */

/*ALTER SEQUENCE expense_tracker.transactions_id_transaction_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 7117
	CACHE 1
	NO CYCLE;
ALTER SEQUENCE expense_tracker.transactions_id_transaction_seq RESTART;*/


INSERT INTO expense_tracker.transactions (id_trans_ba, id_trans_cat, id_trans_subcat, 
                       id_trans_type, id_user, transaction_date, transaction_value,transaction_description) 
                       VALUES (1,1,4,2,null,now(),-500,'f17');
                      
                      
UPDATE expense_tracker.transactions SET transaction_value = -200 -- , transaction_date = '2020-11-02'
									WHERE id_transaction = 7117;        
														
SELECT *
FROM expense_tracker.monthly_budget_planned mbp;

DELETE FROM expense_tracker.transactions WHERE id_transaction = 7117;

SELECT *
FROM expense_tracker.monthly_budget_planned mbp;

/*6. Czego brakuje w tym triggerze? Jakie potencjalnie spowoduje problemy w kontekście
danych w tabeli MONTHLY_BUDGET_PLANNED. */

--1) Można dodać funkcję, która będzie aktualizowała planowany budżet na następny miesiąc. 
--   Jeśli przekroczymy planowany budżet na dany miesiąc to automatycznie zmniejszy ilość pieniędzy jaką możemy wydać w następny miesiącu
--   lub jeśli będziemy mieć na koniec miesiąca więcej pieniędzy niż planowaliśmy automatycznie zwiększy ilość pieniędzy jaką możemy wydać w następny miesiącu.
--2) Trigger działa niepoprawnie jeśli w operacji uptade zmienimy datę transakcji. 
--3) Trigger nie jest odporny na różne formaty dat w kolumnie month_year.
--4) Do tabeli MONTHLY_BUDGET_PLANNED można by było dodać informację o jakiego konta dotyczy planowany budżet i dołączyć ją do schematu.



DROP TABLE IF EXISTS expense_tracker.monthly_budget_planned;	
DROP FUNCTION update_monthly_budget() CASCADE;

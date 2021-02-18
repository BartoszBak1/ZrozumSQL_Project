
/*1. Zmień tabelę USERS w taki sposób, aby pozbyć się pola password_salt (wykorzystaj gen_salt()), i hasło przetrzymywane w tabeli,
 powinno być hasłem zaszyfrowanym funkcją crypt().*/
CREATE EXTENSION pgcrypto SCHEMA expense_tracker;

ALTER TABLE  expense_tracker.users DROP COLUMN password_salt;
UPDATE expense_tracker.users SET user_password = crypt(user_password, gen_salt('md5'));


/*2.
a. Zobacz ile wierszy dla tabel posiadających klucze obce ma w sobie wartość -1 (<unknown>).
b. Czy w atrybutach tabeli TRANSACTIONS są wartości nieokreślone (NULL) - na jakich atrybutach? Jaki procent całego zbioru danych one stanowią?
 */

-- informacje o zmiennych w schemacie expense_tracker
SELECT * 
FROM information_schema."columns" c 
WHERE table_schema = 'expense_tracker'
ORDER BY c.table_name, c.ordinal_position ;


-- znalezienie tabel z kluczami obcymi 
SELECT DISTINCT 
    tc.table_name
FROM 
    information_schema.table_constraints  tc 
    JOIN information_schema.key_column_usage  kcu ON tc.constraint_name = kcu.constraint_name
      											  AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
      													AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'expense_tracker' ;

-- obliczenie ilosci wystepowan wartości -1 w kolumnach odpowadajązych za klucze główne w danych tabelach
SELECT count(*)
FROM expense_tracker.bank_account_types bat 
WHERE id_ba_type = -1;

SELECT count(*)
FROM expense_tracker.transaction_bank_accounts 
WHERE id_trans_ba = -1;

SELECT count(*)
FROM expense_tracker.transaction_subcategory
WHERE id_trans_subcat = -1;

SELECT count(*)
FROM expense_tracker.transactions
WHERE id_transaction = -1;

--b) analiza braków danych tabela transactions 

-- obliczenie jaki procent całego zbioru danych stanowią braki
WITH missing_val_in_set as
	(SELECT count(*) * (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS  WHERE table_schema = 'expense_tracker' AND table_name = 'transactions') AS number_of_records,
	   SUM(CASE WHEN id_transaction IS NULL THEN 1 ELSE 0 END) + 
	   SUM(CASE WHEN id_trans_ba IS NULL THEN 1 ELSE 0 END) +
	   SUM(CASE WHEN id_trans_cat IS NULL THEN 1 ELSE 0 END) +
	   SUM(CASE WHEN id_trans_subcat IS NULL THEN 1 ELSE 0 END) +
	   SUM(CASE WHEN id_trans_type IS NULL THEN 1 ELSE 0 END) +
	   SUM(CASE WHEN id_user IS NULL THEN 1 ELSE 0 END) +
	   SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) +
	   SUM(CASE WHEN transaction_value  IS NULL THEN 1 ELSE 0 END) +
	   SUM(CASE WHEN transaction_description IS NULL THEN 1 ELSE 0 END) +
	   SUM(CASE WHEN insert_date IS NULL THEN 1 ELSE 0 END) +
	   SUM(CASE WHEN update_date IS NULL THEN 1 ELSE 0 END) AS number_of_missing_val
	FROM expense_tracker.transactions t)
SELECT  number_of_records,
		number_of_missing_val,
		number_of_missing_val::float /number_of_records *100 AS pct_missing_val
FROM missing_val_in_set;

-- obliczenie procentowego udziału brakujących danych w kolumnach
SELECT count(*) AS number_of_records,
	   COALESCE(SUM(CASE WHEN id_transaction IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_id_transaction,
	   COALESCE(SUM(CASE WHEN id_trans_ba IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_id_trans_ba,
	   COALESCE(SUM(CASE WHEN id_trans_cat IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_id_trans_cat,
	   COALESCE(SUM(CASE WHEN id_trans_subcat IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_id_trans_subcat,
	   COALESCE(SUM(CASE WHEN id_trans_type IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_id_trans_type,
	   COALESCE(SUM(CASE WHEN id_user IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_id_user,
	   COALESCE(SUM(CASE WHEN transaction_date IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_transaction_date,
	   COALESCE(SUM(CASE WHEN transaction_value  IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_transaction_value,
	   COALESCE(SUM(CASE WHEN transaction_description IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_transaction_description,
	   COALESCE(SUM(CASE WHEN insert_date IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_insert_date,
	   COALESCE(SUM(CASE WHEN update_date IS NULL THEN 1 END)::float/count(*) * 100,0)	AS pct_of_missing_val_update_date
FROM expense_tracker.transactions t ;


-- obliczenie braków danych w wierszach 
SELECT 
	(SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS  WHERE table_schema = 'expense_tracker' AND table_name = 'transactions') AS number_of_variable,
	num_nulls(id_transaction, id_trans_ba, id_trans_cat, id_trans_subcat, id_trans_type, 
			  id_user, transaction_date, transaction_value, transaction_description, 
			  insert_date, update_date) AS sum_missing_val_in_row,
	num_nulls(id_transaction, id_trans_ba, id_trans_cat,
			  id_trans_subcat, id_trans_type, id_user,
			  transaction_date, transaction_value, transaction_description, 
			  insert_date, update_date)::float / (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS  WHERE table_schema = 'expense_tracker' AND table_name = 'transactions') * 100 AS pct_of_missing_val_in_row
FROM  expense_tracker.transactions t;

/*3. Zastanów się i rozpisz w kilku krokach, Twoje podejście do wykorzystania przygotowanego schematu, jako rzeczywistego elementu aplikacji.
Wymagania:
? Korzysta z niej wiele rodzin / osób (czy trzymasz wszystko w jednym
schemacie / czy schemat per użytkownik (rodzina) ?)
? Jak zarządzasz użytkownikami i hasłami?
? Jak wykorzystasz wnioski z poprzednich modułów (które tabele, klucze obce
zostają / nie zostają, jak podejdziesz do wydajności itd.) */ 

/*3.
- schemat na rodzinę
- dane użytkowników będą przechowywane w tabeli users. Użytkownik wpisuje swoje hasło następnie jest ono szyfrowane generowaną w locie funkcją

Modyfikacje schematu:
- nie usuwałem żadnych kluczy obcych, dodałem natomiast nową tabelę users_bank_account_owner łączącą tabelę users z bank_account_owners
- usunąłem kolumnę password_salt z tabel users
- dodanie partycjonowania tabeli transactions ze względu na rok transakcji 
- stworzenie indexów typu betree na tabelach transactions, bank_account_owner odpowiednio na kolumnach  transaction_date, owner_name  i indexów GIN na tabelach transaction_category, transaction_subcategory  odpowiednio na kolumnach category_name, subcategory_name
- nie tworzę triggerów i funkcji automatyzujących jakieś czynności, ponieważ to będzie zrealizowane w warstwie backendu
*/



-- 4.  Schemat 

DO
$do$
BEGIN
   IF EXISTS (
      SELECT FROM pg_catalog.pg_roles 
      WHERE  rolname = 'expense_tracker_user') THEN
      REASSIGN OWNED  BY expense_tracker_user TO postgres;
      DROP OWNED BY expense_tracker_user;
   END IF;
END
$do$;

-- creating user with the ability to log into database
DROP ROLE IF EXISTS expense_tracker_user; 
CREATE ROLE expense_tracker_user WITH LOGIN PASSWORD 'p3r50na!3ud93t'; 

REVOKE CREATE ON SCHEMA public FROM PUBLIC; --  revoke ability to create in public schema of the PUBLIC group 

-- IF EXISTS expense_tracker_group, revoke dependent objects from expense_tracker_group to postgres
DO
$do$
BEGIN
   IF EXISTS (
      SELECT FROM pg_catalog.pg_roles 
      WHERE  rolname = 'expense_tracker_group') THEN
      REASSIGN OWNED  BY  expense_tracker_group TO postgres;
      DROP OWNED BY expense_tracker_group;
   END IF;
END
$do$;

-- creating a group expense_tracker_group
DROP ROLE IF EXISTS expense_tracker_group;
CREATE ROLE expense_tracker_group;

-- creating schema expense_tracker and seting owner expense_tracker_group of this schema 
DROP SCHEMA IF EXISTS expense_tracker CASCADE;
CREATE SCHEMA IF NOT EXISTS expense_tracker AUTHORIZATION expense_tracker_group; 

-- settling rights for expanse_tracker_group and giving all privileges to expense_tracker schema
GRANT CONNECT ON DATABASE postgres TO expense_tracker_group; 
GRANT ALL PRIVILEGES ON SCHEMA expense_tracker TO expense_tracker_group;

GRANT expense_tracker_group TO expense_tracker_user; -- assigment user expense_tracker_user to expense_tracker_group group 


--- Createing  tabels with keys.

DROP TABLE IF EXISTS expense_tracker.users CASCADE;
CREATE TABLE IF NOT EXISTS expense_tracker.users(
	id_user serial PRIMARY KEY,
	user_login varchar(25) NOT NULL,
	user_name varchar(50) NOT NULL,
	user_password varchar(100) NOT NULL,
	active boolean DEFAULT TRUE NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

DROP TABLE IF EXISTS expense_tracker.bank_account_owner CASCADE;
CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_owner(
	id_ba_own serial PRIMARY KEY,
	owner_name varchar(50) NOT NULL,
	owner_status varchar(250), 
	active boolean DEFAULT TRUE NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

DROP TABLE IF EXISTS expense_tracker.users_bank_account_owner CASCADE;
CREATE TABLE IF NOT EXISTS expense_tracker.users_bank_account_owner(
	id serial PRIMARY KEY,
	id_ba_own integer NOT NULL,
	id_user integer NOT NULL, 
	FOREIGN KEY (id_user) REFERENCES expense_tracker.users(id_user),
	FOREIGN KEY (id_ba_own) REFERENCES expense_tracker.bank_account_owner(id_ba_own)
);

DROP TABLE IF EXISTS expense_tracker.transaction_type CASCADE;
CREATE TABLE IF NOT EXISTS expense_tracker.transaction_type(
	id_trans_type serial PRIMARY KEY,
	transaction_type_name varchar(50) NOT NULL,
	transaction_type_desc varchar(250),
	active boolean DEFAULT TRUE NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

DROP TABLE IF EXISTS expense_tracker.transaction_category CASCADE;
CREATE TABLE IF NOT EXISTS expense_tracker.transaction_category(
	id_trans_cat serial PRIMARY KEY,
	category_name varchar(50) NOT NULL,
	category_description varchar(250),
	active boolean DEFAULT TRUE NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

DROP TABLE IF EXISTS expense_tracker.transaction_subcategory CASCADE;
CREATE TABLE IF NOT EXISTS expense_tracker.transaction_subcategory(
	id_trans_subcat serial PRIMARY KEY,
	id_trans_cat integer,
	subcategory_name varchar(50) NOT NULL,
	subcategory_description varchar(250),
	active boolean DEFAULT TRUE NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp,
	FOREIGN KEY (id_trans_cat) REFERENCES expense_tracker.transaction_category(id_trans_cat)
);

DROP TABLE IF EXISTS expense_tracker.bank_account_types CASCADE;
CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_types(
	id_ba_type serial PRIMARY KEY,
	ba_type varchar(50) NOT NULL,
	ba_desc varchar(250),
	active boolean DEFAULT TRUE NOT NULL ,
	is_common_account boolean DEFAULT TRUE NOT NULL,
	id_ba_own integer,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp,
	FOREIGN KEY (id_ba_own) REFERENCES expense_tracker.bank_account_owner(id_ba_own)
);

DROP TABLE IF EXISTS expense_tracker.transaction_bank_accounts CASCADE;	
CREATE TABLE IF NOT EXISTS expense_tracker.transaction_bank_accounts(
	id_trans_ba serial PRIMARY KEY,
	id_ba_own integer,
	id_ba_type integer,
	bank_account_name varchar(50) NOT NULL,
	bank_account_desc varchar(250),
	active boolean DEFAULT TRUE NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp,
	FOREIGN KEY (id_ba_own) REFERENCES expense_tracker.bank_account_owner(id_ba_own),
	FOREIGN KEY (id_ba_type) REFERENCES expense_tracker.bank_account_types(id_ba_type)
);

DROP TABLE IF EXISTS expense_tracker.transactions CASCADE;
CREATE TABLE IF NOT EXISTS expense_tracker.transactions(
	id_transaction serial ,
	id_trans_ba integer,
	id_trans_cat integer,
	id_trans_subcat integer,
	id_trans_type integer,
	id_user integer,
	transaction_date date DEFAULT current_date,
	transaction_value NUMERIC(9,2),
	transaction_description TEXT,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp,
	FOREIGN KEY (id_user) REFERENCES expense_tracker.users(id_user),
	FOREIGN KEY (id_trans_type) REFERENCES expense_tracker.transaction_type(id_trans_type),
	FOREIGN KEY (id_trans_cat) REFERENCES expense_tracker.transaction_category(id_trans_cat),
	FOREIGN KEY (id_trans_subcat) REFERENCES expense_tracker.transaction_subcategory(id_trans_subcat),
	FOREIGN KEY (id_trans_ba) REFERENCES expense_tracker.transaction_bank_accounts(id_trans_ba),
	PRIMARY KEY (id_transaction, transaction_date)
)PARTITION BY RANGE (transaction_date);


CREATE TABLE transactions_2015 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2015-01-01') TO ('2016-01-01'); 

CREATE TABLE transactions_2016 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2016-01-01') TO ('2017-01-01'); 

CREATE TABLE transactions_2017 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2017-01-01') TO ('2018-01-01'); 

CREATE TABLE transactions_2018 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE transactions_2019 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
	
CREATE TABLE transactions_2020 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');

CREATE TABLE transactions_2021 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
	
CREATE EXTENSION pg_trgm SCHEMA expense_tracker;
CREATE INDEX idx_transaction_year ON expense_tracker.transactions USING btree (EXTRACT (YEAR FROM transaction_date));
CREATE INDEX idx_bank_account_owner_name ON expense_tracker.bank_account_owner USING btree (owner_name);
CREATE INDEX idx_transaction_category_name ON expense_tracker.transaction_category USING GIN (category_name gin_trgm_ops);
CREATE INDEX idx_subcategory_name ON expense_tracker.transaction_subcategory USING GIN(subcategory_name gin_trgm_ops);

-- This script is used to create a new, clean database structure, users and groups and to declare their permissions

-- IF EXISTS expense_tracker_group, revoke dependent objects from expense_tracker_user to postgres
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
DROP TABLE IF EXISTS expense_tracker.bank_account_owner CASCADE;
CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_owner(
	id_ba_own serial PRIMARY KEY,
	owner_name varchar(50) NOT NULL,
	owner_desc varchar(250), 
	user_login integer NOT NULL, 
	active boolean DEFAULT TRUE NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

DROP TABLE IF EXISTS expense_tracker.users CASCADE;
CREATE TABLE IF NOT EXISTS expense_tracker.users(
	id_user serial PRIMARY KEY,
	user_login varchar(25) NOT NULL,
	user_name varchar(50) NOT NULL,
	user_password varchar(100) NOT NULL,
	password_salt varchar(100) NOT NULL,
	active boolean DEFAULT TRUE NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
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
	id_transaction serial PRIMARY KEY,
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
	FOREIGN KEY (id_trans_ba) REFERENCES expense_tracker.transaction_bank_accounts(id_trans_ba)
);




-- some exemplary data
TRUNCATE TABLE expense_tracker.bank_account_owner RESTART IDENTITY  CASCADE;
TRUNCATE TABLE expense_tracker.transaction_category RESTART IDENTITY  CASCADE;
TRUNCATE TABLE expense_tracker.users RESTART IDENTITY  CASCADE;
TRUNCATE TABLE expense_tracker.transaction_subcategory RESTART IDENTITY  CASCADE;
TRUNCATE TABLE expense_tracker.transaction_type RESTART IDENTITY  CASCADE;
TRUNCATE TABLE expense_tracker.bank_account_types RESTART IDENTITY  CASCADE;
TRUNCATE TABLE expense_tracker.transaction_bank_accounts RESTART IDENTITY  CASCADE;
TRUNCATE TABLE expense_tracker.transactions RESTART IDENTITY  CASCADE;

INSERT INTO expense_tracker.bank_account_owner(owner_name,owner_desc,user_login)
						  VALUES('Jan Karbowski','description 1',10),
							  ('Anna Karbowski','description 2',11);
						
INSERT INTO expense_tracker.users(user_login,user_name,user_password,password_salt)
						  VALUES('JaK10','Jan Karbowski','1234','JK1234'),
							    ('AnKa','Anna Karbowski','56789','AN56789');

						
INSERT INTO expense_tracker.transaction_type(transaction_type_name,transaction_type_desc)
						  VALUES('deposit','transaction type description 1'),
							    ('withdrawal','transaction type description 2');						
 

INSERT INTO expense_tracker.transaction_category(category_name,category_description)
						  VALUES('entertainment','category description'),
							('shopping','category description');
						
INSERT INTO expense_tracker.transaction_subcategory(id_trans_cat,subcategory_name,subcategory_description)
						  VALUES(1,'sport','swimming pool'),
							(2,'food','bred');
					
INSERT INTO expense_tracker.bank_account_types(ba_type,ba_desc,id_ba_own)
						  VALUES('Savings Account','bank account type desc',1),
							('Savings Account','bank account type desc',2);					
						
						
INSERT INTO expense_tracker.transaction_bank_accounts(id_ba_own,id_ba_typ,bank_account_name,bank_account_desc)
						  VALUES(1,1,'student account','description'),
							(2,2,'vip account','description');					

INSERT INTO expense_tracker.transactions(id_trans_ba,id_trans_cat,id_trans_subcat,id_trans_type,id_user,transaction_value)
						  VALUES(1,1,1,1,1,300),
							(2,2,2,2,2,100);						
						
						



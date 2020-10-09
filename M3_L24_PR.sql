--- 1.  Create schema expense_tracker.
CREATE SCHEMA expense_tracker;

--- 2. Create table bank_account_owner.
CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_owner(
	id_ba_own integer PRIMARY KEY,
	owner_name varchar(100) NOT NULL,
	owner_desc varchar(250), 
	user_login integer NOT NULL, 
	active boolean DEFAULT '1' NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

--- 3. Create table bank_account_types.
CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_types(
	id_ba_type integer PRIMARY KEY,
	ba_type varchar(50) NOT NULL,
	ba_desc varchar(250),
	active boolean DEFAULT '1' NOT NULL ,
	is_common_account boolean DEFAULT '1' NOT NULL,
	id_ba_own integer,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

--- 4. Create table transactions.

CREATE TABLE IF NOT EXISTS expense_tracker.transactions(
	id_transaction integer PRIMARY KEY,
	id_trans_ba integer,
	id_trans_cat integer,
	id_trans_subcat integer,
	id_trans_type integer,
	id_user integer,
	transaction_date date DEFAULT current_date,
	transaction_value NUMERIC(9,2),
	transaction_description TEXT,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp 
);

--- 5. Create table transaction_bank_account.
	
CREATE TABLE IF NOT EXISTS expense_tracker.transaction_bank_accounts(
	id_trans_ba integer PRIMARY KEY,
	id_ba_own integer,
	id_ba_typ integer,
	bank_account_name varchar(50) NOT NULL,
	bank_account_desc varchar(250),
	active boolean DEFAULT '1' NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
	);

--- 6. Create table transaction_category

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_category(
	id_trans_cat integer PRIMARY KEY,
	category_name varchar(50) NOT NULL,
	category_description varchar(250),
	active boolean DEFAULT '1' NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

--- 7. Create table transaction_subcategory.

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_subcategory(
	id_trans_subcat integer PRIMARY KEY,
	id_trans_cat integer,
	subcategory_name varchar(50) NOT NULL,
	subcategory_description varchar(250),
	active boolean DEFAULT '1' NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

--- 8. Create table transaction_type

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_type(
	id_trans_type integer PRIMARY KEY,
	transaction_type_name varchar(50) NOT NULL,
	transaction_type_desc varchar(250),
	active boolean DEFAULT '1' NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

--- 9. Create table users.

CREATE TABLE IF NOT EXISTS expense_tracker.users(
	id_user integer PRIMARY KEY,
	user_login varchar(25) NOT NULL,
	user_name varchar(50) NOT NULL,
	user_password varchar(100) NOT NULL,
	password_salt varchar(100) NOT NULL,
	active boolean DEFAULT '1' NOT NULL,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp
);

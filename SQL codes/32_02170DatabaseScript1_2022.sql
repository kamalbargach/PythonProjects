DROP DATABASE IF EXISTS bank_official;
CREATE DATABASE bank_official;
USE bank_official;

# --------------------------- CREATES ---------------------------
CREATE TABLE City (
	zip_code				VARCHAR(15),
    country					VARCHAR(60),
    city_name				VARCHAR(90),
    
    PRIMARY KEY(zip_code,country)
);

CREATE TABLE Exchange_Rate (
	currency				CHAR(3),
	commission				DECIMAL(6,3),
	rate					DECIMAL(16,8),
    
	PRIMARY KEY(currency)
);

CREATE TABLE Account_type (
	account_type_ID			VARCHAR(8),
	account_type_name		VARCHAR(15),
	credit_limit			DECIMAL(15,2),
    interest				DECIMAL(7,5),
    
	PRIMARY KEY(account_type_id)
);

CREATE TABLE Card_Brand (
	brand_ID				VARCHAR(8),
	brand_name				VARCHAR(40),
    
	PRIMARY KEY(brand_ID)
);

CREATE TABLE Card_Category (
	category_ID				VARCHAR(8),
	category_name			VARCHAR(40),
    
	PRIMARY KEY(category_ID)
);

CREATE TABLE Branch (
	branch_ID				VARCHAR(8),
	branch_name				VARCHAR(45),
	street_name				VARCHAR(80),
	street_number			VARCHAR(10),
	apartment_number		VARCHAR(10),
	zip_code				VARCHAR(15),
	country					VARCHAR(60),

	PRIMARY KEY(branch_ID),
	FOREIGN KEY(zip_code, country) REFERENCES City(zip_code, country) ON DELETE CASCADE
);

CREATE TABLE Employee (
	employee_CPR			CHAR(10),
	employee_first_name		VARCHAR(45),
	employee_last_name		VARCHAR(45),
	employee_title 			VARCHAR(15),
    employee_salary 		DECIMAL(10,2),
    employee_job_title 		VARCHAR(45),
    employee_email			VARCHAR(45),
    employee_phone			VARCHAR(16),
    employment_date			DATE,
    branch_ID				VARCHAR(8),

	PRIMARY KEY(employee_CPR),
	FOREIGN KEY(branch_ID) REFERENCES Branch(branch_ID) ON DELETE SET NULL
);

CREATE TABLE Customer (
	customer_CPR			CHAR(10),
	customer_first_name		VARCHAR(48),
	customer_last_name		VARCHAR(48),
	customer_title			ENUM("Mr.","Ms."),
	customer_email			VARCHAR(48),
	customer_phone			VARCHAR(17),
	branch_ID				VARCHAR(8),
	employee_CPR			CHAR(10),
    
	PRIMARY KEY(customer_CPR),
	FOREIGN KEY(branch_ID) REFERENCES Branch(branch_ID) ON DELETE SET NULL,
	FOREIGN KEY(employee_CPR) REFERENCES Employee(employee_CPR) ON DELETE SET NULL
);

CREATE TABLE Customer_Account (
	account_ID				VARCHAR(8),
	account_name			VARCHAR(24),
    currency				CHAR(3),
	standing				DECIMAL(15,2),
	open_date				DATE,
	account_type_ID			VARCHAR(8),
	customer_CPR			CHAR(10),
    
	PRIMARY KEY(account_ID),
	FOREIGN KEY(currency) REFERENCES Exchange_Rate(currency) ON DELETE SET NULL,
	FOREIGN KEY(account_type_ID) REFERENCES Account_Type(account_type_ID) ON DELETE SET NULL,
	FOREIGN KEY(customer_CPR) REFERENCES Customer(customer_CPR) ON DELETE SET NULL
);

CREATE TABLE Card_Type (
	card_type_ID			VARCHAR(8),
	brand_ID				VARCHAR(8),
	category_ID				VARCHAR(8),
	daily_amount			DECIMAL(8,2),
	daily_transactions 		SMALLINT,
	monthly_amount			DECIMAL(10,2),
	transaction_amount		DECIMAL(8,2),

	PRIMARY KEY(card_type_ID),
	FOREIGN KEY(brand_ID) REFERENCES Card_Brand(brand_ID) ON DELETE SET NULL,
	FOREIGN KEY(category_ID) REFERENCES Card_Category(category_ID) ON DELETE SET NULL
);

CREATE TABLE Card (
	card_number				CHAR(16),
	expiration_date			DATE,
	cvv						CHAR(3),
	pin_hash				VARCHAR(40),
	card_type_ID			VARCHAR(8),
	account_ID				VARCHAR(8),
    
	PRIMARY KEY(card_number, expiration_date),
	FOREIGN KEY(card_type_ID) REFERENCES Card_Type(card_type_ID) ON DELETE SET NULL,
	FOREIGN KEY(account_ID) REFERENCES Customer_Account(account_ID) ON DELETE SET NULL
);

CREATE TABLE Loan (
	Loan_ID               	VARCHAR(8), 
	Initial_Amount       	DECIMAL(15,2), 
	Loan_Amount           	DECIMAL(15,2),
	Start_Date            	DATE,
	End_Date              	DATE,
	Currency              	VARCHAR(3),
	Interest_Rate         	DECIMAL(3,3),
	Is_Variable_Interest  	BOOL,
	Customer_CPR          	CHAR(10),
    
	PRIMARY KEY(Loan_ID),
	FOREIGN KEY(Currency) REFERENCES Exchange_Rate(Currency) ON DELETE SET NULL,
	FOREIGN KEY(Customer_CPR) REFERENCES Customer(Customer_CPR) ON DELETE SET NULL
);

CREATE TABLE Loan_Payment (
	Loan_ID           		VARCHAR(8), 
	account_ID        		VARCHAR(8), 
	Payment_Timestamp 		TIMESTAMP,
	Amount            		DECIMAL(15,2),
    
	PRIMARY KEY(Loan_ID, account_ID, Payment_Timestamp),
	FOREIGN KEY(Loan_ID) REFERENCES Loan(Loan_ID) ON DELETE CASCADE,
	FOREIGN KEY(account_ID) REFERENCES Customer_Account(account_ID) ON DELETE CASCADE
);

CREATE TABLE Account_transaction (
    transaction_ID			VARCHAR(20),
	account_from			VARCHAR(20), 
	account_to				VARCHAR(20), 
	transaction_timestamp	TIMESTAMP,
	amount					DECIMAL(10,2),
    exchange_rate			DECIMAL(10,2),
    
	PRIMARY KEY(transaction_ID),
	FOREIGN KEY(account_from) REFERENCES Customer_account(account_ID) ON DELETE SET NULL,
    FOREIGN KEY(account_to) REFERENCES Customer_account(account_ID) ON DELETE SET NULL
);

# ---------------------- CONVERT FUNCTION ----------------------
CREATE FUNCTION convert_currency (in_amount DECIMAL(15,2), in_currency CHAR(3)) RETURNS DECIMAL(15,2)
RETURN in_amount * (SELECT rate FROM Exchange_Rate WHERE in_currency = currency);

# --------------------------- VIEWS ---------------------------
CREATE VIEW Customer_Standing AS
SELECT customer_cpr, customer_first_name, customer_last_name, SUM(convert_currency(standing, currency)) AS TotalStanding FROM Customer NATURAL JOIN Customer_Account GROUP BY customer_cpr;

CREATE VIEW cards_of_card_types AS
SELECT card.card_number,card.expiration_date,card_brand.brand_name,card_category.category_name
FROM card,card_type,card_brand,card_category
WHERE 
card.card_type_ID=card_type.card_type_ID AND
card_type.brand_ID=card_brand.brand_ID AND
card_type.category_ID=card_category.category_ID
ORDER BY card.expiration_date ASC;

# --------------------------- POPULATION ---------------------------
INSERT city VALUES
('1358','Denmark','Copenhagen'),
('1620','Denmark','Copenhagen'),
('2800','Denmark','Kgs Lyngby');

INSERT Exchange_Rate VALUES
('DKK','0','1'),
('EUR','0.5','7.5'),
('USD','2','6.69'),
('JPY','2','0.0055'),
('SEK','2','0.72'),
('NOK','2','1.55'),
('RUB','25','0.082');

INSERT Account_type VALUES
('111','Basic',1000,0.0270),
('222','Silver',5000,0.0235),
('333','Gold',25000,0.0210),
('444','Platinum',50000,0.0185),
('555','Black',250000,0.0145);

INSERT Card_Brand VALUES
('1','Visa'),
('2','Mastercard'),
('3','Maestro'),
('4','AMEX'),
('5','Chase');

INSERT Card_Category VALUES
('1','Debit'),
('2','Credit'),
('3','Prepaid'),
('4','Foreign currency'),
('5','Travel');

INSERT Branch VALUES
('HG98DC01', 'Group 8 Bank Norreport', 'Norre Volgade', '68','1','1358', 'Denmark'),
('SD38F82G', 'Group 8 Bank Vesterport', 'Vesterbrogade', '10','1','1620', 'Denmark'),
('NCEO8D01', 'Group 8 Bank Kgs Lyngby', 'Lyngby Hovedgade', '25','1','2800', 'Denmark');

INSERT Employee VALUES
('1403984598','Line','Hansen', 'Female', 210.00, 'Student Assistant IT', 'eh@bankmail.com', '004540879823', '2021-05-17', 'HG98DC01'),
('1708984791','Max','Mikkelsen', 'Male', 180.00, 'Student Assistant Finance', 'mm@bankmail.com', '0039875402', '1994-08-25', 'SD38F82G'),
('2911825248','Iben','Jacobsen', 'Female', 500.00, 'Director', 'ij@bankmail.com', '004562358788', '2005-03-11', 'NCEO8D01');

INSERT Customer VALUES
('0101001234','John','Doe','Mr.','johndoe@gmail.com','004512345678','HG98DC01','1708984791'),
('0104001234','Jane','Doe','Ms.','janedoe@gmail.com','004512341234','HG98DC01','1708984791'),
('1902552233','Ole','Petersen','Mr.','petermanden@yahoo.com','004542072069','NCEO8D01','1708984791'),
('3103776575','Sammuel','Jackson','Mr.','pulpfictionfan@live.com','0017603733399','SD38F82G','2911825248'),
('0611995061','Katrin','Á Sandi','Ms.','katrinas@olivant.fo','00298567843','NCEO8D01','2911825248');


INSERT Customer_Account VALUES
('ZvKNjsaK','John\'s Payment Account','DKK',-765.33,'2020-09-25','222','0101001234'),
('Q5qM7WZP','Jane\'s Savings Account','DKK',620000,'2015-04-01','222','0104001234'),
('7nImnLpM','Sam\'s dollar stash','USD',4538203.99,'2016-01-25','555','3103776575'),
('FH8fOeO2','Sam\'s crown storage','DKK',-35500,'2016-01-25','555','3103776575'),
('jaNIx9yy','Feriu konta hjá Katrin','EUR',84900,'2017-04-07','333','0611995061'),
('G5q5GWZS','Ole\'s Savings Account','DKK',11000,'2021-07-21','111','1902552233');

INSERT card_type VALUES
('1','3','1',1000.00,15,40000.00,20000),
('2','1','1',20000.00,30,100000.00,60000),
('3','2','2',1000.00,20,30000.00,10000),
('4','5','4',1500.00,14,40000.00,25000),
('5','4','5',20000.00,30,100000.00,60000);

INSERT card VALUES
('2004102028272948','2022-08-20','230','ghskjdfht3453bhj245h342v5b21','3','jaNIx9yy'),
('1592354980235782','2024-04-12','103','53uz348iotgjdgrf0h80vdsfhguh','3','Q5qM7WZP'),
('4568457648678345','2023-03-04','753','degfhj43g8h08h432978ghfg2h83','4','7nImnLpM'),
('7435634876523669','2021-12-09','345','jthgg80h438g0hbv28vbf882ghf8','1','Q5qM7WZP'),
('6458765465487849','2025-10-30','598','hj0gh438hfg328h8h2hosdfghj23','2','ZvKNjsaK'),
('2356782680724563','2026-11-12','634','sdfgjlkhjdfogihg089j8gfedgh8340g','5','FH8fOeO2');

INSERT Loan VALUES
("9H5eYOt0", 1250000.00, 136821.92, "2005-01-01", "2025-01-01", "DKK", .032, false, "0101001234"), 
("eg5V-19K", 12345.00, 8391.24, "2021-07-12", "2023-07-12", "DKK", .083, true, "0104001234"), 
("Q9KiNZRl", 60000.00, 1212.12, "2012-05-05", "2022-05-05", "USD", .051, false, "3103776575"), 
("JGlCHqpA", 3500.00, 1250.25, "2021-12-03", "2022-06-03", "DKK", .083, true, "3103776575"), 
("Kx4HFBR9", 2395000.00, 1741842.56, "2012-09-23", "2042-09-23", "EUR", .037, false, "0611995061");

INSERT Loan_Payment VALUES
("9H5eYOt0", "ZvKNjsaK", "2007-08-12 12:35:02", 371059.36),
("9H5eYOt0", "ZvKNjsaK", "2013-03-31 09:12:46", 371059.36),
("9H5eYOt0", "ZvKNjsaK", "2017-07-04 09:16:31", 371059.36),
("eg5V-19K", "Q5qM7WZP", "2022-01-08 14:34:28", 3953.76),
("Q9KiNZRl", "7nImnLpM", "2020-02-12 15:12:54", 58787.88),
("JGlCHqpA", "FH8fOeO2", "2022-03-26 11:11:11", 2249.75),
("Kx4HFBR9", "jaNIx9yy", "2016-09-03 10:03:57", 643157.44);

INSERT Account_transaction VALUES
('12345678901234567890','ZvKNjsaK','Q5qM7WZP','2022-01-04 08:35:26',540,1),
('23456789012345678901','Q5qM7WZP','FH8fOeO2','2022-02-01 16:11:00',1782,1),
('34567890123456789012','ZvKNjsaK','FH8fOeO2','2022-03-05 10:26:09',35,7.5),
('34567890123456789013','Q5qM7WZP','FH8fOeO2','2022-03-05 10:26:10',12300,1), 
('45678901234567890123','FH8fOeO2','Q5qM7WZP','2022-03-26 17:56:59',45000,1),
('45675867858657890745','ZvKNjsaK','FH8fOeO2','2022-03-27 12:47:23',130,7.5),
('46789012345678901234','ZvKNjsaK','7nImnLpM','2022-03-27 15:18:18',2300,6.69);


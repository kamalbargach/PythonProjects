SET SQL_SAFE_UPDATES = 0;
# ----------------------- DATA QUERIES -----------------------
# 7.1 Amount transferred
SELECT	
	acty.account_type_name,
    sum(actr.amount * actr.exchange_rate) amount_transferred_DKK
FROM Account_type AS acty
JOIN Customer_account AS ca
	ON ca.account_type_id = acty.account_type_id
JOIN Account_transaction AS actr
	ON actr.account_from = ca.account_id
GROUP BY acty.account_type_name
ORDER BY amount_transferred_DKK DESC;

# 7.2 Loan status
SELECT loan_id, initial_amount AS total, loan_amount AS remaining, SUM(amount) AS paid FROM Loan NATURAL JOIN Loan_Payment GROUP BY loan_id ORDER BY total DESC;

# 7.3 Accounts with negative standing
Select account_ID, standing, currency, customer_CPR, 
	(Select credit_limit 
	 From Account_Type 
	 Where Account_Type.account_type_ID = Customer_Account.account_type_ID) 
     As credit 
From Customer_Account 
Where standing < 0 
Order by standing;

# 7.4 Cards with high limits
SELECT
	card.card_number,
	card.expiration_date,
    card_type.monthly_amount,
    customer_account.customer_CPR,
    customer.employee_CPR,
    employee.employee_first_name,
    employee.employee_last_name,
    employee.employee_job_title,
    employee.employee_email,
    branch.branch_name
FROM card,card_type,customer_account,customer,employee,branch
WHERE 
	card.account_ID = customer_account.account_ID AND
	customer_account.customer_CPR = customer.customer_CPR AND
    customer.employee_CPR = employee.employee_CPR AND
    card.card_type_ID = card_type.card_type_ID AND
    employee.branch_ID = branch.branch_ID
GROUP BY card.account_ID
HAVING MAX(card_type.monthly_amount) > 50000.00
ORDER BY card_type.monthly_amount DESC;

# 7.5 Number of transactions
SELECT customer_CPR, customer_first_name, customer_last_name, account_from, COUNT(transaction_ID) 
FROM Customer NATURAL JOIN Customer_Account NATURAL JOIN Account_Transaction 
WHERE Customer_Account.account_ID = account_transaction.account_from 
GROUP BY customer_CPR
ORDER BY amount;

# ----------------------- MODIFICATIONS -----------------------
# 8.1 Update commission rates
Update Exchange_Rate 
Set commission = commission * 1.025 
Where commission > 1.5 And commission < 3;

Select * From Exchange_Rate;

# 8.2 Update credit limit
UPDATE Account_type
SET credit_limit = 6300 
WHERE account_type_name = "Silver";

#8.3 Update salary 
UPDATE Employee 
SET employee_salary =  employee_salary * 1.2 
WHERE employee_job_title 
LIKE '%Student Assistant%';
SELECT * FROM Employee;

# 8.4 Delete Mastercard credit cards
DELETE FROM card
WHERE card_type_ID IN (
	SELECT card_type.card_type_ID
    FROM card_type, card_category, card_brand
    WHERE
        card_type.brand_ID = card_brand.brand_ID AND
        card_type.category_ID = card_category.category_ID AND
        card_brand.brand_name = 'Mastercard' AND
        card_category.category_name = 'Credit'
);

# 8.5 Delete transactions
DELETE 
FROM Account_transaction
WHERE Account_transaction.amount * Account_transaction.exchange_rate < 1000
OR DATE(Account_transaction.transaction_timestamp) < NOW() - INTERVAL 1 MONTH;

#8.6 Delete employee
DELETE FROM Employee
WHERE employee_salary  < 200
AND DATE(Employee.employment_date) < NOW() - INTERVAL 10 YEAR;
SELECT * FROM Employee;

# ----------------------- Programming -----------------------
# 9.1 Event
SET GLOBAL event_scheduler = 1; # Enable events

CREATE EVENT Account_Interest
ON SCHEDULE EVERY 1 YEAR
DO UPDATE Customer_Account AS CA SET standing = standing * (1 + (SELECT interest FROM Account_Type AS ACT WHERE CA.account_type_id = ACT.account_type_id));

# 9.2 Trigger
DROP TRIGGER IF EXISTS Customer_Account_Before_Update
DELIMITER //
Create Trigger Customer_Account_Before_Update Before Update On Customer_Account For Each Row 
Begin
If convert_currency(NEW.standing, 'DKK') < -1 * (Select credit_limit From Account_Type Where Account_Type.account_type_ID = NEW.account_type_ID)
Then Signal SQLState 'HY000' Set mysql_errno = 1525, message_text = 'Insufficient credit, account standing would become too low!';
End If;
End//
DELIMITER ;

Update Customer_Account Set standing = -300000 Where account_ID = '7nImnLpM';
Update Customer_Account Set standing = -30000 Where account_ID = '7nImnLpM';
Update Customer_Account Set standing = -4000 Where account_ID = 'ZvKNjsaK';
Update Customer_Account Set standing = -2500 Where account_ID = 'G5q5GWZS';
Select account_ID, standing, currency From Customer_Account;

# 9.3 Function 1
DELIMITER //
CREATE FUNCTION number_of_cards_of_customer (f_customer_CPR CHAR(16)) RETURNS INT
BEGIN
	DECLARE f_count_of_cards INT;
	SELECT COUNT(*) INTO f_count_of_cards
	FROM card, customer_account
    WHERE
		customer_account.customer_CPR = f_customer_CPR AND
		card.account_ID = customer_account.account_ID;
    RETURN f_count_of_cards;
END//
DELIMITER ;

SELECT customer.customer_CPR, number_of_cards_of_customer('3103776575') AS 'Number of cards' FROM customer WHERE customer.customer_CPR = '3103776575';

# 9.4 Function 2
DROP FUNCTION IF EXISTS convert_currency;
DELIMITER //
CREATE FUNCTION convert_currency (in_amount DECIMAL(15,2), in_currency CHAR(3)) RETURNS DECIMAL(15,2)
RETURN in_amount * (SELECT rate FROM Exchange_Rate WHERE in_currency = currency)
//
DELIMITER ;

SELECT convert_currency(1000, 'USD');

# 9.5 Procedure
DROP PROCEDURE IF EXISTS open_account;
DELIMITER //
CREATE PROCEDURE open_account
(
	IN p_customer_CPR CHAR(10)
)
BEGIN
	DECLARE semi_random_new_ID CHAR(8);
    DECLARE semi_random_new_card_number CHAR(16);
    DECLARE semi_random_new_cvv CHAR(3);
    DECLARE semi_random_new_pin_hash CHAR(40);
    SELECT SUBSTR(MD5(RAND()), 1, 8) INTO semi_random_new_ID;
    SELECT SUBSTR(MD5(RAND()), 1, 16) INTO semi_random_new_card_number;
    SELECT FLOOR(100 + RAND() * 900) INTO semi_random_new_cvv;
    SELECT SUBSTR(MD5(RAND()), 1, 40) INTO semi_random_new_pin_hash;
	INSERT customer_account VALUES (semi_random_new_ID,'New basic account','DKK',0.00,CURRENT_DATE(),'111',p_customer_CPR);
    INSERT card VALUES (semi_random_new_card_number, DATE_ADD(CURRENT_DATE(), INTERVAL 3 YEAR), semi_random_new_cvv, semi_random_new_pin_hash, '1', semi_random_new_ID);
END //
DELIMITER ;

CALL open_account('0611995061');
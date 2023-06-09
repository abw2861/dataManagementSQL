
--Creates detailed table--
CREATE TABLE detailed_table (
	rental_id INT,
	amount NUMERIC(6,2),
	purchase_month INT,
	category_id INT,
	category_name VARCHAR(50)
	);
	
--Creates summary table--
CREATE TABLE summary_table (
	sales NUMERIC(6,2),
	category_name VARCHAR(50),
	purchase_month INT
);


--Extracts data from database and enters into detailed table--
INSERT INTO detailed_table (
	rental_id,
	amount,
	purchase_month,
	category_id,
	category_name
)
SELECT 
	DISTINCT payment.rental_id,
	payment.amount,
	EXTRACT (MONTH FROM payment.payment_date),
	film_category.category_id,
	category.name
FROM payment

INNER JOIN rental ON rental.rental_id = payment.rental_id
INNER JOIN inventory ON inventory.inventory_id = rental.inventory_id
INNER JOIN film_category ON film_category.film_id = inventory.film_id
INNER JOIN category ON category.category_id = film_category.category_id
ORDER BY category_id;

--Creates function to perform transformation--
CREATE OR REPLACE FUNCTION extract_month()
RETURNS INT 
LANGUAGE plpgsql
AS $$
DECLARE
	payment_month INT;
BEGIN	
	SELECT
		EXTRACT (MONTH FROM payment.payment_date)
	INTO payment_month
	FROM payment;
	RETURN payment_month;
END; $$



--Creates trigger function to continually update summary table--
CREATE OR REPLACE FUNCTION summary_table_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
	TRUNCATE summary_table;
	
	INSERT INTO summary_table
		SELECT
		SUM (amount),
		category_name,
		purchase_month
		FROM detailed_table
		GROUP BY category_name, purchase_month
		ORDER BY purchase_month ASC, category_name ASC;
	RETURN NEW;
END; $$

--Creates trigger statement to execute trigger function--
CREATE TRIGGER summary_table_trigger 
	AFTER INSERT
	ON detailed_table
	FOR EACH STATEMENT	
		EXECUTE PROCEDURE summary_table_update();
		
--Creates stored procedure to refresh all tables--
CREATE OR REPLACE PROCEDURE table_refresh()
LANGUAGE plpgsql
AS $$
BEGIN
	TRUNCATE detailed_table;
	
	INSERT INTO detailed_table (
	rental_id,
	amount,
	purchase_month,
	category_id,
	category_name
)
SELECT 
	DISTINCT payment.rental_id,
	payment.amount,
	EXTRACT (MONTH FROM payment.payment_date),
	film_category.category_id,
	category.name
FROM payment

INNER JOIN rental ON rental.rental_id = payment.rental_id
INNER JOIN inventory ON inventory.inventory_id = rental.inventory_id
INNER JOIN film_category ON film_category.film_id = inventory.film_id
INNER JOIN category ON category.category_id = film_category.category_id
ORDER BY category_id;
END; $$

--Call stored procedure to initiate table refresh-- 
CALL table_refresh();
	
	
	
	
	
	
	

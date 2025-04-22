-- 1. Calculate the sum of the user's 10 largest transactions 12476
-- First I'll create the CTE for the customer's data
WITH 12476_tnx_data AS (
	SELECT *
	FROM orders o
	-- Filter the data to not show null values 
	WHERE o.buyer_id = 12476 AND o.paid_at IS NOT NULL AND o.paid_at NOT IN ('NA', 'N/A', '')
	ORDER BY o.total DESC
	LIMIT 10
)
-- Then continue to just sum its total
SELECT SUM(total) AS sum_of_10_largest_tnx FROM 12476_tnx_data;
-- SELECT * FROM 12476_tnx_data;


-- 2. What is the trend of the number of transactions and total transaction value per month since January 2020
-- First create a CTE to filter out NA in all of the date cols
WITH tnx_data AS (
	SELECT 
		o.*, 
		DATE_FORMAT(o.paid_at, '%Y-%m-01') AS paid_month
	FROM orders o
	-- Filter the data to not show null values 
	WHERE o.paid_at IS NOT NULL AND o.paid_at NOT IN ('NA', 'N/A', '') 
	AND o.delivery_at IS NOT NULL AND o.delivery_at NOT IN ('NA', 'N/A', '')  
)
SELECT 
	paid_month,
	COUNT(*) AS number_of_tnx,
	SUM(total) AS total_tnx
FROM tnx_data
-- Now just filter it to show the data from January 2020 onwards
WHERE paid_month >= '2020-01-01'
GROUP BY paid_month
ORDER BY paid_month ASC;
	
	
-- 3. Who are the buyers with the highest number of transactions in January 2020, and what is the average transaction value?
-- First, filter out the tnx data like previously
WITH tnx_data AS (
	SELECT
		o.*
	FROM orders o
	-- Filter the data to not show null values
	WHERE o.paid_at IS NOT NULL AND o.paid_at NOT IN ('NA', 'N/A', '')
		AND o.delivery_at IS NOT NULL AND o.delivery_at NOT IN ('NA', 'N/A', '')
		AND o.paid_at >= '2020-01-01' AND o.paid_at <= '2020-01-30'
),
-- Create CTE to find the buyer with highest number of tnx
highest_num_tnx AS (
	SELECT
		buyer_id,
		COUNT(order_id) AS tnx_count,
		AVG(total) AS average_tnx
	FROM tnx_data
	GROUP BY buyer_id
)
SELECT * FROM highest_num_tnx
-- Now let's just sort it by the highest tnx and limit by 1
ORDER BY tnx_count DESC
LIMIT 1;


-- 4. Show big transactions in December 2019 approximately transaction value >= 20 million
-- First, filter out the tnx data like previously
WITH tnx_data AS (
	SELECT
		o.*
	FROM orders o
	-- Filter the data to not show null values
	WHERE o.paid_at IS NOT NULL AND o.paid_at NOT IN ('NA', 'N/A', '')
		AND o.delivery_at IS NOT NULL AND o.delivery_at NOT IN ('NA', 'N/A', '')
		AND o.paid_at >= '2019-12-01' AND o.paid_at <= '2019-12-30'
)
SELECT *
FROM tnx_data
WHERE total >= 20000000
ORDER BY total DESC;



-- 5. Create a query based on Best Selling Product Category in 2020
-- I'll just join the orders and products table, and filter the date to shows within 2020
WITH BestSellingProduct AS (
	SELECT
	    p.product_id,
	    p.desc_product AS product_description,
	    p.category,
	    SUM(od.quantity) AS order_qty,
	    COUNT(o.order_id) AS order_count,
	    SUM(o.total) AS order_sum_tnx
	FROM orders o
	JOIN order_details od ON o.order_id = od.order_id 
	LEFT JOIN products p ON od.product_id = p.product_id
	WHERE o.created_at >= '2020-01-01' 
	  AND o.created_at < '2021-01-01' 
	GROUP BY p.product_id, p.category, p.desc_product
)
-- See the top 10 of best sellling product category in 2020, sort it by order count because it shows how many times the product was purhased, thus made it as Best Sellig
SELECT * FROM BestSellingProduct ORDER BY order_qty DESC LIMIT 10;



-- 6. Create and search for buyers with high value
-- I'll just query the customer's LTV
-- First, filter out the tnx data like previously
WITH tnx_data AS (
	SELECT
		o.*
	FROM orders o
	-- Filter the data to not show null values
	WHERE o.paid_at IS NOT NULL AND o.paid_at NOT IN ('NA', 'N/A', '')
		AND o.delivery_at IS NOT NULL AND o.delivery_at NOT IN ('NA', 'N/A', '')
)
SELECT buyer_id, SUM(total) AS total_revenue FROM tnx_data GROUP BY buyer_id ORDER BY total_revenue DESC;
-- Query above is one of the KPI example, the rest usually depends on the company's appetite on deciding which customers are likely having high value.



-- 7. Who are the buyers who made at least 10 transactions with different zip codes in each transaction, and what is the total and average value of the transactions

SELECT 
	o.buyer_id,
	COUNT(o.order_id) AS order_count,
	COUNT(DISTINCT o.kodepos) AS distinct_zc, -- Count EVERY DISTINCT OR different zip codes FOR EVERY order_id
	SUM(o.total) AS total_tnx,
	AVG(o.total) AS average_tnx_val
FROM orders o
GROUP BY o.buyer_id
HAVING COUNT(o.order_id) >= 10
AND COUNT(o.order_id) = COUNT(DISTINCT o.kodepos); -- making sure EVERY tnx has different zip codes.
	
	

-- 8. Who are the users with at least 7 purchase transactions and how many purchase and sales transaction have they made?
-- I'll just join the userss and orders table
SELECT 
	u.user_id,
	u.nama_user,
	u.kodepos,
	u.email,
	COUNT(o.order_id) AS order_count,
	SUM(o.total) AS total_sales_tnx
FROM users u
LEFT JOIN orders o ON u.user_id = o.buyer_id
GROUP BY u.user_id, u.nama_user, u.kodepos, u.email
HAVING COUNT(o.order_id) >= 7
ORDER BY total_sales_tnx DESC;



-- 9. Who are the buyers with at least 8 transactions, an average quantity of items transaction of more than 10 and the largest total transaction value
-- First create 2 of CTEs, to sum its qty in grouped and to create buyer summary, then just join the user table if we need the detail information of the buyer
WITH order_qty AS (
    SELECT
        od.order_id,
        SUM(od.quantity) AS total_order_quantity
    FROM order_details od
    GROUP BY od.order_id
),
buyer_summary AS (
    SELECT
        o.buyer_id,
        COUNT(o.order_id) AS order_count,
        AVG(oq.total_order_quantity) AS avg_item_tnx, 
        SUM(o.total) AS total_tnx
    FROM orders o
    JOIN order_qty oq ON o.order_id = oq.order_id 
    GROUP BY o.buyer_id
)
SELECT bs.*, u.* FROM buyer_summary bs JOIN users u ON bs.buyer_id = u.user_id HAVING order_count >= 8 AND avg_item_tnx > 10
-- Now just find its largest tnx value and limit by 1 
ORDER BY total_tnx DESC
LIMIT 1;



-- 10. What is the average, minimum, and maximum time it takes to settle payments per month, and how many transactions are paid each month?
-- Create base CTE as same as before
WITH tnx_data AS (
	SELECT
		o.*
	FROM orders o
	-- Filter the data to not show null values
	WHERE o.paid_at IS NOT NULL AND o.paid_at NOT IN ('NA', 'N/A', '')
		AND o.delivery_at IS NOT NULL AND o.delivery_at NOT IN ('NA', 'N/A', '')
),
tnx_date AS (
	SELECT 
		t.order_id,
		t.created_at, 
		t.paid_at,
		DATE_FORMAT(t.created_at, '%Y-%m') AS order_month, 
		DATEDIFF(t.paid_at, t.created_at) AS settled_payment_days
	FROM tnx_data t ORDER BY order_month ASC
)
SELECT 
	order_month,
	AVG(settled_payment_days) AS avg_settled_payment_days,
	MIN(settled_payment_days) AS min_settled_payment_days,
	MAX(settled_payment_days) AS max_settled_payment_days,
	COUNT(order_id) AS tnx_count
FROM tnx_date
GROUP BY order_month
ORDER BY order_month ASC;
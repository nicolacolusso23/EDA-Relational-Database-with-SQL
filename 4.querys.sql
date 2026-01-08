-- ==========================================================================================
-- DATA QUALITY & CLEANING
-- ==========================================================================================

-- Check for transactions with NULL total_amount

-- Identify transaction lines with missing final monetary values.

-- This is a data quality validation step.

SELECT
	*
FROM fact_pos_logs
WHERE total_amount IS NULL;


-- Delete transactions with NULL total_amount

-- Remove incomplete or invalid transactions that would distort

DELETE FROM fact_pos_logs
WHERE total_amount IS NULL;



-- ==========================================================================================
-- SALES RANKING
-- ==========================================================================================

-- Products sold from most to least

-- Aggregate total quantities per item to identify best-sellers and low-performing products.

-- Useful for inventory planning, menu optimization, and sales strategy evaluation.

SELECT
    i.item_name,
    SUM(f.quantity) AS total_quantity,
    SUM(f.total_amount) AS total_sold
FROM fact_pos_logs f
JOIN items_table i ON f.item_id = i.item_id
GROUP BY i.item_name
ORDER BY total_sold DESC;


-- Stores ranked from highest to lowest sales

-- Aggregate total quantity of items sold per store to evaluate store performance.

-- Useful for operational monitoring and identifying top-performing locations.

SELECT
    s.store_name,
    SUM(f.quantity) AS total_items,
    SUM(f.total_amount) AS total_sold
FROM fact_pos_logs f
JOIN stores_table s ON f.store_id = s.store_id
GROUP BY s.store_name
ORDER BY total_items DESC;


-- Customers ranked from highest to lowest spending

-- Calculate total spending per customer to identify top clients and potential loyalty program targets.

-- Useful for marketing, rewards programs, and revenue analysis.

SELECT
    c.customer_name,
    SUM(f.total_amount) AS total_spent,
    c.loyalty_member
FROM fact_pos_logs f
JOIN customers_table c ON f.customer_id = c.customer_id
GROUP BY c.customer_name, loyalty_member
ORDER BY total_spent DESC
LIMIT 10;


-- Compare sales of vegetarian and non-vegetarian items

-- Aggregate quantities sold by item type to analyze dietary trends and menu composition.

-- Useful for menu design, promotional offers, and customer preference insights.

SELECT
    CASE WHEN i.is_vegetarian THEN 'Vegetarian' ELSE 'Non-Vegetarian' END AS item_type,
    SUM(f.quantity) AS total_quantity_sold
FROM fact_pos_logs f
JOIN items_table i ON f.item_id = i.item_id
GROUP BY item_type
ORDER BY total_quantity_sold DESC;



-- ==========================================================================================
-- MODIFIER ANALYSIS
-- ==========================================================================================

-- Aggregation (COUNT), GROUP BY, boolean expression

-- Count orders with or without modifiers

-- Measure how often customers customize items versus ordering default products.

SELECT
    CAST(modifier IS NOT NULL AS BOOLEAN) AS has_modifier,
    COUNT(*) AS total_orders
FROM fact_pos_logs
GROUP BY has_modifier;


-- Aggregation (COUNT), GROUP BY, ORDER BY

-- Visualize the modifiers and their frequency

-- Identify the most commonly used modifiers to understand customization behavior.

SELECT
	modifier,
	COUNT(*) AS total_quantity
FROM fact_pos_logs
GROUP BY modifier
ORDER BY total_quantity DESC;


-- JOIN, conditional aggregation (CASE WHEN), HAVING

-- Counters of sauce modifiers per item

-- Analyze how specific modifiers (Extra Sauce / No Sauce) are distributed per item.

-- Useful for menu optimization and operational planning.

SELECT
    i.item_name,
    SUM(CASE WHEN f.modifier = 'Extra Sauce' THEN 1 ELSE 0 END) AS extra_sauce_count,
    SUM(CASE WHEN f.modifier = 'No Sauce' THEN 1 ELSE 0 END) AS no_sauce_count,
    SUM(quantity) as total_quantity
FROM fact_pos_logs f
JOIN items_table i ON f.item_id = i.item_id
GROUP BY i.item_name
HAVING
    SUM(CASE WHEN f.modifier = 'Extra Sauce' THEN 1 ELSE 0 END) > 0
    OR
    SUM(CASE WHEN f.modifier = 'No Sauce' THEN 1 ELSE 0 END) > 0
ORDER BY total_quantity DESC;



-- ==========================================================================================
-- TIME-BASED SALES ANALYSIS
-- ==========================================================================================

-- Aggregation (SUM, COUNT), EXTRACT, GROUP BY

-- Total sales per hour of the day

-- Identify peak revenue hours and compare order volume and average order value.

SELECT
    EXTRACT(HOUR FROM transaction_datetime) AS hour_of_day,
    SUM(total_amount) AS total_sold,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_amount)::numeric / COUNT(DISTINCT order_id), 2) AS avg_sold_per_order
FROM fact_pos_logs
GROUP BY hour_of_day
ORDER BY avg_sold_per_order DESC;


-- CTEs (WITH), aggregation, CROSS JOIN

-- Count of orders below and above the average at 20:00

-- Compare individual order totals against the hourly average

-- to understand distribution of order values at dinner time.

WITH order_totals AS (
    SELECT
        order_id,
        SUM(total_amount) AS order_total
    FROM fact_pos_logs
    WHERE EXTRACT(HOUR FROM transaction_datetime) = 20
    GROUP BY order_id
),
avg_sales AS (
    SELECT AVG(order_total) AS avg_order_total
    FROM order_totals
)
SELECT
    SUM(CASE WHEN o.order_total > a.avg_order_total THEN 1 ELSE 0 END) AS orders_above_avg,
    SUM(CASE WHEN o.order_total < a.avg_order_total THEN 1 ELSE 0 END) AS orders_below_avg
FROM order_totals o
CROSS JOIN avg_sales a;


-- Count of orders below and above the average at 11:00

-- Same analytical approach as above, applied to a different time window

-- to compare morning vs evening purchasing behavior.

WITH order_totals AS (
    SELECT
        order_id,
        SUM(total_amount) AS order_total
    FROM fact_pos_logs
    WHERE EXTRACT(HOUR FROM transaction_datetime) = 11
    GROUP BY order_id
),
avg_sales AS (
    SELECT AVG(order_total) AS avg_order_total
    FROM order_totals
)
SELECT
    SUM(CASE WHEN o.order_total > a.avg_order_total THEN 1 ELSE 0 END) AS orders_above_avg,
    SUM(CASE WHEN o.order_total < a.avg_order_total THEN 1 ELSE 0 END) AS orders_below_avg
FROM order_totals o
CROSS JOIN avg_sales a;


-- JOIN, aggregation

-- Count of items sold at 11:00

-- Identify top-selling items during a specific hour to support demand forecasting and staffing decisions.

SELECT
    i.item_name,
    i.price,
    SUM(f.quantity) AS total_quantity,
    SUM(f.quantity * i.price) AS total_sold
FROM fact_pos_logs f
JOIN items_table i ON f.item_id = i.item_id
WHERE EXTRACT(HOUR FROM f.transaction_datetime) = 11  
GROUP BY i.item_name, i.price
ORDER BY total_quantity DESC;



-- ==========================================================================================
-- CUSTOMER & LOYALTY ANALYSIS
-- ==========================================================================================

-- VIEW, aggregation, LEFT JOIN

-- Create VIEW of total spending, quantity, and orders per customer

-- Create a reusable analytical layer summarizing customer activity.

CREATE OR REPLACE VIEW customers_orders AS
SELECT
    c.customer_id,
    SUM(f.total_amount) AS total_spent,
    SUM(quantity) as total_quantity,
    COUNT(DISTINCT order_id) AS total_orders
FROM customers_table c
LEFT JOIN fact_pos_logs f
    ON c.customer_id = f.customer_id
GROUP BY c.customer_id
ORDER BY total_spent DESC;
-- Inspect customer aggregates
SELECT *
FROM customers_orders
ORDER BY total_spent DESC;  


-- Average spending and orders by loyalty membership

-- Evaluate the effectiveness of the loyalty program by comparing customer behavior across segments.

SELECT
    c.loyalty_member,
    COUNT(*) AS customers,
    ROUND(AVG(co.total_spent), 2) AS avg_spent,
    ROUND(AVG(co.total_orders), 2) AS avg_orders,
    SUM(co.total_spent) AS total_spent
FROM customers_orders co
JOIN customers_table c
    ON co.customer_id = c.customer_id
GROUP BY c.loyalty_member;


-- JOIN, aggregation, GROUP BY

-- Average spending and orders per store

-- Compare store performance based on customer-level metrics.

SELECT
    s.store_name,
    COUNT(DISTINCT co.customer_id) AS customers_count,
    ROUND(AVG(co.total_spent), 2) AS avg_spent,
    ROUND(AVG(co.total_orders), 2) AS avg_orders
FROM customers_orders co
JOIN fact_pos_logs f
    ON co.customer_id = f.customer_id
JOIN stores_table s
    ON f.store_id = s.store_id
GROUP BY s.store_name
ORDER BY avg_spent DESC;



-- ==========================================================================================
-- DISCOUNT DISTRIBUTION ANALYSIS
-- ==========================================================================================

-- Count total sales per month, number of sales with discount,

-- and calculate the percentage of discounted sales per month.

-- Useful for analyzing discount trends over time.

WITH monthly_sales AS (
    SELECT
        date_trunc('month', transaction_datetime) AS month,
        COUNT(*) AS total_sales,
        COUNT(*) FILTER (WHERE discount_id >= 234) AS discount_sales
    FROM fact_pos_logs
    GROUP BY month
)
SELECT
    TO_CHAR(month, 'YYYY-MM') AS month,
    total_sales,
    discount_sales,
    ROUND(discount_sales::numeric / total_sales * 100, 2) AS pct_discounted
FROM monthly_sales
ORDER BY pct_discounted DESC;


-- CTE, JOIN, aggregation, NULLIF

-- Discount usage percentage per store

-- Measure the relative weight of discounted items per store, useful for evaluating promotion strategies and store behavior.

WITH store_totals AS (
    SELECT
        store_id,
        SUM(quantity) AS total_items
    FROM fact_pos_logs
    GROUP BY store_id
)
SELECT
    d.discount_id,
    d.discount_name,
    s.store_name,
    ROUND(SUM(f.quantity)::numeric / NULLIF(st.total_items,0) * 100, 2) AS pct_per_store
FROM fact_pos_logs f
JOIN stores_table s ON f.store_id = s.store_id
JOIN discounts_table d ON f.discount_id = d.discount_id
JOIN store_totals st ON st.store_id = s.store_id
WHERE f.discount_id <> 0
GROUP BY d.discount_id, d.discount_name, s.store_name, st.total_items
ORDER BY d.discount_id, pct_per_store DESC;

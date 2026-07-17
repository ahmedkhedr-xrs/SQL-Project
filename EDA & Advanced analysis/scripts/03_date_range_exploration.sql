/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    - To determine the temporal boundaries of key data points.
    - To understand the range of historical data.

SQL Functions Used:
    - MIN(), MAX(), DATEDIFF()
===============================================================================
*/

-- Determine first and last opened branch Date
SELECT 
    MIN(open_date) AS first_open_branch ,
    MAX(open_date) AS last_open_branch
FROM gold.dim_branches

-- Determine the first and last order date and the total duration in months
SELECT 
    MIN(order_date) AS first_order ,
    MAX(order_date) AS last_order ,
    DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) order_range_months
FROM gold.fact_sales


-- Find the youngest and oldest customer based on birthdate
SELECT 
    MIN(birthdate) AS  oldest_birthdate,
    DATEDIFF(YEAR,MIN(birthdate),GETDATE()) AS oldest_age,
    MAX(birthdate)  AS youngest_birthdate,
    DATEDIFF(YEAR,MAX(birthdate),GETDATE()) AS youngest_age
FROM gold.dim_customers


-- Find first and latest date we add product to our products list
SELECT 
    MIN(start_date) first_product_date,
    MAX(start_date) last_product_date
FROM gold.dim_products
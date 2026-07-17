/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.
    - To show 

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
    -- Another Functionos : ROLLUP(), CAST(), COALESCE()     
===============================================================================
*/

-- Analyse sales performance over time
-- Quick Date Functions
SELECT 
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) total_sales,
    SUM(quantity) total_quantity,
    COUNT(DISTINCT order_number) total_orders ,
    COUNT(DISTINCT customer_key) total_customers 
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date) , MONTH(order_date)
ORDER BY 1 ,2 ;

-- DATETRUNC() & ROLLUP()
SELECT 
    COALESCE(CAST(DATETRUNC(MONTH,order_date) AS VARCHAR(50)),'Total') AS order_date,
    SUM(sales_amount) total_sales,
    SUM(quantity) total_quantity,
    COUNT(DISTINCT order_number) total_orders ,
    COUNT(DISTINCT customer_key) total_customers 
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY ROLLUP (DATETRUNC(MONTH,order_date))
ORDER BY order_date ;

-- FORMAT()
SELECT
    FORMAT(order_date, 'yyyy-MMM') AS order_date,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity ,
    COUNT(DISTINCT order_number) total_orders ,
    COUNT(DISTINCT customer_key) AS total_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM');
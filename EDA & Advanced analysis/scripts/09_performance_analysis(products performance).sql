/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/

/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */

-- CTE to prepare need data and apply join and group by operations
WITH yearly_product_sales AS (
    SELECT 
        YEAR(f.order_date) order_year,
        p.product_key,
        p.product_name ,
        SUM(sales_amount) current_sales 
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date) , p.product_key ,p.product_name
) 

-- Main Query 
SELECT 
    order_year ,
    product_key,
    product_name ,
    current_sales ,
    -- average sales for each product & compare it with each year sales for this product
    AVG(current_sales) OVER(PARTITION BY product_key) AS avg_sales ,
    current_sales - AVG(current_sales) OVER(PARTITION BY product_key) AS diff_avg ,
    CASE 
        WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_key) > 0 THEN 'Above Avg' 
        WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_key) < 0 THEN 'Below Avg' 
        ELSE 'Avg'
    END AS avg_change ,
    -- Year-over-Year Analysis : compare sales of the product in a specific year with the sales of previous year
    LAG(current_sales) OVER(PARTITION BY product_key ORDER BY order_year) AS pr_year_sales ,
    current_sales - LAG(current_sales) OVER(PARTITION BY product_key ORDER BY order_year) AS diff_pr_year_sales ,
    CASE 
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_key ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_key ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pr_year_change
FROM yearly_product_sales
ORDER BY   product_name , order_year 

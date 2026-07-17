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

/* Analyze the yearly performance of branches by comparing their sales 
to both the average sales performance of the branch and the previous year's sales */


-- CTE to prepare need data and apply join and group by operations
WITH yearly_branch_sales AS (
    SELECT 
        YEAR(order_date) order_year ,
        branch_name , 
        SUM(sales_amount) current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_branches b
    ON f.branch_key = b.branch_key
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date) , branch_name 
    )

-- Main Query 
SELECT 
    order_year ,
    branch_name ,
    current_sales ,
    -- average sales for each product & compare it with each year sales for this product
    AVG(current_sales) OVER(PARTITION BY branch_name) AS avg_sales ,
    current_sales - AVG(current_sales) OVER(PARTITION BY branch_name) AS diff_avg ,
    CASE 
        WHEN current_sales - AVG(current_sales) OVER(PARTITION BY branch_name) > 0 THEN 'Above Avg' 
        WHEN current_sales - AVG(current_sales) OVER(PARTITION BY branch_name) < 0 THEN 'Below Avg' 
        ELSE 'Avg'
    END AS avg_change ,
    -- Year-over-Year Analysis : compare sales of the product in a specific year with the sales of previous year
    LAG(current_sales) OVER(PARTITION BY branch_name ORDER BY order_year) AS pr_year_sales ,
    current_sales - LAG(current_sales) OVER(PARTITION BY branch_name ORDER BY order_year) AS diff_pr_year_sales ,
    CASE 
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY branch_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY branch_name ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pr_year_change
FROM yearly_branch_sales
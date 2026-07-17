/*
===============================================================================
Part-to-Whole Analysis (Branches)
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/

-- Which categories contribute the most to overall sales?
WITH category_sales AS (
    SELECT 
        b.branch_name ,
        SUM(f.sales_amount) AS branch_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_branches b
    ON f.branch_key = b.branch_key
    GROUP BY b.branch_name
)

SELECT 
    branch_name ,
    branch_sales ,
    SUM(branch_sales) OVER() AS overall_sales ,
    CAST(ROUND(CAST(branch_sales AS float) /  SUM(branch_sales) OVER() * 100,2)AS nvarchar(20)) + '%' AS percentage_of_total
FROM category_sales
ORDER BY branch_sales DESC
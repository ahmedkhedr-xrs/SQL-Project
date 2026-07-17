/*
===============================================================================
Part-to-Whole Analysis (products category)
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
        p.category_name ,
        SUM(f.sales_amount) AS category_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
    GROUP BY p.category_name
)

SELECT 
    category_name ,
    category_sales ,
    SUM(category_sales) OVER() AS overall_sales ,
    CAST(ROUND(CAST(category_sales AS float) /  SUM(category_sales) OVER() * 100,2)AS nvarchar(20)) + '%' AS percentage_of_total
FROM category_sales
ORDER BY category_sales DESC
/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.

SQL Functions Used:
    - Window Ranking Functions: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
    - Clauses: GROUP BY, ORDER BY
===============================================================================
*/


-- Which 5 products Generating the Highest Revenue?
-- 1- Simple Ranking
SELECT TOP 5
    p.product_key ,
    p.product_name ,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key 
GROUP BY p.product_key , product_name
ORDER BY total_sales DESC ;


-- 2- Complex but Flexibly Ranking Using Window Functions
SELECT *
FROM (
    SELECT 
        p.product_key ,
        p.product_name ,
        SUM(f.sales_amount) AS total_sales,
        DENSE_RANK() OVER(ORDER BY SUM(f.sales_amount) DESC) AS product_rank
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
    GROUP BY p.product_key , p.product_name ) t
WHERE product_rank <= 5 ;


-- TOP three branches generate the most orders
SELECT TOP 3
    branch_name ,
    COUNT(*) AS total_orders 
FROM gold.fact_sales f
LEFT JOIN gold.dim_branches b
ON f.branch_key = b.branch_key
GROUP BY branch_name 
ORDER BY total_orders DESC ;


-- What are the 5 worst-performing products in terms of sales?
SELECT TOP 5
    p.product_key ,
    p.product_name ,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key 
GROUP BY p.product_key , product_name
ORDER BY total_sales ;


-- Find the top 10 customers who have generated the highest revenue
SELECT TOP 10
    c.customer_key ,
    c.first_name ,
    c.last_name ,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key , c.first_name , c.last_name
HAVING c.customer_key IS NOT NULL
ORDER BY total_revenue  DESC ;



-- The 5 customers with the fewest orders placed
SELECT TOP 5
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY 
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders ;
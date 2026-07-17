/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()
===============================================================================
*/

-- Calculate the total sales per month , average price
-- ,the running total of sales over time and the moving average of prices
SELECT 
    order_date ,
    total_sales ,
    SUM(total_sales) OVER(ORDER BY order_date) AS runing_total_sales ,
    AVG(average_price) OVER(ORDER BY order_date) AS moving_average_price
FROM(
    SELECT 
        DATETRUNC(MONTH,order_date) AS order_date,
        SUM(sales_amount) AS total_sales ,
        AVG(price) AS average_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH,order_date)
) t ; 

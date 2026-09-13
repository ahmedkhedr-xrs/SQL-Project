/*
===============================================================================
Branch Report
===============================================================================
Purpose:
    - This report consolidates key branch metrics and behaviors.

Highlights:
    1. Gathers essential fields such as branch key , branch name, city, and open date.
    2. Aggregates branch-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in years)
    4. Calculates valuable KPIs:
		- Average Orders per Month
		- Average Order Revenue	  
		- Average Monthly Revenue 
		- Average Yearly Revenue         
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_branches
-- =============================================================================
IF OBJECT_ID('gold.report_branches', 'V') IS NOT NULL
    DROP VIEW gold.report_branches;
GO

CREATE VIEW gold.report_branches AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_branches
---------------------------------------------------------------------------*/
SELECT 
	f.order_number ,
	f.product_key ,
	f.customer_key ,
	f.order_date ,
	f.sales_amount ,
	f.quantity ,
	b.branch_key ,
	b.branch_name , 
	b.city ,
	b.open_date 
FROM gold.fact_sales f
LEFT JOIN gold.dim_branches b
ON f.branch_key = b.branch_key
WHERE f.order_date IS NOT NULL 
),

branch_aggregations AS (
/*---------------------------------------------------------------------------
2) branch Aggregations: Summarizes key metrics at the branch level
---------------------------------------------------------------------------*/
SELECT 
	branch_key ,
	branch_name , 
	city ,
	open_date ,
	DATEDIFF(YEAR , open_date , GETDATE()) AS lifespan_year ,
	MAX(order_date) last_order_date,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales ,
	SUM(quantity) AS total_quantity
FROM base_query
GROUP BY 
	branch_key ,
	branch_name , 
	city ,
	open_date
)
/*---------------------------------------------------------------------------
  3) Final Query: Combines all branches results into one output
---------------------------------------------------------------------------*/
SELECT 
	branch_key ,
	branch_name ,
	city ,
	open_date ,
	lifespan_year ,
	total_orders, 
	total_customers,
	total_sales, 
	total_quantity,
	-- Average Orders per Month
	CASE 
	WHEN DATEDIFF(MONTH,open_date,last_order_date) = 0 THEN 0 -- if a new branches is recently open
	ELSE total_orders / DATEDIFF(MONTH,open_date,last_order_date) 
	END AS avg_orders_per_month  ,
	-- Average Price per Order
	CASE
	WHEN total_orders = 0 THEN 0
	ELSE ROUND(total_sales / CONVERT(float,total_orders),2)
	END AS avg_order_price ,
	-- Average Monthly Revenue  
	CASE 
	WHEN DATEDIFF(MONTH,open_date,last_order_date) = 0 THEN 0 
	ELSE total_sales / DATEDIFF(MONTH,open_date,last_order_date) 
	END AS avg_monthly_revenue  ,
	-- Average Yearly Revenue  
	CASE 
	WHEN DATEDIFF(YEAR,open_date,last_order_date) = 0 THEN 0 
	ELSE total_sales / DATEDIFF(YEAR,open_date,last_order_date) 
	END AS avg_yearly_revenue  
FROM branch_aggregations
/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    - To explore the structure of dimension tables.
	
SQL Functions Used:
    - DISTINCT
    - ORDER BY
===============================================================================
*/

-- Retrieve a list of branches it is cites and open date
SELECT 
    city ,
    branch_name ,
    open_date
FROM gold.dim_branches
ORDER BY city , branch_name , open_date

-- Retrieve a list of unique cites from which customers originate
SELECT DISTINCT city
FROM gold.dim_customers
ORDER BY city

-- Retrieve a list of unique categories, subcategories, and products
SELECT DISTINCT
    category_name ,
    sub_category ,
    prodouct_name
FROM gold.dim_products
ORDER BY category_name , sub_category , prodouct_name
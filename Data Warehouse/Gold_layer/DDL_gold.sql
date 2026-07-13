/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
iF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key, -- Surrogate key
	ect.cst_id						   AS customer_id,
	ect.cst_key						   AS customer_number,
	ect.cst_firstname				   AS first_name,
	ect.cst_lastname				   AS last_name,
	cr.REGION						   AS country,
	ect.cst_marital_status			   AS marital_status,
	CASE 
	WHEN ect.cst_gndr != 'n/a' THEN ect.cst_gndr -- erp system is master
	ELSE COALESCE(cd.GEN,'n/a')	-- user crm data when no data on erp
	END								   AS gender ,
	cd.BDATE						   AS birthdate,
	ect.cst_create_date				   AS create_date
FROM silver.erp_store_customers ect
LEFT JOIN silver.crm_customer_demographics cd 
	ON cd.CID = ect.cst_key
LEFT JOIN silver.crm_customer_region cr
	ON ect.cst_id = cr.CID
GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY ep.prd_start_dt , ep.prd_key) AS product_key ,
	ep.prd_id AS product_id,
	ep.prd_key AS product_number,
	ep.prd_nm  AS product_name,
	cr.ID AS category_id,
	cr.CAT AS category_name, 
	cr.SUBCAT AS sub_category,
	cr.WARRANTY AS warranty,
	ep.prd_cost AS cost,
	ep.prd_start_dt AS start_date 
FROM silver.erp_store_products ep
LEFT JOIN silver.crm_category_reference cr
	ON ep.general_prd_key = cr.ID
WHERE ep.prd_end_dt IS NULL   -- Filter out all historical data
GO


-- =============================================================================
-- Create Dimension: gold.dim_branches
-- =============================================================================
IF OBJECT_ID('gold.dim_branches', 'V') IS NOT NULL
    DROP VIEW gold.dim_branches;
GO

CREATE VIEW gold.dim_branches AS 
SELECT 
	branch_id AS branch_key,
	branch_name,
	city,
	open_date
FROM silver.erp_store_branches
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS 
SELECT 
	 s.sls_ord_num AS order_number,
	 p.product_key ,  -- foregin key from dim_products
	 c.customer_key , -- foregin key from dim_customers
	 s.sls_store_id AS branch_key,
	 s.sls_order_dt AS order_date,
	 s.sls_ship_dt  AS shipping_date,
	 s.sls_due_dt   AS due_date,
	 s.sls_sales    AS sales,
	 s.sls_quantity	AS quantity,
	 s.sls_price	AS price
FROM silver.erp_store_sales s
LEFT JOIN gold.dim_customers c
	ON c.customer_id = s.sls_cust_id
LEFT JOIN gold.dim_products p
	ON p.product_number = s.sls_prd_key

GO

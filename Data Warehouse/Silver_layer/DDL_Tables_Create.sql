/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'silver' Tables
===============================================================================
*/



IF OBJECT_ID('silver.erp_store_branches', 'U') IS NOT NULL
    DROP TABLE silver.erp_store_branches;
GO
CREATE TABLE silver.erp_store_branches (
	branch_id   INT ,
	branch_name NVARCHAR(50) ,
	city        NVARCHAR(50) ,
	open_date   DATE ,
	dwh_batch_name     NVARCHAR(50) , 
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_update_date DATETIME2 DEFAULT NULL
);
GO


IF OBJECT_ID('silver.erp_store_customers', 'U') IS NOT NULL
    DROP TABLE silver.erp_store_customers;
GO
CREATE TABLE silver.erp_store_customers (
	cst_id			   INT ,
	cst_key			   NVARCHAR(50) ,
	cst_firstname      NVARCHAR(50) ,
	cst_lastname       NVARCHAR(50) ,
	cst_marital_status NVARCHAR(50),
	cst_gndr		   NVARCHAR(50) , 
	cst_create_date	   DATE ,
	dwh_batch_name     NVARCHAR(50) , 
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_update_date DATETIME2 DEFAULT NULL  
);
GO


IF OBJECT_ID('silver.erp_store_products', 'U') IS NOT NULL
    DROP TABLE silver.erp_store_products;
GO
CREATE TABLE silver.erp_store_products (
	prd_id		 INT ,
	general_prd_key NVARCHAR(50) ,
	prd_key		 NVARCHAR(50) ,
	prd_nm		 NVARCHAR(50) ,
	prd_cost	 INT ,
	prd_line     NVARCHAR(50) ,
	prd_start_dt DATE ,
	prd_end_dt   DATE ,
	dwh_batch_name     NVARCHAR(50) , 
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_update_date DATETIME2 DEFAULT NULL   
);
GO


IF OBJECT_ID('silver.erp_store_sales', 'U') IS NOT NULL
    DROP TABLE silver.erp_store_sales;
GO
CREATE TABLE silver.erp_store_sales (
	sls_ord_num  NVARCHAR(50) ,
	sls_prd_key  NVARCHAR(50) ,
	sls_cust_id  INT ,
	sls_store_id INT , 
	sls_order_dt DATE ,
	sls_ship_dt  DATE , 
	sls_due_dt   DATE ,
	sls_sales    INT ,
	sls_quantity INT ,
	sls_price    INT ,
	dwh_batch_name     NVARCHAR(50) , 
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_update_date DATETIME2 DEFAULT NULL  
);
GO


IF OBJECT_ID('silver.crm_category_reference', 'U') IS NOT NULL
    DROP TABLE silver.crm_category_reference;
GO
CREATE TABLE silver.crm_category_reference (
	ID		 NVARCHAR(50) ,
	CAT		 NVARCHAR(50) ,
	SUBCAT	 NVARCHAR(50) ,
	WARRANTY NVARCHAR(50) ,
	dwh_batch_name     NVARCHAR(50) , 
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_update_date DATETIME2 DEFAULT NULL 
);
GO


IF OBJECT_ID('silver.crm_customer_demographics', 'U') IS NOT NULL
    DROP TABLE silver.crm_customer_demographics;
GO
CREATE TABLE silver.crm_customer_demographics (
	CID   NVARCHAR(50) ,
	BDATE DATE ,
	GEN   NVARCHAR(50) ,
	dwh_batch_name     NVARCHAR(50) , 
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_update_date DATETIME2 DEFAULT NULL 
);
GO


IF OBJECT_ID('silver.crm_customer_region', 'U') IS NOT NULL
    DROP TABLE silver.crm_customer_region;
GO
CREATE TABLE silver.crm_customer_region (
	CID    NVARCHAR(50),
	REGION NVARCHAR(50),
	dwh_batch_name     NVARCHAR(50) , 
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_update_date DATETIME2 DEFAULT NULL 
)
GO
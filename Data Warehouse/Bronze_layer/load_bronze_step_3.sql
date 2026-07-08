/*
This is the Third step of load data into bronze layer
===============================================================================
Stored Procedure : Load to bronze ( final loading form => execution on all tables of bronze layer)
===============================================================================
Script Purpose:
    This stored procedure is used to collect all previous procs in one place as like puzzle collection 
	to put every peace of the system in it place .

    It performs the following actions :
    - It receives the folder where the file which be loaded exist and name of batch which be loaded 
    - Apply the procedure from the previous file 'load_bronze_step_2' on each table on the bronze stage
    - Calculate all time the batch took to be executed
*/


CREATE OR ALTER PROCEDURE bronze.load_to_bronze @folder_name VARCHAR(50) , @batch_value VARCHAR(50)
AS 
BEGIN
	-- Two Vars to calculate all batch execute time
	DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;

	SET @batch_start_time = GETDATE();
		
	
	PRINT '==============================================================';
	PRINT '==>STARTING BRONZE LAYER LOAD | BATCH: ' + @batch_value;
	PRINT '==============================================================';


	/*================================= CRM System files =====================================*/
	PRINT '';
	PRINT '--------------------------------------------------------------';
	PRINT '*Loading CRM System Tables...*';
	PRINT '--------------------------------------------------------------';

	----------------------------------- Table crm_category_reference ----------------------------------
	exec bronze.load_form @folder_name = @folder_name , @table_name = 'crm_category_reference',
						  @batch_value = @batch_value , @system_type = 'CRM_System' , @data_file_name = 'category_reference';
	---------------------------------------------------------------------------------------------------

	---------------------------------- Table crm_customer_demographics ----------------------------------
	exec bronze.load_form @folder_name = @folder_name , @table_name = 'crm_customer_demographics',
						  @batch_value = @batch_value , @system_type = 'CRM_System' , @data_file_name = 'customer_demographics';
	---------------------------------------------------------------------------------------------------
			

	---------------------------------- Table crm_customer_region ----------------------------------
	exec bronze.load_form @folder_name = @folder_name , @table_name = 'crm_customer_region',
						  @batch_value = @batch_value , @system_type = 'CRM_System' , @data_file_name = 'customer_region';
	---------------------------------------------------------------------------------------------------

	/*================================= ERP System files =====================================*/
	PRINT '';
	PRINT '--------------------------------------------------------------';
	PRINT '*Loading ERP System Tables...*';
	PRINT '--------------------------------------------------------------';

	---------------------------------- Table erp_store_branches ----------------------------------
	exec bronze.load_form @folder_name = @folder_name , @table_name = 'erp_store_branches',
						  @batch_value = @batch_value , @system_type = 'ERP_System' , @data_file_name = 'store_branches';
	---------------------------------------------------------------------------------------------------



	---------------------------------- Table erp_store_customers ----------------------------------
	exec bronze.load_form @folder_name = @folder_name , @table_name = 'erp_store_customers',
						  @batch_value = @batch_value , @system_type = 'ERP_System' , @data_file_name = 'store_customers';
	---------------------------------------------------------------------------------------------------


	---------------------------------- Table erp_store_products ----------------------------------
	exec bronze.load_form @folder_name = @folder_name , @table_name = 'erp_store_products',
						  @batch_value = @batch_value , @system_type = 'ERP_System' , @data_file_name = 'store_products';
	---------------------------------------------------------------------------------------------------


	---------------------------------- Table erp_store_sales ----------------------------------
	exec bronze.load_form @folder_name = @folder_name , @table_name = 'erp_store_sales',
						  @batch_value = @batch_value , @system_type = 'ERP_System' , @data_file_name = 'store_sales';
	---------------------------------------------------------------------------------------------------

		-- Calculate batch execution time
		SET @batch_end_time = GETDATE();
		PRINT '';
		PRINT '==============================================================';
		PRINT '=> BRONZE LAYER LOAD COMPLETED';
		PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS VARCHAR) + ' seconds.';
		PRINT '==============================================================';

END
/*
This is the second step of load data into bronze layer
===============================================================================
Stored Procedure : Load Form ( Bulk Insert => final loading form)
===============================================================================
Script Purpose:
    This stored procedure use to make security checks , organize dataflow , 
	use to prevent any duplicate load to any file to make sure consistency of data 
	in this layer and write all load information on the log table, finally make
	load operation more dynamic and reduce repeatation of code .

    It performs the following actions :
    - It receives the folder where the file which be loaded exist and the table which be loaded to 
    - First Check the correctness of loaded file path
    - Second  check this batch not execute before to avoid dublicate load
    - if file loaded it calculate execute time and return it and store load process info to log table
	- if file not loaded it show message to display the error happend and store this into log table

*/

CREATE OR ALTER PROCEDURE bronze.load_form (@folder_name NVARCHAR(100) , @table_name NVARCHAR(100) , 
											@batch_value NVARCHAR(100) , @system_type NVARCHAR(100),
											@data_file_name NVARCHAR(100))
AS 
BEGIN

	-- Var to calculate time of execution 	
	DECLARE @start_time DATETIME, @end_time DATETIME;


	DECLARE @insert_final_form NVARCHAR(MAX); -- var for procedure : bulk_insert_form
	DECLARE @row_affected_by_load INT; -- var to show number of effect row by load operation
	-- Two vars to check if file exist in the given path
	DECLARE @file_path_check VARCHAR(300);
	DECLARE @file_exists INT;

	-- ************************************** Table *******************************************
	PRINT '------------------------------------------------------------'
	PRINT '>> Table: bronze.' + @table_name;
	SET @start_time = GETDATE();
	-- Check file Exist before load
	SET @file_path_check = 'E:\Portfolio\SQL-Project\Data sets\' + @folder_name +'\' +@system_type+ '\' + @data_file_name +'.csv';
	EXEC master.dbo.xp_fileexist @file_path_check, @file_exists OUTPUT;
	IF @file_exists = 1
	BEGIN
	-------------------------------------------------------------------------------------------------------------------
	-- check this batch not execute before to avoid dublicate load
	IF NOT EXISTS (select 1
				   from bronze.load_log
				   where  (table_name = @table_name and status = 'commit_load' and batch_name = @batch_value))
	BEGIN 
	---------------------------------------------------------------------------------------------------------------------
	-- send load information to log table
		INSERT INTO bronze.load_log(batch_name,table_name,batch_time,file_path,status)
		VALUES(@batch_value,@table_name,GETDATE(),@file_path_check,'begin_load');
	---------------------------------------------------------------------------------------------------------------------
	-- try to applay bulk_insert_form procedure to load data
		BEGIN TRY
			EXECUTE bronze.bulk_insert_form  @static_path = 'E:\Portfolio\SQL-Project\Data sets', @folder = @folder_name ,
											 @crm_erp = @system_type ,@file_name = @data_file_name,
											 @table_name = @table_name ,@batch_name= @batch_value ,
									         @final_form = @insert_final_form OUTPUT

			EXEC sp_executesql @insert_final_form;
			SET @row_affected_by_load = @@ROWCOUNT;
		------------------------------------------------------------------------------------------------------------
		-- if load success send the information to log table and calc load time and print success message
			INSERT INTO bronze.load_log(batch_name,table_name,batch_time,row_affected,file_path,status)
			VALUES(@batch_value,@table_name,GETDATE(),@row_affected_by_load,@file_path_check,'commit_load');
			SET @end_time = GETDATE();
			PRINT '[SUCCESS] ' + CAST(@row_affected_by_load AS VARCHAR) + ' rows loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds.';
		-------------------------------------------------------------------------------------------------------------
		END TRY
		--- Catch to handle load process when error
		BEGIN CATCH
			DECLARE @delete_sql NVARCHAR(300);
			SET @delete_sql = N'DELETE FROM bronze.[' + @table_name + N'] WHERE dwh_batch_name = @b';
			EXEC sp_executesql @delete_sql, N'@b NVARCHAR(100)', @b = @batch_value;

			INSERT INTO bronze.load_log(batch_name,table_name,batch_time,row_affected,file_path,status)
			VALUES(@batch_value,@table_name,GETDATE(),0,@file_path_check,'failed');
				
			SET @end_time = GETDATE();
			PRINT '[FAILED] Error occurred after ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds. Check load_log.';
		END CATCH
	-----------------------------------------------------------------------------------------------------------------
	-- if this table alread loaded successfully before print message to show that
	END
	ELSE 
		print'=> This batch (' + @batch_value + ') for [' + @table_name + '] has already been loaded. Please check the load_log table.'

	-----------------------------------------------------------------------------------------------------------------
	END
	------ if file not exist in the given path show message and send this to log table
	ELSE
	BEGIN
		INSERT INTO bronze.load_log(batch_name,table_name,batch_time,row_affected,status)
		VALUES(@batch_value,@table_name,GETDATE(),0,'skipped_no_file');
		PRINT '[SKIPPED] File not found.';
	END
	-- ************************************************************************************

END
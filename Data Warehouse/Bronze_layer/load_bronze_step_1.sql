/*
This is the first step of load data into bronze layer
===============================================================================
Stored Procedure : Insert Form (Source files => Sturctured form)
===============================================================================
Script Purpose:
    This stored procedure take data from source system (parsing files) and organize it into structre way to simplify 
    load process in the next step, it just like as object of forms and each file get a copy from it to cross to 
    the next level
    It performs the following actions :
    - get all data about source path and distination table
    - create a temporary view on the distination table to ensure put data on the right columns 
    - after data loaded on to the distination table temp view drop 
    - insert batch info (name , time) to distination table
*/
CREATE OR ALTER PROCEDURE bronze.bulk_insert_form 
    (@static_path  VARCHAR(100) , @folder VARCHAR(100) , 
	 @crm_erp VARCHAR(100) , @file_name VARCHAR(100) , 
     @table_name VARCHAR(100) , @batch_name VARCHAR(50),
     @final_form  NVARCHAR(MAX) OUTPUT )
AS 
BEGIN 
    DECLARE @full_path VARCHAR(200);
    SET @full_path = @static_path + '\' + @folder + '\' + @crm_erp + '\' + @file_name + '.csv';

    SET @final_form = N'
        -- 1. delete the view if exist 
        IF OBJECT_ID(''bronze.vw_temp_' + @table_name + ''', ''V'') IS NOT NULL 
            DROP VIEW bronze.vw_temp_' + @table_name + ';
        
        -- 2. get all columns of table except DWH information columns 
        DECLARE @columns NVARCHAR(MAX);
        SELECT @columns = STRING_AGG(''['' + name + '']'', '','') WITHIN GROUP (ORDER BY column_id)
        FROM sys.columns 
        WHERE object_id = OBJECT_ID(''bronze.[' + @table_name + ']'') 
          AND name NOT IN (''dwh_batch_name'', ''dwh_added_time'');

        -- 3. Create Temp View to make insert into chosen columns only 
        EXEC(''CREATE VIEW bronze.vw_temp_' + @table_name + ' AS SELECT '' + @columns + '' FROM bronze.[' + @table_name + ']'');

        -- 4. Applay BULK INSERT on temp view
        BULK INSERT bronze.vw_temp_' + @table_name + '
        FROM ''' + @full_path + N'''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n'',
            TABLOCK
        );

        -- 5. Delete Temp  View
        DROP VIEW bronze.vw_temp_' + @table_name + ';

        -- 6. Update DWH Column information (batch_name)  
        UPDATE bronze.[' + @table_name + N']
        SET dwh_batch_name = ''' + @batch_name + N'''
        WHERE dwh_batch_name IS NULL;
    ';	
END
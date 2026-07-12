/*
===============================================================================
 Function : Get unloaded batches.
===============================================================================
Script Purpose:
    This function get table name from user and return which batches not loaded to the
    silver layer.
    It performs the following actions :
    - receive table name from as a paramenter
    - compare between bronze log and silver log for this table  
    - apply 'EXCEPT' operator between bronze.load_log , silver.load_log
    - return batches name which already loaded to bronze layer and not load in the silver one
*/

CREATE OR ALTER FUNCTION silver.get_unload_batches_inline (
    @table_name NVARCHAR(100)
)
RETURNS TABLE
AS
RETURN (

    SELECT batch_name 
    FROM bronze.load_log
    WHERE table_name = @table_name AND status = 'commit_load'
    EXCEPT
    SELECT batch_name 
    FROM silver.load_log
    WHERE table_name = @table_name  AND status = 'commit_load'
);
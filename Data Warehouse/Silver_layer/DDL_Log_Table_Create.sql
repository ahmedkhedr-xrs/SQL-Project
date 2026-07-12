/*
================================================================================
DDL Script: Create silver load log table
================================================================================
Script Purpose:
    This script creates log table to monitor data load process in 'silver' layer 
================================================================================
*/

IF OBJECT_ID('silver.load_log', 'U') IS NOT NULL
    DROP TABLE silver.load_log;
GO

CREATE TABLE silver.load_log (
    load_id INT IDENTITY PRIMARY KEY,
    batch_name NVARCHAR(50),
    table_name NVARCHAR(50),
    process_time DATETIME2 DEFAULT GETDATE(),
    rows_inserted INT DEFAULT 0,
    rows_updated INT DEFAULT 0,
    status NVARCHAR(20)  
);
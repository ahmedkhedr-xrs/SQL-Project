/*
================================================================================
DDL Script: Create Bronze load log table
================================================================================
Script Purpose:
    This script creates log table to monitor data load process in 'bronze' layer 
================================================================================
*/

IF OBJECT_ID('bronze.load_log', 'U') IS NOT NULL
    DROP TABLE bronze.load_log;
GO

CREATE TABLE bronze.load_log (
    load_id INT IDENTITY PRIMARY KEY,
    batch_name NVARCHAR(50),
    table_name NVARCHAR(50),
    batch_time DATETIME2 ,
    row_affected INT DEFAULT 0,
    file_path NVARCHAR(300),
    status NVARCHAR(20)
);
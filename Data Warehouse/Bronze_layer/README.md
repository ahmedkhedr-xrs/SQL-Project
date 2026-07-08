# 🥉 Bronze Layer - Data Warehouse

## 📌 Overview
This directory contains the SQL scripts and stored procedures responsible for the **Bronze Layer** of the Data Warehouse, built on the Medallion Architecture. 
The primary objective of this layer is to ingest raw data from source files (CSV) into the SQL Server database without applying any major transformations, ensuring a historical, immutable record of the source data.

## ⚙️ Architecture & Key Features
The ingestion pipeline is designed with advanced data engineering principles to ensure robustness, modularity, and data integrity:

- **Metadata & Audit Trails:** Every table includes `dwh_batch_name` and `dwh_added_time` to track exactly when and how data was loaded.
- **Robust Logging Mechanism:** A dedicated `bronze.load_log` table captures the start time, end time, rows affected, and status (Success/Failed/Skipped) of every table load.
- **Idempotency & Duplicate Prevention:** The pipeline checks if a specific batch has already been loaded for a table, preventing accidental duplicate data ingestion.
- **Dynamic SQL & Temporary Views:** Utilizes dynamic SQL to construct `BULK INSERT` statements on the fly. It smartly maps CSV columns to target tables while ignoring auto-generated DWH metadata columns.
- **Error Handling & Rollback:** Implements `TRY...CATCH` blocks. If a load fails, it cleans up (deletes) the partially loaded data for that batch to maintain consistency and logs the failure.

## 📂 File Structure

### 1. DDL Scripts (Data Definition)
* `create_load_log.sql`: Defines the `bronze.load_log` table used for monitoring the execution of data loads.
* `create_bronze_tables.sql`: Contains the schema definitions for all source systems, dropping existing tables and recreating them. 
  * **Systems Included:**
    * **CRM System:** `crm_category_reference`, `crm_customer_demographics`, `crm_customer_region`
    * **ERP System:** `erp_store_branches`, `erp_store_customers`, `erp_store_products`, `erp_store_sales`

### 2. ETL Stored Procedures (Data Ingestion)
The loading process is divided into a 3-step modular architecture:

* `step1_bulk_insert_form.sql`: The core engine. It generates and executes a dynamic `BULK INSERT` script using a temporary view to map source data correctly into the database.
* `step2_load_form.sql`: The controller. It validates file paths, checks for duplicate batches, logs the process initiation, calls Step 1, handles errors/rollbacks, and logs the final success/failure metrics.
* `step3_load_to_bronze.sql`: The master orchestrator. It sequentially triggers the load process for all CRM and ERP tables and calculates the total execution time for the entire batch.

## 🚀 How to Run

To execute the data load process for a new batch of data, run the master orchestration stored procedure, providing the folder name (e.g., date-based partition) and the unique batch identifier:

```sql
EXEC bronze.load_to_bronze 
    @folder_name = '2023-10',  -- The folder containing the CSV files
    @batch_value = 'Batch_001'; -- Unique identifier for this load
```

## 🛠️ Tech Stack
* **Database:** SQL Server (T-SQL)
* **Techniques:** Stored Procedures, Dynamic SQL, Bulk Insert, Error Handling

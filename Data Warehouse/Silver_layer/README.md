# 🥈 Silver Layer - Data Warehouse

## 📌 Overview
This directory contains the SQL scripts and stored procedures responsible for the **Silver Layer** of the Data Warehouse, utilizing the Medallion Architecture.
The Silver layer is the core processing hub where raw data from the Bronze layer undergoes rigorous **data cleansing, standardization, and integration**. It is designed to handle **Incremental Loads**, ensuring that only new or updated batches are processed, minimizing resource consumption while maintaining a high-quality, reliable Single Source of Truth.

## ⚙️ Architecture & Key Features
The ETL pipeline in the Silver layer employs sophisticated data engineering patterns to handle complex transformations and load stategies:

- **Incremental Loading & Batch Tracking:** Uses a custom inline function (`silver.get_unload_batches_inline`) to dynamically compare the `bronze.load_log` with the `silver.load_log`. It only processes batches that exist in Bronze but haven't yet been committed to Silver.
- **Advanced Data Cleansing (The "Dirty Data" Fixes):**
    - **String Formatting:** Applies `TRIM()` and `UPPER()`/`LOWER()` to standardize text fields across all tables.
    - **Categorical Normalization:** Unifies inconsistent gender and marital status values (e.g., mapping 'M', 'MALE' to 'Male') using `CASE` statements.
    - **ID Normalization (System Integration):** Strips prefixes like 'OLD' from CRM Customer IDs to seamlessly join with the ERP system.
    - **Data Type Casting & Date Handling:** Converts integer-based dates (e.g., `20251031`) into native SQL `DATE` formats and handles 'zero-dates' or invalid lengths by casting them to `NULL`.
    - **Financial Integrity:** Recalculates missing or incorrect `sls_sales` and `sls_price` values using the formula `Sales = Quantity * Price` in the `erp_store_sales` table.
- **Strategic Data Loading Patterns:**
    - **Upsert (MERGE):** Utilized for Dimension tables (Customers, Regions, Demographics, Categories) to gracefully handle new records (`INSERT`) and updates to existing records (`UPDATE`), outputting metrics via the `$action` variable.
    - **SCD Type 2 (Slowly Changing Dimensions):** Implemented for `erp_store_products` to track historical pricing changes using Window Functions (`LEAD()`) to calculate accurate `prd_end_dt` ranges.
    - **Append-Only:** Applied to the Fact table (`erp_store_sales`), where historical immutable transactions are directly inserted for maximum performance.
- **Idempotency & Rollback:** Uses robust `TRY...CATCH` blocks. If a transformation or load fails, any partially inserted data for that specific batch is deleted, ensuring the table remains in a consistent state.

## 📂 File Structure

### 1. DDL Scripts (Data Definition)
* `create_silver_log.sql`: Defines the `silver.load_log` table, tracking process time, inserted rows, updated rows, and status for every batch.
* `create_silver_tables.sql`: Defines the schema for the cleansed tables, adding `dwh_create_date` and `dwh_update_date` for robust auditing.

### 2. ETL Stored Procedures & Functions
* `func_get_unload_batches.sql`: An inline table-valued function that returns pending batches by performing an `EXCEPT` operation between Bronze and Silver logs.
* `load_to_silver.sql`: The master orchestrator. It sequentially executes the cleansing and loading logic (MERGE, SCD2, Append) for all CRM and ERP tables, capturing precise row-level metrics.
* `ERP_CRM Relation.drawio.png`: A visual schema diagram illustrating the relationships between the integrated ERP and CRM entities.

## 🚀 How to Run

To execute the data transformation and load process from Bronze to Silver, simply execute the main stored procedure. The procedure will automatically detect which batches need processing:

```sql
EXEC silver.load_to_silver;
```

## 🛠️ Tech Stack
* **Database:** SQL Server (T-SQL)
* **Techniques:** Stored Procedures, Table-Valued Functions, MERGE (Upsert), SCD Type 2, Window Functions (`LEAD()`, `ROW_NUMBER()`), Data Type Casting.

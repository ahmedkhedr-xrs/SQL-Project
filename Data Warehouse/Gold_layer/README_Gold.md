# 🥇 Gold Layer - Data Warehouse

## 📌 Overview
This directory contains the SQL scripts responsible for the **Gold Layer** of the Data Warehouse. Following the Medallion Architecture, this layer provides the final, business-ready dataset. 
It transforms the cleansed and integrated data from the Silver layer into a highly optimized **Star Schema**, consisting of Fact and Dimension tables (Views). This layer serves as the foundation for the EDA and Advanced Analytics phase of the project.

## ⚙️ Architecture & Key Features
The Gold layer focuses on analytical performance, business logic integration, and ease of use for end-users (analysts and BI tools):

- **Star Schema Design:** Data is explicitly structured into a central Fact table (`fact_sales`) surrounded by descriptive Dimension tables (`dim_customers`, `dim_products`, `dim_branches`), optimizing querying performance and simplifying table joins.
- **Virtualization (Views):** The Gold layer is implemented entirely using SQL `VIEW`s on top of the Silver tables. This ensures real-time access to the latest cleansed data without duplicating storage, while encapsulating complex join logic.
- **Surrogate Keys:** Generates reliable, auto-incrementing surrogate keys (`customer_key`, `product_key`) using `ROW_NUMBER()` to isolate the Data Warehouse from source system key changes and to improve join efficiency.
- **Cross-System Data Integration:** 
    - **`dim_customers`:** Masterfully merges ERP customer data with CRM demographic and regional data. It includes intelligent conflict resolution (e.g., prioritizing ERP gender data, but falling back to CRM data using `COALESCE` if ERP data is missing).
    - **`dim_products`:** Joins ERP product data with CRM category hierarchies, providing a unified product catalog.
- **Current State Filtering (SCD2 Resolution):** The `dim_products` view filters out historical price versions (`WHERE prd_end_dt IS NULL`), presenting only the current, active state of products for standard reporting.

## 📂 File Structure

* `create_gold_views.sql`: A comprehensive DDL script that drops (if they exist) and recreates all the views defining the Star Schema.
  * **Dimensions:**
    * `gold.dim_customers`: Unified customer profile (ERP + CRM).
    * `gold.dim_products`: Unified product catalog (ERP + CRM).
    * `gold.dim_branches`: Store locations and details.
  * **Facts:**
    * `gold.fact_sales`: Transactional sales data linked to dimensions via surrogate keys.

## 🚀 How to Use
These views are ready to be queried directly by any BI tool (e.g., Power BI, Tableau) or used for advanced analytical queries using Python or SQL.

Example query to get total sales by region:
```sql
SELECT 
    c.country, 
    SUM(f.sales) AS total_revenue
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_revenue DESC;
```

## 🛠️ Tech Stack
* **Database:** SQL Server (T-SQL)
* **Techniques:** Star Schema Modeling, Views, Surrogate Key Generation (`ROW_NUMBER()`), Cross-System JOINs, Data Coalescing (`COALESCE`).

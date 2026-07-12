# 📊 Datasets - Electronics Retail Chain (Egypt)

## 📌 Overview
This repository folder contains the raw data files used for the **Data Warehouse Project**. The dataset simulates a real-world scenario of an Electronics Retail Chain in Egypt, extracting data from two distinct source systems:
1. **ERP System (Store / POS):** Sales, customers, products, and branches.
2. **CRM System (Warehouse / Supplier):** Demographics, categories, and regional data.

A key feature of this dataset is that it is structured to support **Incremental Loading (Batched)**, making it perfect for demonstrating robust ETL/ELT pipelines, specifically the Medallion Architecture (Bronze ➔ Silver ➔ Gold).

---

## 📂 Folder Structure
To simulate realistic monthly data deliveries, the files are divided into batches:

* 📁 `initial_load/` - Historical accumulated data (up to Sept 2025). Used for the initial Full Load.
* 📁 `monthly_batch_1/` - Incremental updates for October 2025.
* 📁 `monthly_batch_2/` - Incremental updates for November 2025.
* 📁 `monthly_batch_3/` - Incremental updates for December 2025.

---

## 💾 Data Entities & Load Strategies

The dataset dictates specific loading strategies in the **Silver Layer** based on the entity type:

| Entity | Files | Load Strategy (Silver Layer) |
| :--- | :--- | :--- |
| **Sales (Transactions)** | `store_sales.csv` | **Append Only** - New transactions are added directly. |
| **Customers** | `store_customers.csv` | **Upsert (MERGE)** - Contains new customers (Insert) and updates to existing ones (Update). |
| **Products** | `store_products.csv` | **Upsert (SCD)** - Contains new products and price changes over time. |
| **Static Reference** | `store_branches.csv`, `category_reference.csv` | **Full Load** - Reference tables mostly present in `initial_load`. |
| **Demographics** | `customer_demographics.csv`, `customer_region.csv` | **Append/Merge** - Follows the customer acquisition timeline. |

---

## 🧹 Data Quality Challenges (Dirty Data)
Real-world data is rarely clean. This dataset is intentionally seeded with anomalies to test the **Data Cleaning & Transformation** rules in the Silver Layer:
* **Inconsistent Formatting:** Extra whitespaces, mixed casing, and unstandardized categorical values (e.g., gender, marital status).
* **Missing/Null Values:** Blank dates or orphaned categorical fields.
* **Invalid Entries:** Zero-dates, negative/incorrect prices.
* **System Discrepancies:** Different prefix IDs between the ERP and CRM systems.

---

## 🚀 How to Use
1. Begin by loading the `initial_load` folder into the `Bronze` layer, applying cleaning rules, and moving to `Silver`.
2. Process `monthly_batch_1`, followed sequentially by `2` and `3`. 
3. Ensure your pipeline correctly handles Upserts (`MERGE`) for customers, SCD tracking for product prices, and pure Appends for sales without duplicating records.

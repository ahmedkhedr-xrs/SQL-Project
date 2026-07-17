# 📊 Exploratory Data Analysis (EDA) & Advanced SQL Analytics

## 📌 Overview
Welcome to the Analytical engine of the Data Warehouse project. While the Data Engineering phase focused on moving and cleansing data (Bronze ➔ Silver ➔ Gold), this phase focuses on **extracting actionable business intelligence**. 

This repository section demonstrates a structured, progressive approach to data analysis using Advanced SQL (T-SQL). It transitions smoothly from foundational data exploration (EDA) to complex, business-driven advanced analytics, culminating in a robust **Semantic Reporting Layer** ready for BI consumption.

---

## 🗺️ Analytical Roadmap
The analysis strictly follows a comprehensive roadmap, ensuring no data stone is left unturned:

### 🔍 Phase 1: Exploratory Data Analysis (EDA)
Before answering complex business questions, we must understand the shape of our data.
* **Database & Dimensions Exploration:** Profiling the schema, identifying unique dimensions (cities, categories, products), and understanding the structural boundaries.
* **Date Range Exploration:** Defining the temporal scope of the dataset (first/last orders, customer lifespans, branch operating periods).
* **Measures & Magnitude:** Calculating foundational KPIs (Total Sales, Total Orders, Average Selling Price) and understanding data distribution across segments (e.g., Sales by Category, Customers by Region).

### 📈 Phase 2: Advanced Analytics
Moving beyond basic aggregations to uncover deep, actionable trends using advanced SQL capabilities:
* **Ranking Analysis:** Identifying Top/Bottom performers (Products, Branches, Customers) using Window Functions (`DENSE_RANK()`, `ROW_NUMBER()`).
* **Time Intelligence (Change Over Time):** Analyzing seasonal trends and grouping metrics by dynamic timeframes using `DATETRUNC()` and `ROLLUP()`.
* **Cumulative Analysis:** Tracking business growth via Running Totals and Moving Averages using `SUM() OVER()` and `AVG() OVER()`.
* **Performance Benchmarking (YoY / MoM):** Evaluating branch and product performance against historical data and calculating growth/decline using the `LAG()` function.
* **Data Segmentation:** Categorizing entities based on complex behavioral logic (e.g., segmenting customers into *VIP, Regular, New* based on spending and lifespan using `CASE` statements).
* **Part-to-Whole Analysis:** Calculating the percentage contribution of individual categories to overall sales using unpartitioned Window Functions.

### 🎯 Phase 3: The Semantic Layer (Reporting Views)
The culmination of the analytical process. We encapsulate the complex logic, KPIs, and segmentations into unified **SQL Views**.
* **`gold.report_customers`:** A comprehensive 360-degree view of the customer, calculating Recency, Lifespan, Average Order Value (AOV), and Average Monthly Spend.
* **`gold.report_products`:** A detailed product performance matrix, segmenting products into *High/Mid/Low Performers* and calculating Average Order Revenue.
* **Impact:** These views serve as a "Plug-and-Play" Semantic Layer, allowing BI tools (like Power BI or Tableau) to connect and visualize data instantly without needing complex DAX calculations.

---

## 🛠️ Advanced SQL Techniques Applied
This project heavily relies on enterprise-level SQL techniques to ensure high performance and readable code:
- **Common Table Expressions (CTEs):** Used extensively to break down complex multi-step queries into readable, logical blocks.
- **Window Functions:** Employed for ranking (`DENSE_RANK`), cumulative calculations (`SUM OVER`), moving averages, and calculating part-to-whole percentages without costly self-joins.
- **Time Intelligence & Offsets:** Utilizing `LAG()` for Year-over-Year (YoY) performance comparisons.
- **Dynamic Aggregation:** Utilizing `ROLLUP` for hierarchical subtotals.
- **Complex Conditional Logic:** Advanced `CASE` statements for dynamic segmentation and data bucketing.

---

## 📂 Repository Structure
* `01` to `04`: **EDA** (Database, Dimensions, Dates, Measures).
* `05` to `06`: **Magnitude & Ranking** (Top N, Distributions).
* `07` to `09`: **Time-Series & Performance** (Trends, Cumulative, YoY Analysis).
* `10` to `11`: **Advanced Segmentation** (Customer/Product Bucketing, Part-to-Whole).
* `12` to `13`: **Reporting Views** (Final Semantic Layer).

## 🚀 How to Use
Run these scripts sequentially in SQL Server Management Studio (SSMS) or Azure Data Studio against the `DataWarehouse` database. The final scripts (`12_report_customers.sql` and `13_report_products.sql`) will generate the views that can be directly imported into your BI tool of choice.

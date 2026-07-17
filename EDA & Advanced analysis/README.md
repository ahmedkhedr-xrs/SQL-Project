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
* **Ranking Analysis:** Identifying Top/Bottom performers (Products, Branches, Customers) using `TOP` clauses and Window Functions (`DENSE_RANK()`).

### 📈 Phase 2: Advanced Analytics
Moving beyond basic aggregations to uncover deep, actionable trends using advanced SQL capabilities:
* **Time Intelligence (Change Over Time):** Analyzing seasonal trends and grouping metrics by dynamic timeframes using `DATETRUNC()` and `ROLLUP()`.
* **Cumulative Analysis:** Tracking business growth via Running Totals and Moving Averages using `SUM() OVER()` and `AVG() OVER()`.
* **Performance Benchmarking (YoY / MoM):** Evaluating branch and product performance against historical data and calculating growth/decline using the `LAG()` function.
* **Data Segmentation:** Categorizing entities based on complex behavioral logic (e.g., segmenting customers into *VIP, Regular, New* based on spending and lifespan using `CASE` statements).
* **Part-to-Whole Analysis:** Calculating the percentage contribution of individual categories to overall sales using unpartitioned Window Functions.

### 🎯 Phase 3: The Semantic Layer (Reporting Views)
The culmination of the analytical process. We encapsulate the complex logic, KPIs, and segmentations into unified **SQL Views**. These views serve as a "Plug-and-Play" Semantic Layer, allowing BI tools (like Power BI or Tableau) to connect and visualize data instantly.

**💡 Note on Aggregation:** All metrics in these reports are calculated at an **Aggregated Level** (per customer, per product, or per branch) rather than the transactional level, providing high-level, summarized insights ready for dashboarding.

#### 1. Customer Report (`gold.report_customers`)
A 360-degree aggregated view of customer behavior and lifetime value.

| Column Name | Description |
| :--- | :--- |
| `customer_key` / `name` | Unique identifiers and full display names. |
| `age_group` | Categorized age segments (e.g., Under 20, 20-29, 50 and above). |
| `customer_segment` | Behavioral grouping (VIP, Regular, New) based on spending and lifespan. |
| `lifespan` | Total months between the customer's first and last order. |
| `recency` | Months elapsed since the customer's last order. |
| `total_orders` / `sales` | Aggregated lifetime transactional volume and revenue. |
| `avg_order_value` | Average revenue generated per order (Total Sales / Orders). |
| `avg_monthly_spend` | Average revenue generated per month over the customer's lifespan. |

#### 2. Product Report (`gold.report_products`)
A detailed, aggregated matrix of product performance across the catalog.

| Column Name | Description |
| :--- | :--- |
| `product_key` / `name` | Product identifiers and marketing names. |
| `category_name` / `sub_category` | Hierarchical classifications of the product. |
| `product_segment` | Performance grouping (High-Performer, Mid-Range, Low-Performer) based on total revenue. |
| `lifespan` | Total months between the product's first and last sale. |
| `recency_in_months` | Months elapsed since the product was last sold. |
| `total_customers` | Count of unique customers who purchased this product. |
| `avg_selling_price` | Average price at which the product was sold (Total Sales / Quantity). |
| `avg_monthly_revenue` | Average revenue generated per month over the product's lifespan. |

#### 3. Branch Report (`gold.report_branches`)
A holistic, aggregated view of physical store performance over time.

| Column Name | Description |
| :--- | :--- |
| `branch_key` / `name` / `city` | Branch identifiers and geographic location. |
| `open_date` / `lifespan_year` | Date of opening and total years of operation. |
| `total_orders` / `sales` | Aggregated lifetime operational volume and revenue. |
| `avg_orders_per_month` | Velocity metric: Average number of orders processed per month. |
| `avg_order_price` | Average revenue generated per order at this specific branch. |
| `avg_yearly_revenue` | Average revenue generated per year of operation. |

---

## 🧠 Key Design Decisions
Behind the SQL scripts are deliberate engineering and business decisions designed to ensure accuracy and consistency:
- **Grouping by Keys, Not Names:** In Ranking and Performance queries, aggregations are strictly grouped by `product_key` (or `customer_key`) rather than just names. This prevents data merging issues where distinct products might share the same marketing name.
- **Unified Segmentation Logic:** The threshold rules for customer segments (VIP, Regular, New) are strictly unified across both the ad-hoc analysis (`10_data_segmentation.sql`) and the final reporting view (`12_report_customers.sql`) to ensure a single version of the truth.

- **Zero-Division Protection:** Implemented logic (e.g., checking if months since opening is 0 in `report_branches`) to prevent divide-by-zero errors for newly opened branches or entities with no transaction history.
- **Orphaned Sales Handling (Business Judgment):** Discontinued products without an active `product_key` in the current catalog are deliberately retained in the final product reports rather than filtered out via `INNER JOIN`. This ensures the sum of sales in the reports always matches the true financial bottom line.

---

## 🛠️ Advanced SQL Techniques Applied
This project heavily relies on enterprise-level SQL techniques to ensure high performance and readable code:
- **Common Table Expressions (CTEs):** Used extensively to break down complex multi-step queries into readable, logical blocks.
- **Window Functions:** Employed for ranking (`DENSE_RANK`), cumulative calculations (`SUM OVER`), moving averages, and calculating part-to-whole percentages without costly self-joins.
- **Time Intelligence & Offsets:** Utilizing `LAG()` for Year-over-Year (YoY) performance comparisons.
- **Dynamic Aggregation:** Utilizing `ROLLUP` for hierarchical subtotals.
- **Complex Conditional Logic:** Advanced `CASE` statements for dynamic segmentation, data bucketing, and error handling (preventing divide-by-zero).

---

## 📂 Repository Structure
* `01` to `06`: **Phase 1: EDA** (Database, Dimensions, Dates, Measures, Magnitude, Ranking).
* `07` to `09`: **Phase 2: Advanced Analytics** (Time-Series, Cumulative, YoY Performance).
* `10` to `11`: **Phase 2: Advanced Analytics** (Segmentation & Part-to-Whole).
* `12` to `14`: **Phase 3: Reporting Views** (Final Semantic Layer - Customers, Products, Branches).

## 🚀 How to Use
Run these scripts sequentially in SQL Server Management Studio (SSMS) or Azure Data Studio against the `DataWarehouse` database. The final scripts (`12_report_customers.sql`, `13_report_products.sql`, and `14_report_branches.sql`) will generate the views that can be directly imported into your BI tool of choice.

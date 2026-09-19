# 🧾 SQL-Project: Electronics Retail — End-to-End Data Analytics

**A complete, end-to-end data project** — from raw multi-system source
files, through a production-style Data Warehouse built on the Medallion
Architecture, to a fully analyzed Star Schema, and finally an interactive
**Power BI dashboard** for business consumption. Built with **T-SQL on SQL
Server** and **Power BI / DAX**.

---

## 🎯 TL;DR

Built a Data Warehouse from scratch simulating an electronics retail chain
that integrates two independent source systems (**ERP** + **CRM**) via
monthly incremental file drops. Implements idempotent, auditable ETL with
**SCD Type 1 & Type 2**, a clean **Star Schema** in the Gold layer, 14 SQL
analytical queries/reports, and a 4-page interactive **Power BI dashboard**
covering company-wide, customer, product, and branch performance.

---

## 📖 About This Project

Most portfolio projects stop at "clean some data and run a few `SELECT`
statements," or start straight from a ready-made flat file in Power BI.
This one is built to mirror how a real data platform gets built and
operated end-to-end, from the source systems all the way to the business
user's screen:

- Two source systems that don't naturally agree on data formats, ID
  conventions, or update patterns — and have to be reconciled.
- Data that arrives **incrementally**, once a month, not as one clean
  one-time dump.
- A pipeline that has to be **safe to re-run**, **auditable**, and able to
  recover from partial failures without corrupting historical data.
- Deliberately "dirty" data (duplicate records, inconsistent codes,
  mismatched ID formats, invalid dates, non-unique names, near-zero profit
  margins) that had to be discovered and resolved the same way it would be
  in a real dataset — through profiling and debugging, not assumptions.
- A **semantic/reporting layer** (SQL views + a Power BI model) that turns
  all of the above into a dashboard a non-technical stakeholder can
  actually use.

Every layer of this repository documents not just *what* was built, but
*why* — including real issues discovered mid-build (in the data, the SQL,
and later the DAX measures) and how they were fixed.

---

## 🏗️ Repository Structure

```
SQL-Project/
│
├── Data Warehouse/                  # The full ETL pipeline: Bronze → Silver → Gold
│   ├── Bronze_layer/                # Raw ingestion layer (tables, dynamic BULK INSERT engine)
│   ├── Silver_layer/                # Cleansed & integrated layer (MERGE, SCD1/SCD2)
│   ├── Gold_layer/                  # Business-ready Star Schema (Views) + data catalog
│   ├── Docs/                        # Architecture, data flow, integration & star-schema diagrams
│   ├── Create_Database&Schemas.sql  # Initial database/schema setup script
│   └── README.md                    # Deep-dive documentation for the DWH build
│
├── EDA & Advanced analysis/         # SQL analytics layer on top of the Gold schema
│   ├── scripts/                     # 14 numbered analysis scripts (EDA → Advanced → Reports)
│   └── README.md                    # Deep-dive documentation for the analysis layer
│
├── Power BI/                        # Interactive dashboard consuming the Gold layer
│   ├── Dashboard.pbix               # The Power BI report file
│   ├── screenshots/                 # Page-by-page preview images
│   └── README.md                    # Dashboard structure, pages, and DAX highlights
│
├── datasets/                        # Source CSV files, split into initial_load + monthly batches
│
└── README.md                        # (this file)
```



Each subfolder has its own detailed `README.md` — this file is the map
that ties them together. Start here, then dive into whichever layer
interests you most.

---

## 🏛️ Architecture: Medallion (Bronze → Silver → Gold) + BI Layer

![High Level Architecture](Data%20Warehouse/Docs/data_architecture.png)

| Layer      | Object Type   | Load Strategy                  | What Happens Here                                                          |
|------------|---------------|----------------------------------|-------------------------------------------------------------------------------|
| 🥉 Bronze  | Tables        | Batch + Incremental (Append)     | Raw, untouched mirror of every source CSV, tagged by batch                    |
| 🥈 Silver  | Tables        | Batch + Incremental (Upsert)     | Cleansing, standardization, de-duplication, cross-system integration, SCD1/SCD2 |
| 🥇 Gold    | Views         | *No load step — always fresh*    | Star Schema: `dim_customers`, `dim_products`, `dim_branches`, `fact_sales`      |
| 📊 Power BI | Report (.pbix)| Live connection to Gold           | Interactive dashboard: KPIs, trends, segmentation, drill-downs for business users |

📄 Full diagrams (architecture, data flow, system integration, star schema):
[`Data Warehouse/Docs/`](./Data%20Warehouse/Docs/)

---

## 🔗 Two Source Systems, One Warehouse

The company's data arrives every month from two systems that don't speak
the same "language" — different ID formats, different update patterns —
and the pipeline has to reconcile them automatically.

| System | Delivers |
|--------|----------|
| **ERP** | Branches, core customer profile, products (with price history), sales transactions |
| **CRM** | Customer demographics, customer region, product category reference |

Full entity relationships: [`Data Warehouse/Docs/data_integration.png`](./Data%20Warehouse/Docs/data_integration.png)

---

## ⚙️ Engineering Highlights

- **Incremental, idempotent ETL end-to-end** — every layer auto-discovers
  which batches are pending (via log-table comparison) instead of relying
  on manual tracking; re-running a load is always safe.
- **Dynamic, reusable loading engine** — a single dynamic-SQL procedure
  drives `BULK INSERT` for all 7 source tables instead of duplicating code
  per table.
- **Strategic load pattern per table type** — reference data uses simple
  Upsert, slowly-changing attributes use **SCD Type 1**, priced products use
  **SCD Type 2** (full price history preserved via `LEAD()`), and
  transactions are pure append-only.
- **Full audit trail** — dedicated `load_log` tables in both Bronze and
  Silver capture start/end time, rows affected, and status for every table,
  every batch.
- **Gold layer as pure Views** — zero additional load step; reports and the
  Power BI dashboard always reflect the latest Silver data instantly.
- **14 analytical SQL scripts** — from schema exploration to YoY
  performance benchmarking to three consolidated reporting views
  (`report_customers`, `report_products`, `report_branches`).
- **A 4-page Power BI dashboard** built directly on the Gold semantic
  layer — no re-modeling of business logic in DAX, just visualization.

👉 For the full list of real data-quality and design issues discovered and
resolved during this build, see
[`Data Warehouse/README.md`](./Data%20Warehouse/README.md) and
[`Power BI/README.md`](./Power%20BI/README.md).

---

## ⭐ The Gold Layer — Star Schema

![Sales Data Mart Star Schema](Data%20Warehouse/Docs/data_model.png)

| Object | Grain |
|--------|-------|
| `gold.dim_customers` | One row per customer |
| `gold.dim_products`  | One row per currently active product |
| `gold.dim_branches`  | One row per branch |
| `gold.fact_sales`    | One row per sales order line item |

Full column-level data dictionary: [`Data Warehouse/Gold_layer/data_catalog.md`](./Data%20Warehouse/Gold_layer/data_catalog.md)

---

## 📊 SQL Analysis Layer

Built entirely on top of `gold`, following a structured progression:

**Exploratory Data Analysis** → Database/Dimensions/Date/Measures
exploration → Magnitude & Ranking

**Advanced Analytics** → Change-over-time, Cumulative totals, YoY
Performance benchmarking, Customer/Product/Branch Segmentation,
Part-to-Whole contribution

**Semantic Reporting Layer** → Three consolidated, reusable views:
`gold.report_customers`, `gold.report_products`, `gold.report_branches` —
each combining recency, lifespan, segmentation, and revenue KPIs into a
single query-ready object. These same views feed the Power BI dashboard
directly.

Full breakdown of all 14 scripts: [`EDA & Advanced analysis/README.md`](./EDA%20&%20Advanced%20analysis/README.md)

---

## 📈 Power BI Dashboard

A 4-page interactive dashboard connected live to the Gold layer, giving
non-technical stakeholders the same insights the SQL analysis layer
produces — without writing a single query.

| Page | Focus |
|------|-------|
| 🏠 Home | Navigation hub for the whole report |
| 📌 Overview | Company-wide KPIs, monthly sales trend, orders by governorate, top products |
| 👥 Customers Analysis | Customer segmentation (VIP/Regular/New), demographics, lifespan, spend by age group |
| 📦 Products Analysis | Category/sub-category performance, profit by sub-category, product segmentation |
| 🏢 Branches Analysis | Revenue and profit contribution per branch, order value, branch lifespan vs. sales |

**Design & interactivity highlights:**
- Dark, consistent theme across every page
- Reusable KPI card + toggle-button pattern (e.g. switch a chart between
  Total Sales / Total Profit / Total Quantity without adding new visuals)
- A "Top N" selector (5/10/15) on the best-selling products chart
- Cross-page slicers (Year, Segment, Age Group, City, Branch) for ad-hoc
  filtering
- A bubble chart mapping three metrics at once (quantity, revenue,
  customer count) per product category



### Preview

<table>
<tr>
<td><img src="Power%20BI/screenshots/01_home_page.png" width="420"/></td>
<td><img src="Power%20BI/screenshots/02_overview.png" width="420"/></td>
</tr>
<tr>
<td><img src="Power%20BI/screenshots/03_customers_analysis.png" width="420"/></td>
<td><img src="Power%20BI/screenshots/04_products_analysis.png" width="420"/></td>
</tr>
<tr>
<td colspan="2" align="center"><img src="Power%20BI/screenshots/05_branches_analysis.png" width="420"/></td>
</tr>
</table>

📥 Open the full report: [`Power BI/Dashboard.pbix`](./Power%20BI/Dashboard.pbix)
(requires Power BI Desktop and a connection to the `DataWarehouse`
database's `gold` schema)

---

## 🗂️ Datasets

Synthetic but realistic electronics retail data (~8,000 customers, ~300
products, ~35,000 sales transactions across 7 branches), generated with
intentional data-quality issues — duplicate records, inconsistent
categorical codes, mismatched ID formats, invalid dates, and
mathematically inconsistent sales figures — to mirror what a real-world
ingestion pipeline actually has to deal with. Delivered as an `initial_load`
plus three sequential `monthly_batch_*` folders to simulate real
incremental file drops. See [`datasets/`](./datasets/) for details.

---

## 🚀 Getting Started

```sql
-- 1) Set up the database and schemas
:r "Data Warehouse/Create_Database&Schemas.sql"

-- 2) Create all Bronze / Silver / Gold objects (see each layer's folder)

-- 3) Load the initial batch into Bronze, then propagate to Silver
EXEC bronze.load_to_bronze @folder_name = 'initial_load', @batch_value = 'initial_data';
EXEC silver.load_to_silver;

-- 4) Load subsequent monthly batches the same way
EXEC bronze.load_to_bronze @folder_name = 'monthly_batch_1', @batch_value = 'month_10_2025';
EXEC silver.load_to_silver;

-- 5) Query the Gold layer — always fresh, no load step needed
SELECT * FROM gold.report_branches;
```

Then, to explore the dashboard: open `Power BI/Dashboard.pbix` in Power BI
Desktop and point its data source to your local `DataWarehouse` database.

---

## 🛠️ Tech Stack

- **Database:** SQL Server (T-SQL)
- **Engineering:** Stored Procedures, Dynamic SQL, Table-Valued Functions,
  `BULK INSERT`, `MERGE` (Upsert), SCD Type 1 & 2, Idempotent/Incremental
  Load Design
- **Analytics:** Window Functions (`LEAD`, `LAG`, `SUM/AVG OVER`,
  `DENSE_RANK`), CTEs, `ROLLUP`, Date Intelligence, Business Segmentation
- **Modeling:** Dimensional Modeling / Star Schema
- **BI & Visualization:** Power BI, DAX (`DISTINCTCOUNT`, `CALCULATE`,
  conditional measures), interactive slicers and bookmarked navigation
- **Data Generation:** Python (synthetic dataset design with intentional
  data-quality issues)

---

## 🔭 Possible Future Extensions

- A Python/EDA notebook layered directly on `gold.fact_sales`
- SQL Server Agent scheduling to automate monthly batch ingestion
- Publishing the dashboard to the Power BI Service with a scheduled
  refresh against the warehouse

---

## 👤 Author

Ahmed Khedr — built as a Data Analyst portfolio project covering the full
lifecycle of a real-world data platform: dataset design, incremental ETL
engineering, data cleansing, dimensional modeling, business analytics, and
BI dashboarding.

🔗 [GitHub](https://github.com/ahmedkhedr-xrs) · 🔗 [LinkedIn](https://linkedin.com/in/ahmed-fareed-khedr)

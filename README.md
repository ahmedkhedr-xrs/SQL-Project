# 🧾 SQL-Project: Electronics Retail Data Warehouse & Analytics

**A complete, end-to-end data engineering and analytics portfolio project** —
from raw multi-system source files, through a production-style Data
Warehouse built on the Medallion Architecture, to a fully analyzed Star
Schema answering real business questions. Built entirely in **T-SQL on SQL
Server**.

---

## 🎯 TL;DR

Built a Data Warehouse from scratch simulating an electronics retail chain
that integrates two independent source systems (**ERP** + **CRM**) via
monthly incremental file drops. Implements idempotent, auditable ETL with
**SCD Type 1 & Type 2**, a clean **Star Schema** in the Gold layer, and 14
analytical queries/reports covering EDA, advanced analytics, and
business-ready reporting views.

---

## 📖 About This Project

Most portfolio projects stop at "clean some data and run a few `SELECT`
statements." This one is built to mirror how a real Data Warehouse gets
built and operated in production:

- Two source systems that don't naturally agree on data formats, ID
  conventions, or update patterns — and have to be reconciled.
- Data that arrives **incrementally**, once a month, not as one clean
  one-time dump.
- A pipeline that has to be **safe to re-run**, **auditable**, and able to
  recover from partial failures without corrupting historical data.
- Deliberately "dirty" data (duplicate records, inconsistent codes,
  mismatched ID formats, invalid dates, non-unique names) that has to be
  discovered and resolved the same way it would be in a real dataset —
  through profiling and debugging, not assumptions.

Every layer of this repository documents not just *what* was built, but
*why* — including real issues discovered mid-build and how they were fixed.

---

## 🏗️ Repository Structure

```
SQL-Project/
│
├── Data Warehouse/                  # The full ETL pipeline: Bronze → Silver → Gold
│   ├── Bronze_layer/                # Raw ingestion layer (tables, dynamic BULK INSERT engine)
│   ├── Silver_layer/                # Cleansed & integrated layer (MERGE, SCD1/SCD2)
│   ├── Gold_layer/                  # Business-ready Star Schema (Views)
│   ├── Docs/                        # Architecture, data flow, integration & star-schema diagrams
│   ├── Create_Database&Schemas.sql  # Initial database/schema setup script
│   └── README.md                    # Deep-dive documentation for the DWH build
│
├── EDA & Advanced analysis/         # SQL analytics layer on top of the Gold schema
│   ├── scripts/                     # 14 numbered analysis scripts (EDA → Advanced → Reports)
│   └── README.md                    # Deep-dive documentation for the analysis layer
│
├── datasets/                        # Source CSV files, split into initial_load + monthly batches
│
└── README.md                        # (this file)
```

Each subfolder has its own detailed `README.md` — this file is the map that
ties them together. Start here, then dive into whichever layer interests
you most.

---

## 🏛️ Architecture: Medallion (Bronze → Silver → Gold)

![High Level Architecture](Data%20Warehouse/Docs/data_architecture.png)

| Layer  | Object Type | Load Strategy                 | What Happens Here                                                    |
|--------|-------------|--------------------------------|------------------------------------------------------------------------|
| 🥉 Bronze | Tables   | Batch + Incremental (Append)   | Raw, untouched mirror of every source CSV, tagged by batch             |
| 🥈 Silver | Tables   | Batch + Incremental (Upsert)   | Cleansing, standardization, de-duplication, cross-system integration, SCD1/SCD2 |
| 🥇 Gold   | Views    | *No load step — always fresh*  | Star Schema: `dim_customers`, `dim_products`, `dim_branches`, `fact_sales` |

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
- **Gold layer as pure Views** — zero additional load step; reports always
  reflect the latest Silver data instantly.
- **14 analytical SQL scripts** — from schema exploration to YoY
  performance benchmarking to three consolidated reporting views
  (`report_customers`, `report_products`, `report_branches`).

👉 For the full list of real data-quality issues discovered and resolved
during this build (join fan-out, non-unique business keys, mismatched ID
formats across systems, MERGE conflicts on accumulated batches), see
[`Data Warehouse/README.md`](./Data%20Warehouse/README.md).

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

## 📊 Analysis Layer

Built entirely on top of `gold`, following a structured progression:

**Exploratory Data Analysis** → Database/Dimensions/Date/Measures
exploration → Magnitude & Ranking

**Advanced Analytics** → Change-over-time, Cumulative totals, YoY
Performance benchmarking, Customer/Product Segmentation, Part-to-Whole
contribution

**Semantic Reporting Layer** → Three consolidated, reusable views:
`gold.report_customers`, `gold.report_products`, `gold.report_branches` —
each combining recency, lifespan, segmentation, and revenue KPIs into a
single query-ready object.

Full breakdown of all 14 scripts: [`EDA & Advanced analysis/README.md`](./EDA%20&%20Advanced%20analysis/README.md)

### Example questions this project can answer
- Which branch generates the highest revenue, and how does it compare to
  its own historical average and last year's performance?
- Which product category contributes the largest share of total revenue?
- How does the customer base break down into VIP / Regular / New segments?
- What is the running total and month-over-month trend of total sales?
- Which products are top/bottom performers, and which have been
  discontinued?

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

---

## 🛠️ Tech Stack

- **Database:** SQL Server (T-SQL)
- **Engineering:** Stored Procedures, Dynamic SQL, Table-Valued Functions,
  `BULK INSERT`, `MERGE` (Upsert), SCD Type 1 & 2, Idempotent/Incremental
  Load Design
- **Analytics:** Window Functions (`LEAD`, `LAG`, `SUM/AVG OVER`,
  `DENSE_RANK`), CTEs, `ROLLUP`, Date Intelligence, Business Segmentation
- **Modeling:** Dimensional Modeling / Star Schema
- **Data Generation:** Python (synthetic dataset design with intentional
  data-quality issues)

---

## 🔭 Possible Future Extensions

- A Python/EDA notebook layered directly on `gold.fact_sales`
- A Power BI dashboard consuming the Gold semantic layer
- SQL Server Agent scheduling to automate monthly batch ingestion

---

## 👤 Author

Ahmed Khedr — built as a Data Analyst/Engineer portfolio project covering the full
lifecycle of a real-world Data Warehouse: dataset design, incremental ETL
engineering, data cleansing, dimensional modeling, and business analytics.

🔗 [GitHub](https://github.com/ahmedkhedr-xrs)
🔗 [!linkedin](www.linkedin.com/in/ahmed-fareed-khedr)


# Data Catalog for Gold Layer

## Overview
The Gold Layer is the business-level data representation, structured to support
analytical and reporting use cases. It follows a Star Schema and consists of
three **dimension** views and one **fact** view. All objects in this layer are
implemented as SQL Views (not physical tables) to guarantee that reports and
BI tools always read the freshest data available in Silver, with no additional
load step required.

---

### 1. **gold.dim_customers**
- **Purpose:** Stores customer details enriched with demographic and geographic
  data sourced from two integrated systems (ERP + CRM).
- **Grain:** One row per customer.

| Column Name     | Data Type     | Description                                                                                     |
|------------------|---------------|---------------------------------------------------------------------------------------------------|
| customer_key     | INT           | Surrogate key uniquely identifying each customer record in this dimension. Generated via `ROW_NUMBER()` ordered by `customer_id`. |
| customer_id      | INT           | Natural/business key from the source ERP system (`cst_id`).                                       |
| customer_number  | NVARCHAR(50)  | Alphanumeric customer identifier used across systems for integration (`cst_key`, e.g. `EG00020005`). |
| first_name       | NVARCHAR(50)  | Customer's first name.                                                                             |
| last_name        | NVARCHAR(50)  | Customer's last name.                                                                               |
| city             | NVARCHAR(50)  | Customer's governorate/city, sourced from the CRM system (`crm_customer_region`). Value is `'n/a'` when unmatched or unknown. |
| marital_status   | NVARCHAR(50)  | Standardized marital status: `'Single'`, `'Married'`, or `'n/a'`.                                  |
| gender           | NVARCHAR(50)  | Standardized gender: `'Male'`, `'Female'`, or `'n/a'`. ERP is the primary source; falls back to CRM demographic data when ERP value is `'n/a'`. |
| birthdate        | DATE          | Customer's date of birth, sourced from CRM demographic data (`crm_customer_demographics`). NULL if not available. |
| create_date      | DATE          | Date the customer record was first created in the source ERP system.                              |

---

### 2. **gold.dim_products**
- **Purpose:** Provides the **current** catalog of products and their category
  attributes. Historical price versions (SCD2) are intentionally excluded here.
- **Grain:** One row per active product (`prd_end_dt IS NULL`).

| Column Name     | Data Type     | Description                                                                                       |
|------------------|---------------|-------------------------------------------------------------------------------------------------------|
| product_key      | INT           | Surrogate key uniquely identifying each product record. Generated via `ROW_NUMBER()` ordered by `(prd_start_dt, prd_key)`. |
| product_id       | INT           | Internal numeric identifier for the product version (`prd_id`).                                    |
| product_number   | NVARCHAR(50)  | Business SKU code for the product (`prd_key`, e.g. `MOB_SMP-1001`). Used to join with the sales fact table. |
| product_name     | NVARCHAR(50)  | Descriptive/marketing name of the product. Not guaranteed unique across different SKUs.            |
| category_id      | NVARCHAR(50)  | Category reference code (`general_prd_key`, first 7 characters of `product_number`), links to `crm_category_reference`. |
| category_name    | NVARCHAR(50)  | High-level product category (e.g., Mobile Devices, Computers, Gaming, Displays, Accessories).       |
| sub_category     | NVARCHAR(50)  | More detailed classification within the category (e.g., Smartphones, Laptops, Consoles).            |
| warranty         | NVARCHAR(50)  | Whether the product category typically includes extended warranty coverage: `'Yes'` / `'No'`.       |
| cost             | INT           | Current cost of the product in EGP. Represents the latest known price version only.                 |
| start_date       | DATE          | Date this product/price version became effective (`prd_start_dt`).                                  |

> **Note:** Products that have been fully discontinued (their last version has a
> non-NULL `prd_end_dt` with no newer version) will **not** appear in this view.
> Historical sales referencing such products will show a NULL `product_key` in
> `gold.fact_sales`.

---

### 3. **gold.dim_branches**
- **Purpose:** Stores the physical store branches through which sales occur.
- **Grain:** One row per branch.

| Column Name     | Data Type     | Description                                                              |
|------------------|---------------|---------------------------------------------------------------------------|
| branch_key       | INT           | Surrogate/natural key identifying the branch (`branch_id`).               |
| branch_name      | NVARCHAR(50)  | Display name of the branch (e.g., 'Nasr City Branch').                    |
| city             | NVARCHAR(50)  | City/governorate where the branch is located.                             |
| open_date        | DATE          | Date the branch opened for business.                                      |

---

### 4. **gold.fact_sales**
- **Purpose:** Stores transactional sales data at the order-line grain for
  analytical purposes. Append-only — historical rows are never updated.
- **Grain:** One row per sales order line item.

| Column Name     | Data Type     | Description                                                                                  |
|------------------|---------------|--------------------------------------------------------------------------------------------------|
| order_number     | NVARCHAR(50)  | Unique alphanumeric identifier for the sales order (e.g., `SO60015`). Multiple rows may share the same order number (multi-item orders). |
| product_key      | INT           | Foreign key to `gold.dim_products.product_key`.                                                   |
| customer_key     | INT           | Foreign key to `gold.dim_customers.customer_key`.                                                 |
| branch_key       | INT           | Foreign key to `gold.dim_branches.branch_key`.                                                     |
| order_date       | DATE          | Date the order was placed.                                                                        |
| shipping_date    | DATE          | Date the order was shipped. May be NULL for invalid/unrecorded source dates.                       |
| due_date         | DATE          | Payment due date for the order.                                                                    |
| sales_amount     | INT           | Total monetary value of the line item, in EGP (validated as `quantity * price` during Silver cleansing). |
| quantity         | INT           | Number of units ordered for this line item.                                                       |
| price            | INT           | Unit price at the time of sale, in EGP.                                                            |

---

## Star Schema Relationships

```
gold.dim_customers (1) ───< (M) gold.fact_sales (M) >─── (1) gold.dim_products
                                       │
                                       ∨ (M)
                                 gold.dim_branches (1)
```

- `fact_sales.customer_key` → `dim_customers.customer_key`
- `fact_sales.product_key`  → `dim_products.product_key`
- `fact_sales.branch_key`   → `dim_branches.branch_key`

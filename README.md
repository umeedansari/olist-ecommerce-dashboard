# E-Commerce Sales Intelligence Dashboard
### Data Analyst Internship Assignment — Olist Brazilian E-Commerce Dataset

---

## Project Overview

This project analyzes a real-world Brazilian e-commerce dataset (Olist) to extract business insights and present them through an interactive Power BI dashboard. The goal was to understand sales performance, customer behavior, and product trends using data cleaning, SQL analysis, and visualization.

---

## Dataset

**Source:** [Olist Brazilian E-Commerce — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains ~100,000 real orders placed between 2016 and 2018 across multiple tables:

| File | Description |
|------|-------------|
| olist_orders_dataset.csv | Order status and timestamps |
| olist_customers_dataset.csv | Customer location info |
| olist_order_items_dataset.csv | Products per order with price |
| olist_order_payments_dataset.csv | Payment method and value |
| olist_products_dataset.csv | Product category details |
| olist_order_reviews_dataset.csv | Customer review scores |
| product_category_name_translation.csv | Portuguese to English category names |

---

## Project Structure

```
ecommerce-dashboard/
│
├── data/
│   └── cleaned_data/
│       ├── master_orders.csv
│       ├── order_items_clean.csv
│       ├── products_clean.csv
│       ├── customers_clean.csv
│       └── reviews_clean.csv
│
├── scripts/
│   └── data_cleaning.py
│
├── sql/
│   ├── create_and_load.sql
│   └── sql_analysis.sql
│
├── dashboard/
│   └── ecommerce_dashboard.pbix
│
└── README.md
```

---

## Tools Used

- **Python (pandas)** — Data cleaning and preprocessing
- **PostgreSQL (Docker)** — Database setup and SQL analysis
- **Power BI Desktop** — Dashboard and visualizations
- **VS Code** — Development environment

---

## Approach

### 1. Data Cleaning (Python)
- Loaded all 6 raw CSV files from Kaggle
- Removed duplicate rows across all tables
- Filtered only **delivered** orders for accurate revenue analysis
- Converted date columns to proper datetime format
- Translated product category names from Portuguese to English
- Added derived columns: `month`, `year`, `year_month`, `delivery_days`
- Removed rows with zero or negative price/payment values
- Merged all cleaned tables into one **master_orders** dataset
- Saved 5 cleaned CSVs ready for SQL and Power BI

### 2. SQL Analysis (PostgreSQL)
- Created an `olist` schema and loaded all cleaned CSVs
- Wrote queries to compute 4 key KPIs:
  - Total Revenue (overall, by year, by category)
  - Average Order Value (overall, monthly, by category)
  - Customer Retention Rate (one-time vs returning customers)
  - Monthly Sales Growth (month-over-month % change using LAG)
- Additional queries for product performance, state-wise revenue, and review scores

### 3. Power BI Dashboard
Built a 3-page interactive dashboard:

**Page 1 — Sales Overview**
- KPI Cards: Total Revenue, Total Orders, Avg Order Value, Total Customers
- Monthly Revenue Trend (line chart)
- Top Categories by Revenue (bar chart)
- Payment Type Breakdown (donut chart)

**Page 2 — Customer Insights**
- Revenue by State (bar chart)
- Customer Distribution Map
- One-Time vs Returning Customers (donut chart)
- Top Cities Table

**Page 3 — Product Performance**
- Best Selling Categories by Order Count
- Revenue vs Review Score (scatter chart)
- Avg Order Value by Category

Slicers added for: Year, Month, Product Category, Customer State

---

## Key Business Insights

### 1. Health & Beauty is the Top Revenue-Generating Category
Health & Beauty products consistently generate the highest revenue across the dataset period. This category also has a high average order value, suggesting customers are willing to spend more on personal care products. The business should prioritize inventory and promotions in this category.

### 2. Over 95% of Customers Never Return
The customer retention rate is extremely low — more than 95% of customers made only one purchase. This is a major red flag for long-term business sustainability. The company should invest heavily in loyalty programs, post-purchase follow-up emails, and repeat-purchase discounts to improve this number.

### 3. Revenue Peaked in November 2017 (Black Friday Effect)
Monthly sales data shows a sharp revenue spike in November 2017 — clearly driven by Black Friday and end-of-year shopping. This tells us seasonal promotions have a significant impact. Planning campaigns around this period every year could reliably boost annual revenue.

### 4. São Paulo Dominates Both Customers and Revenue
The state of São Paulo (SP) accounts for the largest share of both customer count and total revenue by a wide margin. This suggests heavy urban concentration of the customer base. Expanding marketing efforts to underserved states could unlock significant untapped revenue potential.

### 5. Credit Card is the Most Preferred Payment Method
The majority of orders are paid via credit card, often in installments. This indicates customers prefer the flexibility of paying over time. Offering more installment options or partnering with additional card providers could help increase average order values and conversion rates.

---

## How to Run This Project

### 1. Data Cleaning
```bash
pip install pandas
python scripts/data_cleaning.py
```
Place all raw Kaggle CSVs in the same folder as the script.

### 2. Load into PostgreSQL
- Start your PostgreSQL instance (Docker or local)
- Open `sql/create_and_load.sql` in VS Code
- Update file paths to match your machine
- Run the script to create the `olist` schema and load all tables

### 3. Run SQL Analysis
- Open `sql/sql_analysis.sql` in VS Code
- Run individual queries to see KPI results

### 4. Power BI Dashboard
- Open `dashboard/ecommerce_dashboard.pbix` in Power BI Desktop
- Update the PostgreSQL connection to your local credentials if prompted

---

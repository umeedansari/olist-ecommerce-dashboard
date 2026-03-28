# ============================================================
# E-Commerce Sales Intelligence - Data Cleaning Script
# Dataset: Olist Brazilian E-Commerce (Kaggle)
# Author: Data Analyst Assignment
# ============================================================

import pandas as pd
import numpy as np
import os
import warnings
warnings.filterwarnings("ignore")

# ============================================================
# CONFIGURATION - Set your dataset folder path here
# ============================================================
DATA_PATH = "./data/"          # Folder where you unzipped Kaggle files
OUTPUT_PATH = "./cleaned_data/"      # Where cleaned files will be saved

os.makedirs(OUTPUT_PATH, exist_ok=True)

# ============================================================
# STEP 1: LOAD ALL RAW DATASETS
# ============================================================
print("=" * 60)
print("STEP 1: Loading Raw Datasets")
print("=" * 60)

orders        = pd.read_csv(DATA_PATH + "olist_orders_dataset.csv")
customers     = pd.read_csv(DATA_PATH + "olist_customers_dataset.csv")
order_items   = pd.read_csv(DATA_PATH + "olist_order_items_dataset.csv")
payments      = pd.read_csv(DATA_PATH + "olist_order_payments_dataset.csv")
products      = pd.read_csv(DATA_PATH + "olist_products_dataset.csv")
sellers       = pd.read_csv(DATA_PATH + "olist_sellers_dataset.csv")
reviews       = pd.read_csv(DATA_PATH + "olist_order_reviews_dataset.csv")
category_map  = pd.read_csv(DATA_PATH + "product_category_name_translation.csv")

print(f"  orders        : {orders.shape}")
print(f"  customers     : {customers.shape}")
print(f"  order_items   : {order_items.shape}")
print(f"  payments      : {payments.shape}")
print(f"  products      : {products.shape}")
print(f"  sellers       : {sellers.shape}")
print(f"  reviews       : {reviews.shape}")
print(f"  category_map  : {category_map.shape}")


# ============================================================
# HELPER FUNCTION: Quick summary before/after cleaning
# ============================================================
def cleaning_summary(df, name):
    print(f"\n  [{name}]")
    print(f"    Rows       : {df.shape[0]}")
    print(f"    Columns    : {df.shape[1]}")
    print(f"    Nulls      : {df.isnull().sum().sum()}")
    print(f"    Duplicates : {df.duplicated().sum()}")


# ============================================================
# STEP 2: CLEAN ORDERS TABLE
# ============================================================
print("\n" + "=" * 60)
print("STEP 2: Cleaning Orders Table")
print("=" * 60)

cleaning_summary(orders, "BEFORE")

# 2a. Convert all date columns to datetime
date_cols = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date"
]
for col in date_cols:
    orders[col] = pd.to_datetime(orders[col], errors="coerce")

# 2b. Keep only 'delivered' orders for revenue analysis
#     (canceled/unavailable orders should not count as sales)
print(f"\n  Order status distribution:\n{orders['order_status'].value_counts()}")
orders_clean = orders[orders["order_status"] == "delivered"].copy()
print(f"\n  Kept 'delivered' orders: {len(orders_clean)} rows")

# 2c. Drop rows where purchase timestamp is null (can't analyze without date)
before = len(orders_clean)
orders_clean.dropna(subset=["order_purchase_timestamp"], inplace=True)
print(f"  Dropped {before - len(orders_clean)} rows with null purchase timestamp")

# 2d. Add useful derived time columns
orders_clean["order_year"]       = orders_clean["order_purchase_timestamp"].dt.year
orders_clean["order_month"]      = orders_clean["order_purchase_timestamp"].dt.month
orders_clean["order_month_name"] = orders_clean["order_purchase_timestamp"].dt.strftime("%b")
orders_clean["order_quarter"]    = orders_clean["order_purchase_timestamp"].dt.quarter
orders_clean["order_year_month"] = orders_clean["order_purchase_timestamp"].dt.to_period("M").astype(str)
orders_clean["delivery_days"]    = (
    orders_clean["order_delivered_customer_date"] -
    orders_clean["order_purchase_timestamp"]
).dt.days

# 2e. Remove duplicates
orders_clean.drop_duplicates(subset=["order_id"], inplace=True)

cleaning_summary(orders_clean, "AFTER")


# ============================================================
# STEP 3: CLEAN ORDER ITEMS TABLE
# ============================================================
print("\n" + "=" * 60)
print("STEP 3: Cleaning Order Items Table")
print("=" * 60)

cleaning_summary(order_items, "BEFORE")

# 3a. Convert shipping_limit_date to datetime
order_items["shipping_limit_date"] = pd.to_datetime(
    order_items["shipping_limit_date"], errors="coerce"
)

# 3b. Remove rows with non-positive price or freight value
before = len(order_items)
order_items_clean = order_items[
    (order_items["price"] > 0) & (order_items["freight_value"] >= 0)
].copy()
print(f"\n  Removed {before - len(order_items_clean)} rows with invalid price/freight")

# 3c. Create total item revenue column
order_items_clean["item_revenue"] = (
    order_items_clean["price"] + order_items_clean["freight_value"]
)

# 3d. Remove duplicates
order_items_clean.drop_duplicates(inplace=True)

cleaning_summary(order_items_clean, "AFTER")


# ============================================================
# STEP 4: CLEAN PAYMENTS TABLE
# ============================================================
print("\n" + "=" * 60)
print("STEP 4: Cleaning Payments Table")
print("=" * 60)

cleaning_summary(payments, "BEFORE")

# 4a. Remove zero/negative payment values
before = len(payments)
payments_clean = payments[payments["payment_value"] > 0].copy()
print(f"\n  Removed {before - len(payments_clean)} rows with invalid payment value")

# 4b. Aggregate payments per order (one order can have multiple payment rows)
payments_agg = payments_clean.groupby("order_id").agg(
    total_payment   = ("payment_value", "sum"),
    payment_types   = ("payment_type", lambda x: "|".join(x.unique())),
    installments    = ("payment_installments", "max")
).reset_index()

print(f"\n  Aggregated to {len(payments_agg)} unique orders")
print(f"  Payment types: {payments_clean['payment_type'].unique()}")

cleaning_summary(payments_agg, "AFTER")


# ============================================================
# STEP 5: CLEAN PRODUCTS TABLE
# ============================================================
print("\n" + "=" * 60)
print("STEP 5: Cleaning Products Table")
print("=" * 60)

cleaning_summary(products, "BEFORE")

# 5a. Translate Portuguese category names to English
products_clean = products.merge(
    category_map,
    on="product_category_name",
    how="left"
)

# 5b. Fill missing English category name with Portuguese original
products_clean["product_category_name_english"] = products_clean[
    "product_category_name_english"
].fillna(products_clean["product_category_name"])

# 5c. Fill missing English category name if both are null
products_clean["product_category_name_english"] = products_clean[
    "product_category_name_english"
].fillna("unknown")

# 5d. Fill missing numeric dimensions with median (reasonable imputation)
dimension_cols = [
    "product_name_lenght", "product_description_lenght",
    "product_photos_qty", "product_weight_g",
    "product_length_cm", "product_height_cm", "product_width_cm"
]
for col in dimension_cols:
    if col in products_clean.columns:
        median_val = products_clean[col].median()
        products_clean[col].fillna(median_val, inplace=True)

# 5e. Remove duplicates
products_clean.drop_duplicates(subset=["product_id"], inplace=True)

cleaning_summary(products_clean, "AFTER")


# ============================================================
# STEP 6: CLEAN CUSTOMERS TABLE
# ============================================================
print("\n" + "=" * 60)
print("STEP 6: Cleaning Customers Table")
print("=" * 60)

cleaning_summary(customers, "BEFORE")

# 6a. Standardize state codes to uppercase
customers["customer_state"] = customers["customer_state"].str.upper().str.strip()

# 6b. Standardize city names (title case, strip whitespace)
customers["customer_city"] = customers["customer_city"].str.title().str.strip()

# 6c. Drop duplicates on customer_id
customers_clean = customers.drop_duplicates(subset=["customer_id"]).copy()

cleaning_summary(customers_clean, "AFTER")


# ============================================================
# STEP 7: CLEAN REVIEWS TABLE
# ============================================================
print("\n" + "=" * 60)
print("STEP 7: Cleaning Reviews Table")
print("=" * 60)

cleaning_summary(reviews, "BEFORE")

# 7a. Keep only relevant columns
reviews_clean = reviews[[
    "review_id", "order_id", "review_score",
    "review_creation_date", "review_answer_timestamp"
]].copy()

# 7b. Convert dates
reviews_clean["review_creation_date"]    = pd.to_datetime(reviews_clean["review_creation_date"],    errors="coerce")
reviews_clean["review_answer_timestamp"] = pd.to_datetime(reviews_clean["review_answer_timestamp"], errors="coerce")

# 7c. Validate scores are between 1 and 5
before = len(reviews_clean)
reviews_clean = reviews_clean[reviews_clean["review_score"].between(1, 5)]
print(f"\n  Removed {before - len(reviews_clean)} rows with invalid review scores")

# 7d. Remove duplicate reviews (keep latest per order)
reviews_clean = reviews_clean.sort_values("review_creation_date", ascending=False)
reviews_clean.drop_duplicates(subset=["order_id"], keep="first", inplace=True)

cleaning_summary(reviews_clean, "AFTER")


# ============================================================
# STEP 8: BUILD MASTER DATASET (JOIN ALL TABLES)
# ============================================================
print("\n" + "=" * 60)
print("STEP 8: Building Master Dataset")
print("=" * 60)

# 8a. orders + customers
master = orders_clean.merge(customers_clean, on="customer_id", how="left")

# 8b. + payments
master = master.merge(payments_agg, on="order_id", how="left")

# 8c. + order_items (aggregated per order)
items_per_order = order_items_clean.groupby("order_id").agg(
    item_count       = ("order_item_id", "count"),
    total_items_revenue = ("item_revenue", "sum"),
    avg_item_price   = ("price", "mean"),
    product_ids      = ("product_id", lambda x: list(x))
).reset_index()

master = master.merge(items_per_order, on="order_id", how="left")

# 8d. + reviews
master = master.merge(
    reviews_clean[["order_id", "review_score"]],
    on="order_id", how="left"
)

# 8e. Final null check and fill
master["total_payment"].fillna(master["total_items_revenue"], inplace=True)
master["review_score"].fillna(0, inplace=True)   # 0 = no review

# 8f. Remove any orders without revenue data
before = len(master)
master.dropna(subset=["total_payment"], inplace=True)
print(f"\n  Dropped {before - len(master)} rows with missing revenue")

print(f"\n  ✅ Master dataset shape: {master.shape}")
print(f"  Columns: {list(master.columns)}")


# ============================================================
# STEP 9: FINAL DATA QUALITY REPORT
# ============================================================
print("\n" + "=" * 60)
print("STEP 9: Final Data Quality Report")
print("=" * 60)

print(f"\n  Total Orders (delivered)  : {master['order_id'].nunique():,}")
print(f"  Total Customers           : {master['customer_id'].nunique():,}")
print(f"  Date Range                : {master['order_purchase_timestamp'].min().date()} → {master['order_purchase_timestamp'].max().date()}")
print(f"  Total Revenue (BRL)       : R$ {master['total_payment'].sum():,.2f}")
print(f"  Avg Order Value           : R$ {master['total_payment'].mean():,.2f}")
print(f"  Avg Review Score          : {master[master['review_score'] > 0]['review_score'].mean():.2f} / 5.0")
print(f"\n  Remaining Nulls in Master :\n{master.isnull().sum()[master.isnull().sum() > 0]}")


# ============================================================
# STEP 10: SAVE ALL CLEANED FILES
# ============================================================
print("\n" + "=" * 60)
print("STEP 10: Saving Cleaned Files")
print("=" * 60)

master.drop(columns=["product_ids"], inplace=True)   # Remove list column before CSV save

master.to_csv(OUTPUT_PATH + "master_orders.csv", index=False)
orders_clean.to_csv(OUTPUT_PATH + "orders_clean.csv", index=False)
order_items_clean.to_csv(OUTPUT_PATH + "order_items_clean.csv", index=False)
payments_agg.to_csv(OUTPUT_PATH + "payments_clean.csv", index=False)
products_clean.to_csv(OUTPUT_PATH + "products_clean.csv", index=False)
customers_clean.to_csv(OUTPUT_PATH + "customers_clean.csv", index=False)
reviews_clean.to_csv(OUTPUT_PATH + "reviews_clean.csv", index=False)

print(f"""
  Saved to '{OUTPUT_PATH}':
    ✅ master_orders.csv       ← Main file for Power BI & SQL
    ✅ orders_clean.csv
    ✅ order_items_clean.csv
    ✅ payments_clean.csv
    ✅ products_clean.csv
    ✅ customers_clean.csv
    ✅ reviews_clean.csv
""")

print("=" * 60)
print("✅ DATA CLEANING COMPLETE — Ready for SQL Analysis & Power BI")
print("=" * 60)
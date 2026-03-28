-- ============================================================
-- E-Commerce Sales Intelligence
-- Create Tables + Load Cleaned CSVs into PostgreSQL
-- ============================================================


-- ============================================================
-- 1. MASTER ORDERS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS OLIST;

DROP TABLE IF EXISTS OLIST.master_orders;

CREATE TABLE olist.master_orders (
    order_id                      VARCHAR(50),
    customer_id                   VARCHAR(50),
    order_status                  VARCHAR(30),
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    order_year                    INT,
    order_month                   INT,
    order_month_name              VARCHAR(10),
    order_quarter                 INT,
    order_year_month              VARCHAR(20), -- keep as text
    delivery_days                 NUMERIC,     -- decimals allowed
    customer_unique_id            VARCHAR(50),
    customer_zip_code_prefix      VARCHAR(10),
    customer_city                 VARCHAR(100),
    customer_state                VARCHAR(5),
    total_payment                 NUMERIC,
    payment_types                 VARCHAR(100),
    installments                  NUMERIC,     -- allow decimals
    item_count                    INT,
    total_items_revenue           NUMERIC,
    avg_item_price                NUMERIC,
    review_score                  NUMERIC
);

COPY olist.master_orders
FROM '/cleaned_data/master_orders.csv'
DELIMITER ','
CSV HEADER;


-- ============================================================
-- 2. ORDERS CLEAN
-- ============================================================

DROP TABLE IF EXISTS OLIST.orders_clean;

CREATE TABLE OLIST.orders_clean (
    order_id                        VARCHAR(50),
    customer_id                     VARCHAR(50),
    order_status                    VARCHAR(30),
    order_purchase_timestamp        TIMESTAMP,
    order_approved_at               TIMESTAMP,
    order_delivered_carrier_date    TIMESTAMP,
    order_delivered_customer_date   TIMESTAMP,
    order_estimated_delivery_date   TIMESTAMP,
    order_year                      INT,
    order_month                     INT,
    order_month_name                VARCHAR(10),
    order_quarter                   INT,
    order_year_month                VARCHAR(10),
    delivery_days                   FLOAT
);

COPY olist.orders_clean FROM '/cleaned_data/orders_clean.csv' DELIMITER ',' CSV HEADER NULL '';


-- ============================================================
-- 3. ORDER ITEMS CLEAN
-- ============================================================

DROP TABLE IF EXISTS order_items_clean;

    CREATE TABLE olist.order_items_clean (
        order_id                VARCHAR(50),
        order_item_id           INT,
        product_id              VARCHAR(50),
        seller_id               VARCHAR(50),
        shipping_limit_date     TIMESTAMP,
        price                   FLOAT,
        freight_value           FLOAT,
        item_revenue            FLOAT
    );

COPY olist.order_items_clean FROM '/cleaned_data/order_items_clean.csv' DELIMITER ',' CSV HEADER NULL '';


-- ============================================================
-- 4. PAYMENTS CLEAN
-- ============================================================

DROP TABLE IF EXISTS payments_clean;

CREATE TABLE olist.payments_clean (
    order_id        VARCHAR(50),
    total_payment   FLOAT,
    payment_types   VARCHAR(100),
    installments    INT
);

COPY olist.payments_clean FROM '/cleaned_data/payments_clean.csv' DELIMITER ',' CSV HEADER NULL '';


-- ============================================================
-- 5. PRODUCTS CLEAN
-- ============================================================

DROP TABLE IF EXISTS products_clean;

CREATE TABLE olist.products_clean (
    product_id                      VARCHAR(50),
    product_category_name           VARCHAR(100),
    product_name_lenght             FLOAT,
    product_description_lenght      FLOAT,
    product_photos_qty              FLOAT,
    product_weight_g                FLOAT,
    product_length_cm               FLOAT,
    product_height_cm               FLOAT,
    product_width_cm                FLOAT,
    product_category_name_english   VARCHAR(100)
);

COPY olist.products_clean FROM '/cleaned_data/products_clean.csv' DELIMITER ',' CSV HEADER NULL '';


-- ============================================================
-- 6. CUSTOMERS CLEAN
-- ============================================================

DROP TABLE IF EXISTS customers_clean;

CREATE TABLE olist.customers_clean (
    customer_id                 VARCHAR(50),
    customer_unique_id          VARCHAR(50),
    customer_zip_code_prefix    VARCHAR(10),
    customer_city               VARCHAR(100),
    customer_state              VARCHAR(5)
);

COPY olist.customers_clean FROM '/cleaned_data/customers_clean.csv' DELIMITER ',' CSV HEADER NULL '';


-- ============================================================
-- 7. REVIEWS CLEAN
-- ============================================================

DROP TABLE IF EXISTS reviews_clean;

CREATE TABLE olist.reviews_clean (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50),
    review_score            INT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

COPY olist.reviews_clean FROM '/cleaned_data/reviews_clean.csv' DELIMITER ',' CSV HEADER NULL '';


-- ============================================================
-- VERIFY ALL TABLES LOADED CORRECTLY
-- ============================================================

SELECT 'master_orders'    AS table_name, COUNT(*) AS row_count FROM olist.master_orders
UNION ALL
SELECT 'orders_clean',      COUNT(*) FROM olist.orders_clean
UNION ALL
SELECT 'order_items_clean', COUNT(*) FROM olist.order_items_clean
UNION ALL
SELECT 'payments_clean',    COUNT(*) FROM olist.payments_clean
UNION ALL
SELECT 'products_clean',    COUNT(*) FROM olist.products_clean
UNION ALL
SELECT 'customers_clean',   COUNT(*) FROM olist.customers_clean
UNION ALL
SELECT 'reviews_clean',     COUNT(*) FROM olist.reviews_clean;
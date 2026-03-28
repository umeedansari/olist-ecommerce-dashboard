-- ============================================================
-- E-Commerce Sales Intelligence
-- SQL KPI Analysis Queries
-- Schema: olist | Dataset: Olist Brazilian E-Commerce
-- ============================================================


-- ============================================================
-- KPI 1: TOTAL REVENUE
-- ============================================================

-- Overall total revenue
SELECT
    ROUND(SUM(total_payment)::NUMERIC, 2) AS total_revenue
FROM olist.master_orders;


-- Total revenue by year
SELECT
    order_year,
    ROUND(SUM(total_payment)::NUMERIC, 2) AS total_revenue
FROM olist.master_orders
GROUP BY order_year
ORDER BY order_year;


-- Total revenue by month (all years combined)
SELECT
    order_month_name,
    order_month,
    ROUND(SUM(total_payment)::NUMERIC, 2) AS total_revenue
FROM olist.master_orders
GROUP BY order_month_name, order_month
ORDER BY order_month;


-- Total revenue by product category (top 10)
SELECT
    p.product_category_name_english AS category,
    ROUND(SUM(oi.item_revenue)::NUMERIC, 2) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM olist.order_items_clean oi
JOIN olist.products_clean p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- KPI 2: AVERAGE ORDER VALUE (AOV)
-- ============================================================

-- Overall AOV
SELECT
    ROUND(AVG(total_payment)::NUMERIC, 2) AS avg_order_value
FROM olist.master_orders;


-- AOV by order_month (monthly trend)
SELECT
    order_month,
    ROUND(AVG(total_payment)::NUMERIC, 2) AS avg_order_value,
    COUNT(order_id) AS total_orders
FROM olist.master_orders
GROUP BY order_month
ORDER BY order_month;


-- AOV by product category (top 10)
SELECT
    p.product_category_name_english AS category,
    ROUND(AVG(oi.item_revenue)::NUMERIC, 2) AS avg_order_value
FROM olist.order_items_clean oi
JOIN olist.products_clean p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
ORDER BY avg_order_value DESC
LIMIT 10;


-- AOV by customer state
SELECT
    customer_state,
    ROUND(AVG(total_payment)::NUMERIC, 2) AS avg_order_value,
    COUNT(order_id) AS total_orders
FROM olist.master_orders
GROUP BY customer_state
ORDER BY avg_order_value DESC;


-- ============================================================
-- KPI 3: CUSTOMER RETENTION RATE
-- ============================================================

-- One-time vs returning customers with percentage
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time Customer'
        ELSE 'Returning Customer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM (
    SELECT
        customer_unique_id,
        COUNT(order_id) AS order_count
    FROM olist.master_orders
    GROUP BY customer_unique_id
) AS customer_orders
GROUP BY customer_type;


-- Retention rate as a single number
SELECT
    ROUND(
        COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS retention_rate_percent
FROM (
    SELECT
        customer_unique_id,
        COUNT(order_id) AS order_count
    FROM olist.master_orders
    GROUP BY customer_unique_id
) AS t;


-- Top states by returning customers
SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS returning_customers
FROM olist.master_orders
WHERE customer_unique_id IN (
    SELECT customer_unique_id
    FROM olist.master_orders
    GROUP BY customer_unique_id
    HAVING COUNT(order_id) > 1
)
GROUP BY customer_state
ORDER BY returning_customers DESC
LIMIT 10;


-- ============================================================
-- KPI 4: MONTHLY SALES GROWTH
-- ============================================================

-- Month over month revenue + growth %
SELECT
    order_month,
    ROUND(SUM(total_payment)::NUMERIC, 2) AS monthly_revenue,
    ROUND(
        (SUM(total_payment) - LAG(SUM(total_payment)) OVER (ORDER BY order_month))
        * 100.0 / NULLIF(LAG(SUM(total_payment)) OVER (ORDER BY order_month), 0),
    2) AS growth_percent
FROM olist.master_orders
GROUP BY order_month
ORDER BY order_month;


-- Best 5 growth months
SELECT
    order_month,
    monthly_revenue,
    growth_percent
FROM (
    SELECT
        order_month,
        ROUND(SUM(total_payment)::NUMERIC, 2) AS monthly_revenue,
        ROUND(
            (SUM(total_payment) - LAG(SUM(total_payment)) OVER (ORDER BY order_month))
            * 100.0 / NULLIF(LAG(SUM(total_payment)) OVER (ORDER BY order_month), 0),
        2) AS growth_percent
    FROM olist.master_orders
    GROUP BY order_month
) monthly
WHERE growth_percent IS NOT NULL
ORDER BY growth_percent DESC
LIMIT 5;


-- Worst 5 growth months (drop detection)
SELECT
    order_month,
    monthly_revenue,
    growth_percent
FROM (
    SELECT
        order_month,
        ROUND(SUM(total_payment)::NUMERIC, 2) AS monthly_revenue,
        ROUND(
            (SUM(total_payment) - LAG(SUM(total_payment)) OVER (ORDER BY order_month))
            * 100.0 / NULLIF(LAG(SUM(total_payment)) OVER (ORDER BY order_month), 0),
        2) AS growth_percent
    FROM olist.master_orders
    GROUP BY order_month
) monthly
WHERE growth_percent IS NOT NULL
ORDER BY growth_percent ASC
LIMIT 5;


-- ============================================================
-- BONUS: EXTRA INSIGHT QUERIES (For Power BI Dashboard)
-- ============================================================

-- Top 10 best selling categories by order count
SELECT
    p.product_category_name_english AS category,
    COUNT(oi.order_id)              AS times_ordered,
    ROUND(SUM(oi.item_revenue)::NUMERIC, 2) AS total_revenue
FROM olist.order_items_clean oi
JOIN olist.products_clean p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
ORDER BY times_ordered DESC
LIMIT 10;


-- Average delivery days by customer state
SELECT
    customer_state,
    ROUND(AVG(delivery_days)::NUMERIC, 1) AS avg_delivery_days,
    COUNT(order_id) AS total_orders
FROM olist.master_orders
WHERE delivery_days IS NOT NULL AND delivery_days > 0
GROUP BY customer_state
ORDER BY avg_delivery_days ASC;


-- Revenue by customer state
SELECT
    customer_state,
    ROUND(SUM(total_payment)::NUMERIC, 2)       AS total_revenue,
    COUNT(DISTINCT customer_unique_id)           AS unique_customers
FROM olist.master_orders
GROUP BY customer_state
ORDER BY total_revenue DESC;


-- Average review score by product category
SELECT
    p.product_category_name_english             AS category,
    ROUND(AVG(m.review_score)::NUMERIC, 2)      AS avg_review_score,
    COUNT(m.order_id)                           AS total_orders
FROM olist.master_orders m
JOIN olist.order_items_clean oi ON m.order_id = oi.order_id
JOIN olist.products_clean p     ON oi.product_id = p.product_id
WHERE m.review_score > 0
GROUP BY p.product_category_name_english
ORDER BY avg_review_score DESC
LIMIT 10;


-- Payment type breakdown
SELECT
    payment_types,
    COUNT(order_id)                             AS total_orders,
    ROUND(SUM(total_payment)::NUMERIC, 2)       AS total_revenue,
    ROUND(AVG(total_payment)::NUMERIC, 2)       AS avg_order_value
FROM olist.master_orders
GROUP BY payment_types
ORDER BY total_orders DESC;


-- Orders by quarter
SELECT
    order_year,
    order_quarter,
    COUNT(order_id)                             AS total_orders,
    ROUND(SUM(total_payment)::NUMERIC, 2)       AS total_revenue
FROM olist.master_orders
GROUP BY order_year, order_quarter
ORDER BY order_year, order_quarter;
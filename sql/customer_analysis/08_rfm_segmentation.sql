-- ============================================================
-- QUERY 8: RFM SEGMENTATION
-- ============================================================
-- Business Question: Which customers are high-value/engaged versus
--   at-risk or lost, based on Recency, Frequency, and Monetary value?
-- Stakeholder: Marketing -- this directly drives retention vs.
--   win-back vs. no-spend targeting decisions.
-- SQL Concepts: CTE chain, NTILE() for quintile scoring, CASE WHEN
--   for human-readable segment labels
--
-- Identity note: grouped by customer_unique_id, not customer_id.
-- customer_id is generated per order, so using it here would make
-- every customer appear to have exactly one order, by construction.
--
-- Grain note: order_items is at the line-item grain, while orders
-- and customers are at the order/person grain. Revenue is rolled up
-- to one row per order_id FIRST (order_revenue CTE), and only that
-- pre-aggregated, order-grain value is carried into the customer-level
-- rollup. This keeps frequency (order count) and monetary (order
-- revenue) consistently derived from the same order grain, rather
-- than mixing line-item-grain aggregation into the customer step.
-- ============================================================

-- Step 1: collapse order_items down to one row per order_id.
-- This is the only place line-item grain is touched in this query.
WITH order_revenue AS (
    SELECT
        oi.order_id,
        ROUND(SUM(oi.price), 2) AS order_revenue
    FROM order_items oi
    GROUP BY oi.order_id
),

-- Step 2: anchor date for recency. "Today" is anchored to the day
-- after the dataset's last order (rather than CURRENT_DATE) since
-- this is a historical 2016-2018 dataset, not a live feed -- using
-- real "today" would make every customer look maximally inactive.
dataset_anchor_date AS (
    SELECT MAX(order_purchase_timestamp)::DATE + 1 AS anchor_date
    FROM orders
),

-- Step 3: one row per real customer, with R/F/M raw values --
-- built entirely from order-grain data (orders + order_revenue),
-- never touching order_items directly.
customer_rfm_raw AS (
    SELECT
        c.customer_unique_id,
        (SELECT anchor_date FROM dataset_anchor_date)
            - MAX(o.order_purchase_timestamp)::DATE AS recency_days,
        COUNT(DISTINCT o.order_id)                   AS frequency_orders,
        ROUND(SUM(orev.order_revenue), 2)            AS monetary_value
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    JOIN order_revenue orev
        ON orev.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
),

-- Step 4: score each dimension 1-5.
-- Recency and Monetary use NTILE(5) -- both are continuous-ish
-- distributions where quintile splits are meaningful.
-- Frequency does NOT use NTILE(5): 96% of customers (92,102 of
-- 95,990) placed exactly one order, so NTILE on a value this
-- heavily tied would arbitrarily split identical "1 order"
-- customers across multiple score buckets. Explicit business
-- tiers are used instead, anchored to the data's real breakpoints.
customer_rfm_scored AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency_orders,
        monetary_value,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS recency_score,
        CASE
            WHEN frequency_orders = 1 THEN 1
            WHEN frequency_orders = 2 THEN 3
            WHEN frequency_orders BETWEEN 3 AND 4 THEN 4
            ELSE 5
        END AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC) AS monetary_score
    FROM customer_rfm_raw
)

-- Step 5: combine scores into a readable segment label.
SELECT
    customer_unique_id,
    recency_days,
    frequency_orders,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score,
    CASE
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4
            THEN 'Champions'
        WHEN recency_score >= 4 AND frequency_score <= 2
            THEN 'New / Recent Customers'
        WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4
            THEN 'At Risk (High Value)'
        WHEN recency_score <= 2 AND frequency_score <= 2
            THEN 'Lost / Churned'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM customer_rfm_scored
ORDER BY monetary_value DESC
LIMIT 20;

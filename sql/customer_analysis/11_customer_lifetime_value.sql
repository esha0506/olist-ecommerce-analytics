-- ============================================================
-- QUERY 11: CUSTOMER LIFETIME VALUE (CLV)
-- ============================================================
-- Business Question: What is the historical lifetime value of
--   customers, and how is that value distributed -- is it broad-based
--   or concentrated in a small number of high-spend customers?
-- Stakeholder: Marketing / Finance -- informs how much can be spent
--   to acquire or retain a customer, and whether high-CLV customers
--   are a meaningful enough group to target specifically.
-- SQL Concepts: CTE, NTILE() for spend-based segmentation, aggregate
--   ratios, cumulative contribution via window function
--
-- Identity note: grouped by customer_unique_id, consistent with
-- Queries 8-10.
--
-- Grain note: revenue pre-aggregated to order grain in order_revenue
-- before rolling up to customer_unique_id -- same discipline as
-- Queries 8-9.
--
-- CLV scope: this is HISTORICAL CLV (actual lifetime revenue to
-- date), not predictive/modeled CLV. The dataset's fixed historical
-- window (2016-2018) means this measures realized value, not a
-- forecast of future value.
-- ============================================================

WITH order_revenue AS (
    SELECT
        oi.order_id,
        ROUND(SUM(oi.price), 2) AS order_revenue
    FROM order_items oi
    GROUP BY oi.order_id
),
customer_clv AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)        AS order_count,
        ROUND(SUM(orev.order_revenue), 2) AS lifetime_value
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    JOIN order_revenue orev
        ON orev.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
),
clv_segmented AS (
    SELECT
        customer_unique_id,
        order_count,
        lifetime_value,
        NTILE(5) OVER (ORDER BY lifetime_value DESC) AS clv_quintile
    FROM customer_clv
)
SELECT
    clv_quintile,
    COUNT(*)                                          AS customer_count,
    ROUND(SUM(lifetime_value), 2)                      AS segment_total_value,
    ROUND(AVG(lifetime_value), 2)                       AS avg_lifetime_value,
    ROUND(
        100.0 * SUM(lifetime_value) / SUM(SUM(lifetime_value)) OVER (),
        2
    )                                                   AS pct_of_total_value
FROM clv_segmented
GROUP BY clv_quintile
ORDER BY clv_quintile;

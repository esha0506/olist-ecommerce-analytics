-- ============================================================
-- QUERY 9: REPEAT PURCHASE ANALYSIS
-- ============================================================
-- Business Question: What share of customers make more than one
--   purchase, and how much revenue do repeat customers generate
--   compared to one-time buyers?
-- Stakeholder: Marketing / Executive team -- this is the foundational
--   number behind any retention-vs-acquisition investment decision.
-- SQL Concepts: CTE, conditional aggregation (CASE WHEN), aggregate
--   ratios
--
-- Identity note: grouped by customer_unique_id, not customer_id, for
-- the same reason established in Query 8 -- customer_id is generated
-- per order, so it cannot detect repeat behavior by construction.
--
-- Grain note: revenue is pre-aggregated to order grain in
-- order_revenue before being rolled up to customer_unique_id, keeping
-- the same grain discipline established in Query 8.
-- ============================================================

WITH order_revenue AS (
    SELECT
        oi.order_id,
        ROUND(SUM(oi.price), 2) AS order_revenue
    FROM order_items oi
    GROUP BY oi.order_id
),
customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)        AS order_count,
        ROUND(SUM(orev.order_revenue), 2) AS customer_revenue
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    JOIN order_revenue orev
        ON orev.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
),
customer_type AS (
    SELECT
        customer_unique_id,
        order_count,
        customer_revenue,
        CASE WHEN order_count > 1 THEN 'repeat_customer' ELSE 'one_time_customer' END AS customer_type
    FROM customer_orders
)
SELECT
    customer_type,
    COUNT(*)                                                        AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)               AS pct_of_customers,
    ROUND(SUM(customer_revenue), 2)                                  AS total_revenue,
    ROUND(100.0 * SUM(customer_revenue) / SUM(SUM(customer_revenue)) OVER (), 2) AS pct_of_revenue,
    ROUND(AVG(customer_revenue), 2)                                  AS avg_revenue_per_customer
FROM customer_type
GROUP BY customer_type
ORDER BY customer_type;

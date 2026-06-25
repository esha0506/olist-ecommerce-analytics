-- ============================================================
-- QUERY 3: RUNNING TOTAL REVENUE
-- ============================================================
-- Business Question: What does cumulative revenue look like over time?
-- Stakeholder: Executive team / Finance
-- SQL Concepts: Window function SUM() OVER (ORDER BY ...) -- cumulative sum
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS revenue_month,
        ROUND(SUM(oi.price), 2)                                AS product_revenue
    FROM orders o
    JOIN order_items oi
        ON oi.order_id = o.order_id
    -- Excludes canceled/unavailable orders only (not restricted to 'delivered').
    -- 'Delivered' alone would understate revenue for orders that are still
    -- in transit but represent real, completed sales transactions. Excluding
    -- only the two statuses where no sale actually occurred keeps the
    -- revenue figure accurate without discarding legitimate in-flight orders.
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    revenue_month,
    product_revenue,
    ROUND(SUM(product_revenue) OVER (ORDER BY revenue_month), 2) AS running_total_revenue
FROM monthly_revenue
ORDER BY revenue_month;

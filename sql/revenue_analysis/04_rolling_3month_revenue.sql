-- ============================================================
-- QUERY 4: ROLLING 3-MONTH REVENUE (MOVING AVERAGE)
-- ============================================================
-- Business Question: What does the smoothed revenue trend look like,
--   removing single-month noise/spikes?
-- Stakeholder: Executive team
-- SQL Concepts: Window function with explicit frame
--   (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
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
    ROUND(
        AVG(product_revenue) OVER (
            ORDER BY revenue_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3mo_avg_revenue
FROM monthly_revenue
ORDER BY revenue_month;

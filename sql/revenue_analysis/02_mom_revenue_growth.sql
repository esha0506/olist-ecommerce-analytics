-- ============================================================
-- QUERY 2: MONTH-OVER-MONTH (MoM) REVENUE GROWTH %
-- ============================================================
-- Business Question: Is revenue growth accelerating or decelerating?
-- Stakeholder: Executive team / CEO
-- SQL Concepts: CTE, LAG() window function, NULLIF (divide-by-zero safety)
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
),

-- LAG() is calculated once here and reused below, rather than repeating
-- the same window function three times in the final SELECT.
revenue_with_lag AS (
    SELECT
        revenue_month,
        product_revenue,
        LAG(product_revenue) OVER (ORDER BY revenue_month) AS prior_month_revenue
    FROM monthly_revenue
)

SELECT
    revenue_month,
    product_revenue,
    prior_month_revenue,
    ROUND(
        100.0 * (product_revenue - prior_month_revenue)
        / NULLIF(prior_month_revenue, 0),
        2
    ) AS mom_growth_pct
FROM revenue_with_lag
ORDER BY revenue_month;

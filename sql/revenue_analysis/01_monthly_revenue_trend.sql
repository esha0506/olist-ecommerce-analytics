-- ============================================================
-- QUERY 1: MONTHLY REVENUE TREND
-- ============================================================
-- Business Question: What is the monthly product revenue trend?
-- Stakeholder: Executive team / CEO
-- Revenue definition: Product Revenue = SUM(order_items.price)
--   (per docs/analytics_framework.md -- excludes freight, excludes
--    canceled/unavailable orders)
-- SQL Concepts: DATE_TRUNC, JOIN, GROUP BY, aggregate SUM
-- ============================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS revenue_month,
    ROUND(SUM(oi.price), 2)                                AS product_revenue,
    COUNT(DISTINCT o.order_id)                              AS order_count
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
ORDER BY revenue_month;

-- ============================================================
-- QUERY 14: DELIVERY DELAY ANALYSIS
-- ============================================================
-- Business Question: What share of orders are delivered early, on
--   time, or late, and how severe are the delays?
-- Stakeholder: Operations Manager / Customer Experience Lead
-- SQL Concepts: Date arithmetic, CASE WHEN bucketing, conditional
--   aggregation
--
-- NULL-handling note: only orders with both order_delivered_customer_date
-- and order_estimated_delivery_date populated are included (96,476 of
-- 99,441 orders, ~97%). Orders missing either date are typically
-- canceled or otherwise undelivered and cannot have a delay computed.
-- ============================================================

WITH delivery_delays AS (
    SELECT
        order_id,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        EXTRACT(DAY FROM (order_delivered_customer_date - order_estimated_delivery_date))::INT AS delay_days
    FROM orders
    WHERE order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),
delivery_buckets AS (
    SELECT
        order_id,
        delay_days,
        CASE
            WHEN delay_days < 0  THEN 'Early'
            WHEN delay_days = 0  THEN 'On Time'
            WHEN delay_days BETWEEN 1 AND 3 THEN 'Late (1-3 days)'
            WHEN delay_days BETWEEN 4 AND 7 THEN 'Late (4-7 days)'
            ELSE 'Late (8+ days)'
        END AS delivery_status
    FROM delivery_delays
)
SELECT
    delivery_status,
    COUNT(*)                                            AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS pct_of_orders,
    ROUND(AVG(delay_days), 2)                            AS avg_delay_days
FROM delivery_buckets
GROUP BY delivery_status
ORDER BY
    CASE delivery_status
        WHEN 'Early' THEN 1
        WHEN 'On Time' THEN 2
        WHEN 'Late (1-3 days)' THEN 3
        WHEN 'Late (4-7 days)' THEN 4
        WHEN 'Late (8+ days)' THEN 5
    END;

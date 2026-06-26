-- ============================================================
-- QUERY 15: REVIEW SCORE IMPACT (DELIVERY DELAY vs REVIEW SCORE)
-- ============================================================
-- Business Question: Does delivery delay measurably affect customer
--   satisfaction (review score)?
-- Stakeholder: Customer Experience Lead / Operations Manager --
--   quantifies whether delivery performance is worth investing in
--   beyond pure logistics cost.
-- SQL Concepts: CTE, date arithmetic, CASE WHEN bucketing,
--   conditional aggregation, JOIN with deduplication
--
-- Deduplication note: order_reviews can contain more than one row
-- per order_id (see docs/data_dictionary.md). Reviews are averaged
-- per order_id before being bucketed by delay, so duplicate review
-- rows do not double-count or skew any delay bucket's average score.
--
-- NULL-handling note: only orders with both delivery-related dates
-- populated are included, consistent with Query 14.
-- ============================================================

WITH order_review_avg AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_order_review_score
    FROM order_reviews
    GROUP BY order_id
),
delivery_delays AS (
    SELECT
        o.order_id,
        EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))::INT AS delay_days,
        ora.avg_order_review_score
    FROM orders o
    JOIN order_review_avg ora
        ON ora.order_id = o.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
delay_buckets AS (
    SELECT
        avg_order_review_score,
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
    COUNT(*)                                   AS order_count,
    ROUND(AVG(avg_order_review_score), 2)      AS avg_review_score
FROM delay_buckets
GROUP BY delivery_status
ORDER BY
    CASE delivery_status
        WHEN 'Early' THEN 1
        WHEN 'On Time' THEN 2
        WHEN 'Late (1-3 days)' THEN 3
        WHEN 'Late (4-7 days)' THEN 4
        WHEN 'Late (8+ days)' THEN 5
    END;

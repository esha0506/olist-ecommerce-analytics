-- ============================================================
-- QUERY 13: SELLER PERFORMANCE RANKING
-- ============================================================
-- Business Question: Which sellers perform best/worst on a composite
--   of delivery speed, customer satisfaction, and sales volume?
-- Stakeholder: Operations Manager -- identifies sellers to support,
--   investigate, or feature based on consistent performance rather
--   than a single metric in isolation.
-- SQL Concepts: Multi-CTE composite scoring, JOIN across orders +
--   order_items + order_reviews, RANK()
--
-- Sample-size note: 571 of 3,095 sellers (18%) have only 1 order.
-- A single seller with one lucky fast delivery would rank above
-- consistently strong high-volume sellers, which is not a fair or
-- actionable ranking for Operations. A minimum threshold of 20
-- orders is applied so the ranking reflects sustained performance.
--
-- Deduplication note: order_reviews can contain more than one row
-- per order_id (see docs/data_dictionary.md), so reviews are
-- averaged per order_id before being joined to sellers, preventing
-- duplicate review rows from skewing a seller's average score.
-- ============================================================

WITH order_review_avg AS (
    -- Collapse to one review score per order_id first, so orders with
    -- duplicate review rows don't get double-weighted below.
    SELECT
        order_id,
        AVG(review_score) AS avg_order_review_score
    FROM order_reviews
    GROUP BY order_id
),
seller_orders AS (
    SELECT
        oi.seller_id,
        oi.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        ora.avg_order_review_score
    FROM order_items oi
    JOIN orders o
        ON o.order_id = oi.order_id
    LEFT JOIN order_review_avg ora
        ON ora.order_id = oi.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
seller_metrics AS (
    SELECT
        seller_id,
        COUNT(DISTINCT order_id)                                       AS order_count,
        ROUND(AVG(avg_order_review_score), 2)                          AS avg_review_score,
        ROUND(AVG(
            EXTRACT(DAY FROM (order_delivered_customer_date - order_estimated_delivery_date))
        ) FILTER (
            WHERE order_delivered_customer_date IS NOT NULL
              AND order_estimated_delivery_date IS NOT NULL
        ), 2)                                                          AS avg_delivery_delay_days
    FROM seller_orders
    GROUP BY seller_id
    HAVING COUNT(DISTINCT order_id) >= 20
)
SELECT
    seller_id,
    order_count,
    avg_review_score,
    avg_delivery_delay_days,
    RANK() OVER (
        ORDER BY avg_review_score DESC, avg_delivery_delay_days ASC
    ) AS performance_rank
FROM seller_metrics
ORDER BY performance_rank
LIMIT 15;

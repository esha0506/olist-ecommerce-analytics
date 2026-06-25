-- ============================================================
-- QUERY 6: TOP PRODUCT CATEGORIES BY REVENUE
-- ============================================================
-- Business Question: Which product categories generate the most
--   revenue, and how do they rank against each other?
-- Stakeholder: Category / Merchandising Manager
-- SQL Concepts: RANK() vs DENSE_RANK() (shown together -- RANK()
--   skips numbers after a tie, DENSE_RANK() does not)
--
-- Grain note: category_revenue is correctly computed at the
-- order_item grain (one row per line item, summed by category).
-- This is intentional -- category is a line-item-level attribute,
-- not an order-level one, so no double-counting occurs here.
-- ============================================================

WITH category_revenue AS (
    SELECT
        COALESCE(ct.product_category_name_english, 'uncategorized') AS category_name,
        ROUND(SUM(oi.price), 2)                                      AS category_revenue
    FROM order_items oi
    JOIN orders o
        ON o.order_id = oi.order_id
    JOIN products p
        ON p.product_id = oi.product_id
    LEFT JOIN category_translation ct
        ON ct.product_category_name = p.product_category_name
    -- Excludes canceled/unavailable orders only -- 'delivered' alone
    -- would discard legitimate in-transit sales. Applied identically
    -- across every revenue query in this project.
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY category_name
)
SELECT
    category_name,
    category_revenue,
    RANK()       OVER (ORDER BY category_revenue DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY category_revenue DESC) AS revenue_dense_rank
FROM category_revenue
ORDER BY category_revenue DESC
LIMIT 15;

-- ============================================================
-- QUERY 5: REVENUE CONTRIBUTION % BY CATEGORY
-- ============================================================
-- Business Question: What % of total revenue does each product
--   category contribute?
-- Stakeholder: Category / Merchandising Manager
-- SQL Concepts: GROUP BY aggregate + window function SUM() OVER ()
--   with no PARTITION BY (whole-result-set denominator)
-- ============================================================

WITH category_revenue AS (
    SELECT
        COALESCE(ct.product_category_name_english, 'uncategorized') AS category,
        ROUND(SUM(oi.price), 2)                                      AS category_revenue
    FROM order_items oi
    JOIN orders o
        ON o.order_id = oi.order_id
    JOIN products p
        ON p.product_id = oi.product_id
    LEFT JOIN category_translation ct
        ON ct.product_category_name = p.product_category_name
    -- Excludes canceled/unavailable orders only (not restricted to 'delivered').
    -- 'Delivered' alone would understate revenue for orders that are still
    -- in transit but represent real, completed sales transactions. Excluding
    -- only the two statuses where no sale actually occurred keeps the
    -- revenue figure accurate without discarding legitimate in-flight orders.
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY COALESCE(ct.product_category_name_english, 'uncategorized')
)
SELECT
    category,
    category_revenue,
    ROUND(100.0 * category_revenue / SUM(category_revenue) OVER (), 2) AS revenue_contribution_pct
FROM category_revenue
ORDER BY category_revenue DESC
LIMIT 15;

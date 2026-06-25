-- ============================================================
-- QUERY 7: AVERAGE ORDER VALUE (AOV) BY CATEGORY
-- ============================================================
-- Business Question: Which categories run high-ticket, low-volume
--   transactions versus high-volume, low-ticket ones?
-- Stakeholder: Category / Merchandising Manager, Pricing strategy
-- SQL Concepts: Aggregate ratio (SUM / COUNT DISTINCT) computed in
--   a single grouped pass -- no second CTE needed since category-level
--   revenue, order_count, and AOV all derive from the same GROUP BY.
--
-- Grain note: order_count is COUNT(DISTINCT order_id) within each
-- category, which is correct for "how many orders touched this
-- category." Because ~727 orders contain items from more than one
-- category, those orders are counted once in each category they
-- touch -- order_count summed across all categories will therefore
-- exceed the platform's true total order count. This does not
-- affect AOV's correctness (revenue and order_count are counted
-- consistently within each category), but it means order_count
-- should not be summed across categories to reconstruct total orders.
-- ============================================================

WITH category_summary AS (
    SELECT
        COALESCE(ct.product_category_name_english, 'uncategorized') AS category_name,
        COUNT(DISTINCT oi.order_id)                                  AS order_count,
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
    order_count,
    category_revenue,
    ROUND(category_revenue / order_count, 2) AS avg_order_value
FROM category_summary
ORDER BY avg_order_value DESC
LIMIT 15;

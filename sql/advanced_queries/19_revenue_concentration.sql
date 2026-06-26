-- ============================================================
-- QUERY 19: REVENUE CONCENTRATION ANALYSIS
-- ============================================================
-- Business Question: How concentrated is total revenue across
--   product categories -- does a small number of categories
--   dominate, or is revenue broad-based? What share of revenue
--   comes from the top N categories?
-- Stakeholder: Category Manager / Executive team -- informs how
--   much business risk is tied to any single category's performance.
-- SQL Concepts: Window function for cumulative sum, RANK(),
--   cumulative contribution percentage
--
-- This extends Query 5's contribution-% view into a running,
-- cumulative Pareto-style view -- answering "what % of revenue do
-- the top N categories account for together," not just each
-- category's individual share.
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
    -- Excludes canceled/unavailable orders only, consistent with all
    -- revenue queries in this project.
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY category_name
),
ranked_categories AS (
    SELECT
        category_name,
        category_revenue,
        RANK() OVER (ORDER BY category_revenue DESC) AS revenue_rank
    FROM category_revenue
)
SELECT
    revenue_rank,
    category_name,
    category_revenue,
    ROUND(
        100.0 * SUM(category_revenue) OVER (ORDER BY revenue_rank) / SUM(category_revenue) OVER (),
        2
    ) AS cumulative_pct_of_revenue
FROM ranked_categories
ORDER BY revenue_rank
LIMIT 15;

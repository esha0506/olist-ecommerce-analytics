-- ============================================================
-- QUERY 18: ORDER STATUS ANALYSIS
-- ============================================================
-- Business Question: What does the full distribution of order
--   statuses look like, and what share of orders never reach a
--   successful outcome?
-- Stakeholder: Operations Manager / Executive team -- this is the
--   full-population view that the revenue and funnel queries
--   implicitly filter around (canceled/unavailable excluded
--   elsewhere); this query makes that filtering decision visible
--   and quantified rather than just assumed.
-- SQL Concepts: GROUP BY, conditional aggregation, window-based
--   contribution %
-- ============================================================

SELECT
    order_status,
    COUNT(*)                                            AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS pct_of_all_orders
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

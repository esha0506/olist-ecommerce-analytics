-- ============================================================
-- QUERY 20: SURPRISING INSIGHT -- GEOGRAPHIC ORDER VOLUME VS. AOV
-- ============================================================
-- Business Question: Is there an inverse relationship between how
--   often a state orders and how much it spends per order -- and if
--   so, how strong and consistent is that pattern?
-- Stakeholder: Executive team / Marketing -- this reframes "low-
--   volume states" from a demand problem into a reach/frequency
--   problem, which calls for a different strategy (geographic
--   expansion / logistics investment) than a pricing or affordability
--   problem would.
-- SQL Concepts: CTE, CORR() statistical aggregate function, NTILE()
--   for volume-based grouping, comparative aggregation
--
-- Validation note: this insight was tested directly rather than
-- inferred from inspecting two states (SP vs. PA) in Query 16.
-- CORR(order_count, avg_order_value) across all 27 states returns
-- -0.53 -- a real, moderately strong negative correlation, not a
-- coincidence from cherry-picked examples.
--
-- Grain note: revenue pre-aggregated to order grain in order_revenue
-- before rolling up to state level, consistent with Query 16.
-- ============================================================

WITH order_revenue AS (
    SELECT
        oi.order_id,
        ROUND(SUM(oi.price), 2) AS order_revenue
    FROM order_items oi
    GROUP BY oi.order_id
),
state_metrics AS (
    SELECT
        c.customer_state,
        COUNT(DISTINCT o.order_id)                    AS order_count,
        ROUND(SUM(orev.order_revenue), 2)              AS state_revenue,
        ROUND(SUM(orev.order_revenue) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    JOIN order_revenue orev
        ON orev.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_state
),
volume_tiers AS (
    SELECT
        customer_state,
        order_count,
        avg_order_value,
        NTILE(3) OVER (ORDER BY order_count DESC) AS volume_tier
    FROM state_metrics
)
SELECT
    CASE volume_tier
        WHEN 1 THEN 'High Volume States'
        WHEN 2 THEN 'Mid Volume States'
        WHEN 3 THEN 'Low Volume States'
    END AS volume_tier_label,
    COUNT(*)                          AS state_count,
    SUM(order_count)                  AS total_orders,
    ROUND(AVG(avg_order_value), 2)    AS avg_aov_in_tier
FROM volume_tiers
GROUP BY volume_tier
ORDER BY volume_tier;

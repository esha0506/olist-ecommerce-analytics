-- ============================================================
-- QUERY 16: GEOGRAPHIC REVENUE ANALYSIS
-- ============================================================
-- Business Question: How is revenue distributed across customer
--   states, and which states over/under-index relative to their
--   order volume?
-- Stakeholder: Executive team / Marketing -- informs regional
--   marketing investment and logistics planning.
-- SQL Concepts: CTE, JOIN, GROUP BY, window-based contribution %
--
-- Table choice note: customer_state/customer_city already exist
-- directly on the customers table, so this query does NOT join the
-- geolocation table. geolocation has no enforced primary key and
-- contains ~52 duplicate lat/long rows per zip prefix on average
-- (see docs/data_dictionary.md) -- joining it here would add fan-out
-- risk for zero analytical benefit, since state-level geography is
-- already available without it. geolocation would only be needed for
-- coordinate-level mapping (e.g., a Power BI map visual), not for
-- this revenue-by-state breakdown.
--
-- Grain note: revenue pre-aggregated to order grain in order_revenue
-- before joining to customers, consistent with Queries 8-11.
-- ============================================================

WITH order_revenue AS (
    SELECT
        oi.order_id,
        ROUND(SUM(oi.price), 2) AS order_revenue
    FROM order_items oi
    GROUP BY oi.order_id
),
state_revenue AS (
    SELECT
        c.customer_state,
        COUNT(DISTINCT o.order_id)        AS order_count,
        ROUND(SUM(orev.order_revenue), 2) AS state_revenue
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    JOIN order_revenue orev
        ON orev.order_id = o.order_id
    -- Excludes canceled/unavailable orders only, consistent with all
    -- revenue queries in this project.
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    order_count,
    state_revenue,
    ROUND(100.0 * state_revenue / SUM(state_revenue) OVER (), 2) AS pct_of_total_revenue,
    ROUND(state_revenue / order_count, 2)                          AS avg_order_value
FROM state_revenue
ORDER BY state_revenue DESC
LIMIT 15;

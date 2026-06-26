-- ============================================================
-- QUERY 10: COHORT RETENTION ANALYSIS
-- ============================================================
-- Business Question: Of customers who first purchased in a given
--   month, what share return to purchase again in later months?
-- Stakeholder: Marketing -- standard cohort retention view, the
--   basis for any retention-curve or lifecycle-marketing discussion.
-- SQL Concepts: CTEs, DATE_TRUNC, self-join (orders joined back to
--   each customer's own first-order cohort), conditional aggregation
--
-- Identity note: cohorts are built on customer_unique_id, not
-- customer_id, consistent with Queries 8-9.
--
-- Sample-size note: 2016 cohorts are excluded (Sept 2016 = 2
-- customers, Dec 2016 = 1 customer). Cohorts this small produce
-- 0%/100% retention cells that are statistical noise, not signal,
-- and would distort the retention heatmap. Analysis starts at the
-- first cohort month with a meaningful sample (Jan 2017, 752
-- customers).
-- ============================================================

WITH customer_first_order AS (
    SELECT
        c.customer_unique_id,
        MIN(DATE_TRUNC('month', o.order_purchase_timestamp))::DATE AS cohort_month
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
),
customer_order_months AS (
    -- Every distinct (customer, month) they purchased in -- this is
    -- the activity record we'll check against each cohort's start.
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS order_month
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
cohort_activity AS (
    SELECT
        cfo.cohort_month,
        com.order_month,
        -- months_since_cohort = 0 means the cohort's first purchase
        -- month itself; 1 means one month later, etc.
        (DATE_PART('year', com.order_month) - DATE_PART('year', cfo.cohort_month)) * 12
            + (DATE_PART('month', com.order_month) - DATE_PART('month', cfo.cohort_month)) AS months_since_cohort,
        com.customer_unique_id
    FROM customer_first_order cfo
    JOIN customer_order_months com
        ON com.customer_unique_id = cfo.customer_unique_id
    WHERE cfo.cohort_month >= '2017-01-01'
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM customer_first_order
    WHERE cohort_month >= '2017-01-01'
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    cs.cohort_size,
    ca.months_since_cohort,
    COUNT(DISTINCT ca.customer_unique_id)                              AS active_customers,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_unique_id) / cs.cohort_size, 2) AS retention_pct
FROM cohort_activity ca
JOIN cohort_sizes cs
    ON cs.cohort_month = ca.cohort_month
WHERE ca.months_since_cohort BETWEEN 0 AND 6
GROUP BY ca.cohort_month, cs.cohort_size, ca.months_since_cohort
ORDER BY ca.cohort_month, ca.months_since_cohort;

-- ============================================================
-- QUERY 12: ORDER FUNNEL CONVERSION ANALYSIS
-- ============================================================
-- Business Question: At each stage of the order lifecycle, what
--   share of orders successfully progress to the next stage, and
--   where does the funnel lose the most orders?
-- Stakeholder: Operations Manager / Executive team -- identifies
--   where operational friction (not marketing/demand) is costing
--   completed orders.
-- SQL Concepts: Conditional aggregation (CASE WHEN / COUNT FILTER),
--   ratio-to-baseline calculation
--
-- Funnel definition note (per docs/analytics_framework.md): this is
-- a TIMESTAMP-BASED OPERATIONAL FUNNEL, not a clickstream funnel.
-- The dataset has no page-view/cart/session events -- stage
-- progression is inferred purely from which lifecycle timestamps are
-- populated on each order. Stages:
--   1. Order Placed     -> order_purchase_timestamp IS NOT NULL (always true)
--   2. Payment Approved -> order_approved_at IS NOT NULL
--   3. Handed to Carrier -> order_delivered_carrier_date IS NOT NULL
--   4. Delivered          -> order_delivered_customer_date IS NOT NULL
-- ============================================================

WITH funnel_base AS (
    SELECT
        order_id,
        order_purchase_timestamp IS NOT NULL          AS reached_placed,
        order_approved_at IS NOT NULL                  AS reached_approved,
        order_delivered_carrier_date IS NOT NULL       AS reached_carrier,
        order_delivered_customer_date IS NOT NULL      AS reached_delivered
    FROM orders
),
funnel_counts AS (
    SELECT
        COUNT(*) FILTER (WHERE reached_placed)    AS stage_1_placed,
        COUNT(*) FILTER (WHERE reached_approved)  AS stage_2_approved,
        COUNT(*) FILTER (WHERE reached_carrier)   AS stage_3_carrier,
        COUNT(*) FILTER (WHERE reached_delivered) AS stage_4_delivered
    FROM funnel_base
)
SELECT
    'Stage 1: Order Placed'    AS funnel_stage, stage_1_placed    AS order_count,
    100.00                                                          AS pct_of_stage_1
FROM funnel_counts
UNION ALL
SELECT
    'Stage 2: Payment Approved', stage_2_approved,
    ROUND(100.0 * stage_2_approved / stage_1_placed, 2)
FROM funnel_counts
UNION ALL
SELECT
    'Stage 3: Handed to Carrier', stage_3_carrier,
    ROUND(100.0 * stage_3_carrier / stage_1_placed, 2)
FROM funnel_counts
UNION ALL
SELECT
    'Stage 4: Delivered', stage_4_delivered,
    ROUND(100.0 * stage_4_delivered / stage_1_placed, 2)
FROM funnel_counts;

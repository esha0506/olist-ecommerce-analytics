-- ============================================================
-- QUERY 17: PAYMENT METHOD ANALYSIS
-- ============================================================
-- Business Question: Which payment methods do customers use, and
--   does payment method correlate with order value or installment
--   behavior?
-- Stakeholder: Finance -- informs payment processing cost planning
--   and understanding of customer purchasing behavior (e.g.,
--   installment usage on higher-value orders).
-- SQL Concepts: CTE, conditional aggregation, aggregate ratios
--
-- Revenue-source note (per docs/analytics_framework.md):
-- payment_value is used here deliberately, since this query analyzes
-- PAYMENT behavior itself (method mix, installments), not product
-- revenue. This is the one query in the project where payment_value
-- is the correct metric to use -- everywhere else, order_items.price
-- is used as the revenue source.
--
-- Grain note: order_payments has one row per payment transaction,
-- and a single order can have multiple payment rows (e.g., a split
-- payment across voucher + credit card). This query intentionally
-- analyzes at the PAYMENT-transaction grain, not the order grain,
-- since the question is about payment method usage itself.
--
-- Data quality note: 1 of 99,441 orders (status = 'delivered') has
-- zero rows in order_payments. This does not affect this query
-- (which aggregates existing payment rows, not orders), but is noted
-- here in case it surfaces as an unexplained gap in order-to-payment
-- reconciliation elsewhere in the project.
-- ============================================================

SELECT
    payment_type,
    COUNT(*)                                                       AS payment_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)             AS pct_of_payments,
    ROUND(SUM(payment_value), 2)                                    AS total_payment_value,
    ROUND(AVG(payment_value), 2)                                    AS avg_payment_value,
    ROUND(AVG(payment_installments), 2)                             AS avg_installments
FROM order_payments
GROUP BY payment_type
ORDER BY payment_count DESC;

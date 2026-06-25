# Analytics Framework

This document defines the analytical frameworks underlying the SQL queries built
in this project. Each framework specifies the exact metric definitions, the
business logic behind them, and the SQL concepts required to implement them.
This is the planning layer that precedes query implementation in `sql/`.

---

## A. Revenue Analytics

**Revenue definitions:**

This project distinguishes two deliberate revenue metrics rather than treating
"revenue" as a single number:

- **Product Revenue** = `SUM(order_items.price)` — the value of goods sold,
  excluding shipping. This is the metric used for category, seller, and
  product-level performance analysis, since freight cost is an operational
  pass-through, not a measure of product demand.
- **Operational Revenue** = `SUM(order_items.price + order_items.freight_value)`
  — total customer-facing transaction value, including shipping. This is the
  metric used when analyzing total order value or reconciling against payment
  totals.

`order_payments.payment_value` is **not used as the primary revenue source**.
This is not because the data is unreliable — it is accurate at the transaction
level — but because a single order can have multiple payment rows (e.g., a
payment split across a voucher and a credit card), and summing `payment_value`
without first deduplicating to the order grain would double-count revenue.
`order_items` is used instead because its grain (one row per line item) maps
directly and unambiguously to product-level revenue.

**Filtering decision:** Revenue analysis excludes `canceled` and `unavailable`
orders, since these did not result in completed transactions. Each query in
Phase 6 states its exact `order_status` filter explicitly.

| Metric | Definition | SQL Concept Needed |
|---|---|---|
| Total Product Revenue | `SUM(price)` across valid order_items | Aggregate function |
| Total Operational Revenue | `SUM(price + freight_value)` across valid order_items | Aggregate function |
| Monthly Revenue Trend | Revenue grouped by `DATE_TRUNC('month', order_purchase_timestamp)` | Date functions, GROUP BY |
| MoM Growth % | `(current_month - prior_month) / prior_month` | Window function: `LAG()` |
| Running Total Revenue | Cumulative revenue over time | Window function: `SUM() OVER (ORDER BY ...)` |
| Rolling 3-Month Revenue | Trailing 3-month moving sum/average | Window function: `SUM()/AVG() OVER (... ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` |
| Revenue Contribution % | Segment revenue ÷ total revenue | Window function: `SUM() OVER ()` as denominator |
| Revenue by Category | order_items → products → category_translation | JOIN, GROUP BY |
| Revenue by Seller | order_items → sellers | JOIN, GROUP BY, ranking functions |
| Revenue by Geography | customers → pre-aggregated geolocation | JOIN, subquery aggregation |

---

## B. Funnel Analytics

This project models a **timestamp-based operational funnel**, not a clickstream
or web-event funnel. The Olist dataset contains no page-view, cart, or
session-level events — funnel progression is inferred entirely from the
presence or absence of order lifecycle timestamps in the `orders` table. This
distinction is stated explicitly to avoid implying a type of behavioral
tracking the dataset does not support.

**Funnel stages (defined by timestamp completeness):**

1. Order Placed → `order_purchase_timestamp IS NOT NULL` (entry point; always true)
2. Payment Approved → `order_approved_at IS NOT NULL`
3. Handed to Carrier → `order_delivered_carrier_date IS NOT NULL`
4. Delivered to Customer → `order_delivered_customer_date IS NOT NULL`

Orders that do not progress to the next stage are analyzed against
`order_status` to explain the cause of drop-off (e.g., `canceled`,
`unavailable`, `processing`).

| Metric | Definition | SQL Concept Needed |
|---|---|---|
| Order Funnel | Count of orders reaching each timestamp-defined stage | CASE WHEN, conditional aggregation |
| Conversion Rate | Stage N count ÷ Stage 1 count | Aggregate ratio |
| Drop-off Analysis | Orders not reaching the next stage, grouped by order_status | CASE WHEN, GROUP BY |
| Payment Completion Rate | % of orders with a non-null `order_approved_at` | Conditional aggregation |

---

## C. Customer Analytics

All customer-level analysis in this project uses `customer_unique_id`, not
`customer_id`. As established in the data dictionary, `customer_id` is
generated per order, not per person; using it for retention, frequency, or
lifetime-value analysis would make repeat purchases structurally
undetectable. Every query in this section joins and groups on
`customer_unique_id`.

| Metric | Definition | SQL Concept Needed |
|---|---|---|
| RFM Segmentation | Recency (days since last order), Frequency (order count), Monetary (total spend), scored per `customer_unique_id` | CTEs, `NTILE()`, CASE WHEN for segment labels |
| Repeat Customers | `customer_unique_id` values with `COUNT(DISTINCT order_id) > 1` | GROUP BY, HAVING |
| Cohort Retention | Customers grouped by first-purchase month, tracked for activity in subsequent months | CTEs, self-join or window functions, `DATE_TRUNC` |
| Customer Lifetime Value (CLV) | Total historical revenue per `customer_unique_id` | Aggregate per customer |
| Purchase Frequency | Average order count per customer | Aggregate |
| Average Order Value (AOV) | Total revenue ÷ total order count, overall and segmented | Aggregate ratio |

**Context for interpretation:** Validation in Phase 3 confirmed approximately
3,300 of 96,096 unique customers placed more than one order. Retention and
repeat-purchase metrics in this dataset are expected to be low; this is
treated as a finding in itself (consistent with an acquisition-heavy,
retention-weak business pattern) rather than as an analytical shortfall.

---

## D. Product Analytics

| Metric | Definition | SQL Concept Needed |
|---|---|---|
| Top Categories | Categories ranked by total product revenue | ORDER BY, `RANK()` / `DENSE_RANK()` |
| Underperforming Categories | Categories with high order volume but low revenue relative to peers | CTE/subquery comparison |
| Revenue Concentration | Cumulative % of total revenue contributed by top N categories | Window function: cumulative sum, `NTILE()` |
| High-Ticket Categories | Categories with high AOV but low order volume | Aggregate comparison: AOV vs. order count |

---

## E. Operational Analytics

| Metric | Definition | SQL Concept Needed |
|---|---|---|
| Delivery Performance | % of orders delivered before, on, or after `order_estimated_delivery_date` | CASE WHEN, conditional aggregation |
| Shipping Delays | `order_delivered_customer_date - order_estimated_delivery_date`, calculated only where both fields are non-null | Date arithmetic, NULL filtering |
| Review Score Impact | Relationship between delivery delay (days) and `review_score` | JOIN orders + order_reviews, GROUP BY delay buckets, `AVG(review_score)` |
| Seller Efficiency | Composite score combining average delivery delay, average review score, and order volume per seller | Multi-CTE composite scoring |

---

## Mapping to Phase 6 Required Queries

| # | Required Query | Framework Section |
|---|---|---|
| 1–5 | Monthly revenue, MoM growth, running total, rolling 3-month, contribution % | A |
| 6–7 | Top categories, AOV by category | A / D |
| 8–11 | RFM, retention, cohort, repeat purchase | C |
| 12 | Funnel conversion | B |
| 13 | Seller performance ranking | E |
| 14–15 | Delivery delay, review score impact | E |
| 16 | Geographic revenue | A |
| 17 | Payment method analysis | A (supplementary — not the revenue source) |
| 18 | Order status analysis | B |
| 19 | Revenue concentration | D |
| 20 | Surprising insight | Cross-cutting — expected to emerge from D or E |

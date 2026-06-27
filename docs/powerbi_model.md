# Power BI Data Model — Star Schema

This is the dimensional model recreated in Power BI's Model view, derived
from the normalized PostgreSQL schema (`sql/schema/01_create_tables.sql`)
but reshaped for BI consumption: one central fact table at line-item grain,
surrounded by clean dimension tables, with two secondary fact tables joined
through the orders dimension.

## Fact Tables

**`fact_order_items`** (grain: one row per order line item — 112,650 rows)
The central fact table. Contains `price` and `freight_value`, the basis for
every revenue measure in `docs/dax_measures.md`.

**`fact_reviews`** (grain: one row per order — 99,441 rows)
Pre-deduplicated at extraction time (see `extract_dim_customers_rfm.sql`'s
sibling logic in `sql/operational_analysis/13_seller_performance_ranking.sql`)
so Power BI never has to handle the duplicate-review-row issue documented in
`docs/data_dictionary.md`.

**`fact_payments`** (grain: one row per payment transaction — 103,886 rows)
Kept at transaction grain deliberately — this is the one table where
`payment_value` is the correct metric (per the documented exception in
`sql/revenue_analysis/17_payment_method_analysis.sql`), since the analysis
question is about payment behavior itself, not product revenue.

## Dimension Tables

**`dim_orders`** — order grain, lifecycle timestamps and status
**`dim_customers`** — customer grain (per-order `customer_id`, with
`customer_unique_id` as the true person identifier for any customer-level
analysis — see the grain note in `docs/data_dictionary.md`)
**`dim_customers_rfm`** — one row per `customer_unique_id`, pre-calculated
RFM scores and segment labels (logic identical to
`sql/customer_analysis/08_rfm_segmentation.sql`, including the NTILE-skew
fix for frequency scoring)
**`dim_products`** — product grain, with English category name pre-joined
**`dim_sellers`** — seller grain, all sellers
**`dim_sellers_performance`** — seller grain, filtered to sellers with 20+
orders (per the sample-size rationale in Query 13), with pre-calculated
composite performance metrics
**`dim_date`** — standard calendar table (2016-09-01 to 2018-10-31), required
for Power BI time-intelligence functions, with an `is_truncated_month` flag
identifying the September 2018 dataset-export cutoff

## Relationships

See the ERD in this project's Phase 8 conversation, or recreate in Power BI
Model view per the table in `docs/powerbi_build_guide.md` Step 2. In summary:

- `fact_order_items` connects to `dim_orders`, `dim_products`, `dim_sellers`
- `dim_orders` connects to `dim_customers` (via `customer_id`) and `dim_date`
  (via `order_purchase_date`)
- `fact_reviews` and `fact_payments` connect to `dim_orders` via `order_id`
- `dim_sellers_performance` connects to `dim_sellers` via `seller_id`
- `dim_customers_rfm` connects to `dim_customers` via `customer_unique_id`

## Why a Star Schema (and not just flat tables)

A star schema lets Power BI's filter context propagate correctly across
related visuals — filtering by category on one chart should also filter the
revenue card. A single denormalized flat table would work for one chart in
isolation but breaks cross-filtering between visuals built on different
grains (e.g., a seller-level chart and an order-item-level chart need to
filter each other through the shared `dim_orders`/`dim_sellers` relationship,
not be entirely flattened into one row-bloated table).

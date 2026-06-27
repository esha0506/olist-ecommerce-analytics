# Power BI Dashboard Build Guide

This guide walks through building the actual `.pbix` file in Power BI Desktop,
using the data extracts in `powerbi/data_extracts/`. Power BI Desktop is
Windows-only, so this build happens on your laptop — this document is the
step-by-step reference for that build.

---

## Step 1 — Import the Data Extracts

1. Open Power BI Desktop → **Get Data → Text/CSV**
2. Import all 10 files from `powerbi/data_extracts/`:
   - `fact_order_items.csv`
   - `dim_orders.csv`
   - `dim_customers.csv`
   - `dim_customers_rfm.csv`
   - `dim_products.csv`
   - `dim_sellers.csv`
   - `dim_sellers_performance.csv`
   - `dim_date.csv`
   - `fact_reviews.csv`
   - `fact_payments.csv`
3. Click **Transform Data** before loading, and confirm each date column
   (`order_purchase_date`, `order_delivered_customer_date`,
   `order_estimated_delivery_date`, `date`) is typed as **Date**, not Text —
   Power BI sometimes mis-infers this on CSV import.
4. Click **Close & Apply**.

## Step 2 — Build Relationships (Model View)

Go to **Model view** and create these relationships (drag from one field to
the other; Power BI infers direction from cardinality):

| From | To | Cardinality |
|---|---|---|
| `fact_order_items[order_id]` | `dim_orders[order_id]` | Many-to-one |
| `fact_order_items[product_id]` | `dim_products[product_id]` | Many-to-one |
| `fact_order_items[seller_id]` | `dim_sellers[seller_id]` | Many-to-one |
| `dim_orders[customer_id]` | `dim_customers[customer_id]` | Many-to-one |
| `dim_orders[order_purchase_date]` | `dim_date[date]` | Many-to-one |
| `fact_reviews[order_id]` | `dim_orders[order_id]` | One-to-one |
| `fact_payments[order_id]` | `dim_orders[order_id]` | Many-to-one |
| `dim_sellers_performance[seller_id]` | `dim_sellers[seller_id]` | One-to-one |
| `dim_customers_rfm[customer_unique_id]` | `dim_customers[customer_unique_id]` | One-to-many |

This produces the star schema in `docs/powerbi_model.md` (Phase 8 ERD).

## Step 3 — Mark the Date Table

Right-click `dim_date` → **Mark as date table** → select the `date` column.
This is required for the `DATEADD`/`DATESINPERIOD` functions used in the
MoM Growth % and Retention Rate % measures to work correctly.

## Step 4 — Add the DAX Measures

Follow `docs/dax_measures.md` exactly — create each measure on
`fact_order_items` (Model view → select table → New Measure), paste the
formula, and rename per the heading.

## Step 5 — Hide Technical Columns

In Model view, right-click and **Hide in report view** for any ID columns not
needed directly in visuals (`order_item_id`, `payment_sequential`,
`product_weight_g`, etc.) — keeps the field list clean for report building.

---

## Dashboard Pages

### Page A — Executive Overview

**Stakeholder:** CEO / Executive team
**Use case:** A 10-second health check before a leadership meeting — no
drill-down needed, just "is the business healthy right now."

| Visual | Measure(s) | Why it's here |
|---|---|---|
| Card | Total Revenue | The single most-requested number in any executive review |
| Card | Total Customers | Scale of the customer base |
| Card | AOV | Pricing/spend-per-transaction context |
| Card | Repeat Customer Rate % | Surfaces the retention finding immediately, even on the summary page |
| Line chart | Running Total Revenue by `dim_date[month_start]` | Shows growth trajectory at a glance |
| KPI visual | Revenue MoM Growth % | Flags acceleration/deceleration without needing the full trend chart |

**Layout:** 4 cards across the top row, line chart left-half below, KPI visual
right-half below. **Filter:** apply `dim_date[is_truncated_month] = FALSE` at
the page level so Sept 2018's truncation artifact never appears here.

---

### Page B — Revenue Dashboard

**Stakeholder:** Category Manager / Finance
**Use case:** Deeper investigation into where revenue comes from and how it's
trending, for planning and category strategy discussions.

| Visual | Fields | Why it's here |
|---|---|---|
| Line chart | Total Revenue by month, with Rolling 3-Month overlay | Mirrors Query 4 — shows trend without month-to-month noise |
| Bar chart (horizontal) | Total Revenue by `dim_products[category_name_english]`, top 15 | Mirrors Query 6 |
| Map (or filled map) | Total Revenue by `dim_customers[customer_state]` | Mirrors Query 16/20 — visualizes the geography findings |
| Table | Category, Order Count, Total Revenue, AOV | Mirrors Query 7 — lets a Category Manager sort by AOV vs. volume directly |
| Donut/bar | Total Payment Value by `payment_type` | Mirrors Query 17 |

**Layout:** Line chart full-width top, map + category bar chart side by side
middle, AOV table and payment chart along the bottom.

---

### Page C — Customer Dashboard

**Stakeholder:** Marketing
**Use case:** Identify which customer segments to target for retention vs.
win-back vs. no further spend.

| Visual | Fields | Why it's here |
|---|---|---|
| Matrix/heatmap-style table | `dim_customers_rfm[frequency_score]` (rows) x `monetary_score` (columns), count of `customer_unique_id` | Power BI equivalent of Chart 3's RFM heatmap |
| Pie/bar chart | Count of customers by `rfm_segment` | Shows segment sizes (Champions, Lost/Churned, etc.) at a glance |
| Card | Repeat Customer Rate % | Restates the headline retention number on the page it matters most |
| Card | Total Customers, Repeat Customers | Context for the rate above |

**Note:** the full cohort retention heatmap (Chart 4 from `visualization_analysis.ipynb`)
is intentionally NOT rebuilt in DAX — recreating a 18-cohort x 7-month matrix
in Power BI natively is fragile and error-prone. Instead, embed
`notebooks/_cache/chart4_cohort_retention.png` as a static image on this page,
captioned "see notebooks/visualization_analysis.ipynb for full cohort detail."
This is a deliberate, defensible tool choice: Python for complex one-off
statistical visuals, Power BI for interactive, filterable business metrics.

---

### Page D — Operational Dashboard

**Stakeholder:** Operations Manager / Customer Experience Lead
**Use case:** Identify delivery and seller performance issues needing
intervention.

| Visual | Fields | Why it's here |
|---|---|---|
| Card | Avg Delivery Delay (Days), On-Time Delivery Rate % | Headline operational health |
| Bar chart | Avg Review Score by delivery-delay bucket | Mirrors Chart 8/Query 15 — the strongest relationship in the project |
| Scatter chart | `dim_sellers_performance[avg_delivery_delay_days]` (x) vs. `avg_review_score` (y), size = `order_count` | Mirrors Chart 6/Query 13 |
| Table | Seller ID, Order Count, Avg Review Score, Avg Delivery Delay, sorted ascending by review score | Lets Operations directly identify underperforming sellers to investigate |

**Filter note:** the seller table/scatter should default to `dim_sellers_performance`
(already thresholded to 20+ orders, per Query 13's documented sample-size
rationale) — do not join the unfiltered `dim_sellers` table into these visuals.

---

### Page E — Funnel Dashboard

**Stakeholder:** Operations Manager / Executive team
**Use case:** Quickly see where in the order lifecycle orders are lost.

| Visual | Fields | Why it's here |
|---|---|---|
| Funnel visual (Power BI built-in) | Stage order counts (Placed → Approved → Carrier → Delivered) | Direct visual analog of Chart 5/Query 12 |
| Stacked bar | Order count by `order_status` | Mirrors Query 18 — shows the full status breakdown behind the funnel |
| Card | Stage 4 conversion % (Delivered / Placed) | The headline funnel completion rate |

**Note on data prep:** the funnel visual needs four explicit rows (one per
stage) rather than the raw `dim_orders` table directly. Build a small
calculated table in Power BI (**Modeling → New Table**) using:

```dax
Funnel Stages =
DATATABLE(
    "Stage", STRING, "Order Count", INTEGER,
    {
        {"1. Order Placed", 99441},
        {"2. Payment Approved", 99281},
        {"3. Handed to Carrier", 97658},
        {"4. Delivered", 96476}
    }
)
```
(These counts are taken directly from Query 12's validated output — re-verify
against `sql/funnel_analysis/12_funnel_conversion.sql` if the underlying data
changes.)

---

## UX & Design Recommendations

1. **Consistent color coding across all 5 pages:** use one accent color for
   "good" metrics (e.g., green for on-time/early delivery, repeat customers)
   and one for "needs attention" (e.g., red/orange for late delivery,
   churned customers). Don't let each page invent its own palette.
2. **Page-level filters over slicers where possible** — a Category Manager
   on Page B doesn't need a customer-state slicer cluttering the page if
   the map already shows that breakdown.
3. **Apply the `is_truncated_month` filter globally**, not per-visual — set
   it once at the report level (Filters pane → This Report) so no chart
   ever risks showing the September 2018 artifact.
4. **Use tooltips, not extra visuals**, for secondary detail — e.g., a bar
   chart of revenue by category can show order count and AOV in the tooltip
   rather than needing 3 separate visuals for the same dimension.
5. **Title every page with the audience in mind** — "Revenue" not "Page 2,"
   so a stakeholder opening the file cold knows immediately where to look.

# Power BI Data Modeling — Concepts

This document explains the modeling theory behind the star schema and DAX
measures built in Phase 8 (`docs/powerbi_model.md`, `docs/dax_measures.md`).
Where those documents are reference material ("what to build"), this one is
the reasoning ("why it's built that way") — the part worth being able to
explain fluently in an interview.

---

## 1. Star Schema Concepts

A star schema organizes data into two kinds of tables:

- **Fact tables** — the events/transactions being measured. Long, narrow,
  numeric-heavy, and they grow constantly (every new order adds rows).
- **Dimension tables** — the context that describes those events: who,
  what, where, when. Shorter, wider, descriptive, and relatively stable.

The name "star" comes from the shape: one fact table in the center, with
dimension tables radiating outward, each connected by a single relationship.
This is different from the normalized schema PostgreSQL uses
(`sql/schema/01_create_tables.sql`), where tables reference each other in
chains (`order_items → orders → customers`) to minimize data duplication.

**Why not just use the normalized schema directly in Power BI?** Two reasons:

1. **Query performance.** Power BI's engine (VertiPaq) is optimized for star
   schemas — it expects to filter a small dimension table and propagate that
   filter to a large fact table efficiently. Long join chains across many
   normalized tables force the engine to do more relationship-traversal work
   per visual.
2. **Filter propagation correctness.** In a star schema, filtering
   `dim_products[category_name_english]` to "computers" automatically filters
   every visual built on `fact_order_items`, because there's one direct
   relationship. If the model were a long normalized chain instead, an
   analyst could accidentally build a visual that doesn't correctly inherit
   a filter several joins away — a subtle bug that's hard to spot visually.

This is why Phase 8 built dedicated CSV extracts (`dim_customers_rfm.csv`,
`dim_sellers_performance.csv`) rather than just importing the raw normalized
tables — the SQL logic (RFM scoring, seller dedup) was resolved once in
PostgreSQL, and Power BI receives a clean, pre-shaped dimension table.

## 2. Fact vs. Dimension Tables — How to Tell Them Apart

Ask two questions about a table:

1. **Does it represent an event/transaction, or a descriptive entity?**
   An order line item is an event (something that happened). A customer is
   an entity (something that exists, independent of any single order).
2. **What's the row count growth pattern?**
   Fact tables grow with business activity (more orders → more rows in
   `fact_order_items`). Dimension tables grow much more slowly (a new
   product category is rare; a new order is constant).

Applying this to the Olist model:

| Table | Fact or Dimension? | Why |
|---|---|---|
| `fact_order_items` | Fact | One row per transaction event (a product being sold) |
| `fact_reviews` | Fact | One row per review event |
| `fact_payments` | Fact | One row per payment transaction event |
| `dim_customers` | Dimension | Describes who placed an order — stable entity |
| `dim_products` | Dimension | Describes what was sold — stable entity |
| `dim_date` | Dimension | Describes when — a calendar doesn't "happen," it's a lookup |

**A common trap:** `dim_orders` looks event-like (an order is something that
happened), but it functions as a dimension here because `fact_order_items`
is the true grain of measurement — `dim_orders` exists to describe each
line item's order-level context (status, timestamps), the same way
`dim_customers` describes its customer-level context. Whether a table is a
"fact" or "dimension" depends on its role in a specific model, not some
fixed property of the table.

## 3. Measures vs. Calculated Columns

This is one of the most commonly confused DAX concepts, and a frequent
interview question.

**Calculated columns** are computed once, row-by-row, when the data is
loaded or refreshed, and the result is stored physically in the table —
just like a normal column. They respond to row context but NOT to the
filters a user applies in a visual.

**Measures** are computed on the fly, at query time, in response to
whatever filters are currently active (slicers, visual-level filters, the
rows/columns of a matrix). They are never stored — only calculated when a
visual asks for them.

**The practical rule:** if the answer should change depending on what the
user has filtered or sliced, it must be a measure. If the answer is a fixed
property of each row regardless of context, it can be a calculated column.

Applied to this project: every formula in `docs/dax_measures.md` (Total
Revenue, AOV, MoM Growth %, etc.) is a measure, not a calculated column —
because "Total Revenue" must recompute differently depending on whether the
user has filtered to one category, one month, or the whole dataset. A
calculated column would freeze that number at load time and ignore later
filtering, which would silently produce wrong-looking dashboards (the
number would stop responding to slicers).

The one place a calculated column would make sense in this model is
`dim_date[is_truncated_month]` — it's a fixed, row-level property (is this
date in September 2018 or not) that never needs to respond to filter
context. That column is computed once in the SQL extraction
(`extract_dim_date.sql`) rather than in DAX, which is also a valid and
often preferable choice — push static, row-level logic upstream into SQL
when possible, and reserve DAX for things that genuinely need to be dynamic.

## 4. DAX Fundamentals for Analysts

A few core concepts that explain why the measures in `docs/dax_measures.md`
are written the way they are:

### Row context vs. filter context
- **Row context** exists when DAX evaluates an expression one row at a
  time (e.g., inside `SUMX`, which walks `fact_order_items` row by row to
  compute `price + freight_value` for each line item before summing).
- **Filter context** is the set of filters currently applied — from
  slicers, visual axes, or `CALCULATE`/`FILTER` inside the formula itself.
  Most DAX measures live and die by filter context: `[Total Revenue]`
  produces a different number depending on what's filtered, because
  `SUM(fact_order_items[price])` only sums the rows visible under the
  current filter context.

### CALCULATE is the core function to understand
`CALCULATE` modifies filter context — it's how "Total Revenue" can apply
its own status filter (`NOT IN {"canceled","unavailable"}`) on top of
whatever filters a visual already has active. Every revenue measure in this
project wraps its base aggregation in `CALCULATE` for exactly this reason —
without it, there would be no way to bake the project's standard exclusion
rule into the measure itself.

### Why DATEADD/DATESINPERIOD need a marked date table
Power BI's time-intelligence functions assume a contiguous, one-row-per-day
calendar table with no gaps — this is why `dim_date` was built as a full
date spine (`GENERATE_SERIES` in `extract_dim_date.sql`) rather than just
the distinct dates that happen to appear in `orders`. Marking it as the
official date table tells Power BI's engine which table defines "time" for
functions like `DATEADD(dim_date[date], -1, MONTH)` to walk correctly.

### ALL / ALLSELECTED — removing filters deliberately
`Revenue Contribution %` needs its denominator to ignore the category
filter that's shaping its numerator — that's what `ALL(dim_products[category_name_english])`
does inside the `CALCULATE` for the denominator. Without it, filtering a
visual to one category would make that category's contribution % always
show 100%, since the "total" would already be filtered down to match.

---

## Summary: Why This Model Is Built This Way

Every modeling decision in this project traces back to one of two goals:
**correctness** (numbers that don't silently break when someone applies a
filter) and **interview-defensibility** (being able to explain *why* a
choice was made, not just that it works). The star schema, the
measure/column split, and the explicit `CALCULATE`/`ALL` usage throughout
`docs/dax_measures.md` are all in service of those two goals.

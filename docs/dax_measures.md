# Power BI DAX Measures

These measures assume the star schema in `docs/powerbi_model.md`:
`fact_order_items` is the central fact table, related to `dim_orders`,
`dim_products`, `dim_sellers`, `dim_customers` (via `dim_orders`), and
`dim_date` (via `dim_orders[order_purchase_date]`).

Create these in Power BI Desktop: **Model view → select `fact_order_items` →
New Measure**, paste each formula, and rename per the heading below.

---

## Revenue Measures

### Total Revenue
Excludes canceled/unavailable orders, consistent with every SQL revenue query
in this project (see `docs/analytics_framework.md`).

```dax
Total Revenue =
CALCULATE(
    SUM(fact_order_items[price]),
    NOT( dim_orders[order_status] IN { "canceled", "unavailable" } )
)
```

### Total Revenue (incl. Freight) — "Operational Revenue"
```dax
Total Operational Revenue =
CALCULATE(
    SUMX(fact_order_items, fact_order_items[price] + fact_order_items[freight_value]),
    NOT( dim_orders[order_status] IN { "canceled", "unavailable" } )
)
```

### MoM Growth %
Requires `dim_date` marked as the official Date table (Model view → right-click
`dim_date` → Mark as date table) for `DATEADD` to work correctly.

```dax
Revenue MoM Growth % =
VAR CurrentRevenue = [Total Revenue]
VAR PriorMonthRevenue =
    CALCULATE(
        [Total Revenue],
        DATEADD(dim_date[date], -1, MONTH)
    )
RETURN
    DIVIDE(CurrentRevenue - PriorMonthRevenue, PriorMonthRevenue)
```

### Running Total Revenue
```dax
Running Total Revenue =
CALCULATE(
    [Total Revenue],
    FILTER(
        ALLSELECTED(dim_date[date]),
        dim_date[date] <= MAX(dim_date[date])
    )
)
```

### Revenue Contribution %
Use on a category/seller/state visual — divides each row's revenue by the
grand total, ignoring the current visual's filter for the denominator.

```dax
Revenue Contribution % =
DIVIDE(
    [Total Revenue],
    CALCULATE([Total Revenue], ALL(dim_products[category_name_english]))
)
```
(Swap `dim_products[category_name_english]` for `dim_sellers[seller_id]` or
`dim_customers[customer_state]` depending on which dashboard page/visual
this is used on.)

### Average Order Value (AOV)
```dax
AOV =
DIVIDE(
    [Total Revenue],
    DISTINCTCOUNT(fact_order_items[order_id])
)
```

---

## Customer Measures

### Total Customers
```dax
Total Customers =
DISTINCTCOUNT(dim_customers[customer_unique_id])
```
**Note:** this must reference `customer_unique_id`, never `customer_id` —
see the grain note in `docs/data_dictionary.md`. Using `customer_id` here
would inflate the count and make repeat-customer % impossible to compute.

### Repeat Customers
```dax
Repeat Customers =
CALCULATE(
    DISTINCTCOUNT(dim_customers[customer_unique_id]),
    FILTER(
        VALUES(dim_customers[customer_unique_id]),
        CALCULATE(DISTINCTCOUNT(fact_order_items[order_id])) > 1
    )
)
```

### Repeat Customer Rate %
```dax
Repeat Customer Rate % =
DIVIDE([Repeat Customers], [Total Customers])
```

### Customer Retention Rate % (cohort month 1)
This is intentionally simplified for a single dashboard card — the full
cohort matrix (Query 10 / Chart 4) belongs in the notebook and README, not
recreated as nested DAX. This measure answers "of customers active last
month, what % are active this month" as a rolling retention proxy.

```dax
Retention Rate % (M/M) =
VAR CustomersThisMonth =
    CALCULATETABLE(
        VALUES(dim_customers[customer_unique_id]),
        DATESINPERIOD(dim_date[date], MAX(dim_date[date]), -1, MONTH)
    )
VAR CustomersLastMonth =
    CALCULATETABLE(
        VALUES(dim_customers[customer_unique_id]),
        DATESINPERIOD(dim_date[date], EDATE(MAX(dim_date[date]), -1), -1, MONTH)
    )
VAR RetainedCustomers = INTERSECT(CustomersThisMonth, CustomersLastMonth)
RETURN
    DIVIDE(COUNTROWS(RetainedCustomers), COUNTROWS(CustomersLastMonth))
```

---

## Operational Measures

### Average Delivery Delay (days)
Positive = late, negative = early — consistent with Query 14's sign convention.

```dax
Avg Delivery Delay (Days) =
AVERAGEX(
    FILTER(
        dim_orders,
        NOT ISBLANK(dim_orders[order_delivered_customer_date])
            && NOT ISBLANK(dim_orders[order_estimated_delivery_date])
    ),
    DATEDIFF(
        dim_orders[order_estimated_delivery_date],
        dim_orders[order_delivered_customer_date],
        DAY
    )
)
```

### On-Time Delivery Rate %
```dax
On-Time Delivery Rate % =
VAR DeliveredWithDates =
    FILTER(
        dim_orders,
        NOT ISBLANK(dim_orders[order_delivered_customer_date])
            && NOT ISBLANK(dim_orders[order_estimated_delivery_date])
    )
VAR OnTimeOrEarly =
    FILTER(
        DeliveredWithDates,
        dim_orders[order_delivered_customer_date] <= dim_orders[order_estimated_delivery_date]
    )
RETURN
    DIVIDE(COUNTROWS(OnTimeOrEarly), COUNTROWS(DeliveredWithDates))
```

### Average Review Score
References `fact_reviews`, which is already deduplicated to one row per
`order_id` (see `extract_fact_reviews` logic) — no further dedup needed here.

```dax
Avg Review Score =
AVERAGE(fact_reviews[avg_review_score])
```

---

## Usage Notes

- Every revenue measure filters out `canceled`/`unavailable` order statuses,
  consistent with the project-wide filtering decision documented in
  `docs/analytics_framework.md` and explained inline in every SQL query.
- `dim_date` must be marked as the official Date table for `DATEADD`,
  `DATESINPERIOD`, and `EDATE` to behave correctly.
- The `is_truncated_month` column in `dim_date` should be used as a visual-level
  filter (set to FALSE) on any time-series chart to exclude the September 2018
  dataset-truncation artifact, consistent with how `eda.ipynb` handles it.

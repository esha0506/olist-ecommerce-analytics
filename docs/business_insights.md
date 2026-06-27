# Business Insights & Strategic Recommendations

This document synthesizes the findings from `sql/` (Phase 6) and
`notebooks/` (Phase 7) into an executive-facing narrative. Every figure
cited here traces back to a specific, validated query — referenced inline
so any claim can be checked against its source.

---

## Executive Summary

Olist generated **R$13.49M in product revenue** across the dataset's
~2-year window, from **96,096 unique customers**. The business shows healthy
operational fundamentals — a tight order funnel (97% delivery completion)
and a platform-wide pattern of early, not late, deliveries — but carries one
structural risk that should reframe how growth is pursued: **retention is
nearly nonexistent**. Only 3.04% of customers ever place a second order, and
of those who do, almost none do so within the same or following month. This
is not a single bad metric among many — it is the central fact that should
shape Olist's next strategic decisions, because it means the entire revenue
base documented here was generated primarily through new-customer
acquisition, not loyalty.

At the same time, the data reveals a clear, underexploited opportunity:
customers in lower-order-volume states spend *more* per order, not less,
suggesting the constraint in underserved regions is reach and logistics, not
price sensitivity or demand. This, combined with a strong, quantified link
between delivery delay and customer satisfaction, points to where investment
would matter most: reducing the long tail of severe delivery delays, and
expanding deliberate presence in high-AOV, low-volume states — rather than
broad discounting or undifferentiated marketing spend.

---

## Key Findings

### 1. Revenue is broad-based, not concentrated (low risk)
- The top category (`health_beauty`) holds only 9.3% of total revenue
  (Query 5/6); it takes **9 categories to cross 50%** of revenue and 15 to
  reach 76.32% (Query 19) — a genuinely non-Pareto distribution.
- **Why it matters:** no single category's decline would meaningfully
  threaten total revenue. This is a structural strength, not something that
  needs fixing.

### 2. Retention is the platform's central weakness
- Only **3.04% of customers (2,887 of 94,983) are repeat buyers** (Query 9).
- Cohort retention falls under 1% by month 1 for every single cohort
  measured, with no gradual decay curve (Query 10) — confirmed directly
  against the Jan 2017 cohort, where only 55 of 752 customers (7.3%) ever
  placed a second order across the *entire* dataset.
- Repeat customers generate disproportionate value per head (R$259.95 avg.
  revenue vs. R$138.38 for one-time buyers) but are too small a group to be
  the primary growth engine (Query 9).
- **Why it matters:** this is the single most "surprising, data-backed"
  finding in the project. Olist's growth pattern looks more like a
  one-and-done marketplace than a habitual-purchase platform, which has
  direct implications for whether marketing budget should chase repeat
  purchase (likely low ROI given how few customers ever return) or focus on
  acquisition and one-time order value instead.

### 3. Customer value is concentrated by spend, not by loyalty
- The top 20% of customers by lifetime value generate **56.67%** of total
  revenue (Query 11) — but this concentration is driven by big **one-time**
  purchases, not by repeat buying (cross-referenced against Finding #2).
- **Why it matters:** the actionable lever isn't "retain existing big
  spenders" (there's little repeat behavior to retain) — it's "identify
  high-spend one-time buyers and test second-purchase incentives," since
  they've already demonstrated willingness to spend.

### 4. Delivery delay is the strongest driver of dissatisfaction in the dataset
- Average review score declines **strictly monotonically** as delay
  increases: 4.29 (Early) → 4.08 (On Time) → 3.28 (1-3 days late) → 2.09
  (4-7 days late) → **1.69 (8+ days late)** (Query 15).
- "Late (8+ days)" is both the largest late-bucket (2.97% of orders) and the
  most severe (avg. 19.58 days late) (Query 14).
- **Why it matters:** this is a clean, quantified business case — the
  long-tail of severe delays, not average delay, is what most threatens
  satisfaction, and is a more targeted investment than a blanket logistics
  overhaul.

### 5. The platform delivers early almost everywhere — likely a sign of overly conservative delivery estimates
- **90.37% of orders arrive early**, averaging 12.9 days ahead of the
  estimated delivery date (Query 14); top-ranked sellers average as much as
  23 days early (Query 13).
- **Why it matters:** this suggests `order_estimated_delivery_date` is set
  with a large built-in buffer rather than reflecting real fulfillment
  speed. Tightening delivery estimates is a low-cost lever that could
  improve perceived service quality and potentially conversion, without
  changing actual logistics performance.

### 6. Geography reveals a reach problem, not a demand problem — the project's central surprising insight
- Order volume and average order value are **negatively correlated across
  all 27 states (r = -0.53)** (Query 20) — this was tested as a hypothesis,
  not inferred from two cherry-picked states.
- High-volume São Paulo has the *lowest* AOV (R$125.57); low-volume states
  like Pará and Mato Grosso have AOV nearly 50% higher (Query 16/20).
- **Why it matters:** customers in underserved states aren't buying less
  because they spend less per purchase — they spend *more*. The constraint
  is how often/easily they can order, not whether they can afford to. This
  reframes regional strategy entirely: the opportunity is logistics and
  reach investment, not regional discounting.

### 7. Payment behavior connects back to high-ticket categories
- Credit card dominates payments (73.92%) and is the *only* method with
  meaningful installment usage (avg. 3.51 installments vs. 1.00 for every
  other method) (Query 17).
- This plausibly explains how the `computers` category sustains an AOV of
  **R$1,231.84** (Query 7) despite low order volume (181 orders) — credit
  installments make high-ticket purchases feasible.

---

## Strategic Recommendations

1. **Shift retention strategy from "retain loyal customers" to "convert
   proven spenders."** Since repeat-purchase behavior is structurally rare
   (Finding #2), the highest-leverage retention play is targeting
   high-lifetime-value *one-time* buyers (Finding #3) with a second-purchase
   incentive — not building loyalty programs for a repeat-customer base
   that's currently too small to move overall revenue.

2. **Prioritize eliminating long-tail delivery delays over average delivery
   speed.** Since satisfaction collapses specifically in the 8+ day late
   bucket (Finding #4), Operations should target the root causes behind
   the most severe delay cases first, rather than spreading investment
   evenly across all delivery times.

3. **Audit and tighten `order_estimated_delivery_date` accuracy.**
   Given the platform-wide early-delivery pattern (Finding #5), Olist may be
   able to quote faster delivery promises without any change to real
   fulfillment — a low-cost way to potentially improve conversion and
   perceived reliability.

4. **Invest in logistics and regional presence in high-AOV, low-volume
   states**, rather than price-based promotions there. Since the geography
   finding shows a reach constraint, not a demand constraint (Finding #6),
   discounting in those states would likely be solving the wrong problem.

5. **Explore installment-based financing options specifically for
   high-ticket, low-volume categories** like `computers` (Finding #7), since
   the payment data suggests this is already the mechanism making those
   purchases feasible — formalizing or expanding it could grow that
   category's order volume.

---

## Future Opportunities

- **Predictive CLV modeling:** this project measures historical CLV only
  (Query 11); a logistic/survival model predicting which one-time buyers
  are most likely to convert to repeat customers would directly operationalize
  Recommendation #1.
- **Seller-level root-cause analysis for the late-delivery tail:** Query 13
  identifies which sellers underperform, but doesn't diagnose *why* — a
  follow-up analysis joining seller location, product category, and
  carrier data (if available) could explain the 8+ day delay cluster.
- **A/B test on delivery estimate tightening:** before rolling out
  Recommendation #3 platform-wide, a controlled test on a subset of orders
  would validate whether tighter estimates measurably improve conversion
  without increasing late-delivery complaints.
- **Marketing-channel data integration:** this dataset has no acquisition-
  channel data (noted as an analytical limitation in `docs/data_dictionary.md`),
  which limits CAC analysis — integrating that would let Recommendation #1
  be evaluated against actual acquisition cost, not just lifetime value.

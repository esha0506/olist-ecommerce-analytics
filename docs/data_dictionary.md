# Data Dictionary

## customers
| Column | Type | Meaning |
|---|---|---|
| customer_id | VARCHAR(32) PK | Per-order customer reference |
| customer_unique_id | VARCHAR(32) | True person identifier — use this for retention/repeat-purchase analysis |
| customer_zip_code_prefix | VARCHAR(5) | First digits of customer zip code |
| customer_city | VARCHAR(100) | Customer city |
| customer_state | VARCHAR(2) | Customer state (Brazilian state code) |

## orders
| Column | Type | Meaning |
|---|---|---|
| order_id | VARCHAR(32) PK | Unique order identifier |
| customer_id | VARCHAR(32) FK | References customers.customer_id |
| order_status | VARCHAR(20) | delivered / shipped / canceled / unavailable / etc. |
| order_purchase_timestamp | TIMESTAMP | When the order was placed — revenue date anchor |
| order_approved_at | TIMESTAMP | When payment was approved |
| order_delivered_carrier_date | TIMESTAMP | When order was handed to carrier |
| order_delivered_customer_date | TIMESTAMP | Actual delivery date |
| order_estimated_delivery_date | TIMESTAMP | Promised delivery date |

## order_items
**Primary Key:** Composite — `(order_id, order_item_id)`. Neither column is a primary key on its own.

| Column | Type | Meaning |
|---|---|---|
| order_id | VARCHAR(32) PK (composite) / FK | References orders.order_id |
| order_item_id | INT PK (composite) | Line-item sequence within the order |
| product_id | VARCHAR(32) FK | References products.product_id |
| seller_id | VARCHAR(32) FK | References sellers.seller_id |
| shipping_limit_date | TIMESTAMP | Seller's shipping deadline |
| price | NUMERIC(10,2) | Item price |
| freight_value | NUMERIC(10,2) | Shipping cost charged for this item |

## order_payments
**Primary Key:** Composite — `(order_id, payment_sequential)`. Neither column is a primary key on its own.

| Column | Type | Meaning |
|---|---|---|
| order_id | VARCHAR(32) PK (composite) / FK | References orders.order_id |
| payment_sequential | INT PK (composite) | Sequence if payment was split across methods |
| payment_type | VARCHAR(20) | credit_card / boleto / voucher / debit_card |
| payment_installments | INT | Number of installments |
| payment_value | NUMERIC(10,2) | Amount paid in this transaction |

## order_reviews
| Column | Type | Meaning |
|---|---|---|
| review_id | VARCHAR(32) | Review identifier (not globally unique — some orders contain multiple review records, so deduplication is required before analysis) |
| order_id | VARCHAR(32) FK | References orders.order_id |
| review_score | INT | 1–5 satisfaction score |
| review_comment_title | TEXT | Optional review title |
| review_comment_message | TEXT | Optional review text |
| review_creation_date | TIMESTAMP | When review was created |
| review_answer_timestamp | TIMESTAMP | When review was answered/submitted |

## products
| Column | Type | Meaning |
|---|---|---|
| product_id | VARCHAR(32) PK | Unique product identifier |
| product_category_name | VARCHAR(100) | Category name in Portuguese (610 NULLs exist) |
| product_name_length | INT | Length of product name string |
| product_description_length | INT | Length of product description string |
| product_photos_qty | INT | Number of photos listed |
| product_weight_g | INT | Product weight in grams |
| product_length_cm / product_height_cm / product_width_cm | INT | Product dimensions |

## sellers
| Column | Type | Meaning |
|---|---|---|
| seller_id | VARCHAR(32) PK | Unique seller identifier |
| seller_zip_code_prefix | VARCHAR(5) | Seller zip prefix |
| seller_city | VARCHAR(100) | Seller city |
| seller_state | VARCHAR(2) | Seller state |

## geolocation
**Primary Key:** None — no enforced primary key due to multiple rows per zip code prefix and duplicate coordinate entries.

| Column | Type | Meaning |
|---|---|---|
| geolocation_zip_code_prefix | VARCHAR(5) | Zip prefix (no enforced uniqueness — many rows per prefix) |
| geolocation_lat / geolocation_lng | NUMERIC | Coordinates |
| geolocation_city | VARCHAR(100) | City name |
| geolocation_state | VARCHAR(2) | State code |

## category_translation
| Column | Type | Meaning |
|---|---|---|
| product_category_name | VARCHAR(100) PK | Category name in Portuguese |
| product_category_name_english | VARCHAR(100) | English translation |

---

## Known Data Quality Issues
1. `customer_id` is per-order, not per-person — use `customer_unique_id` for retention analysis.
2. `order_items` and `order_payments` use composite primary keys — `(order_id, order_item_id)` and `(order_id, payment_sequential)` respectively. `order_id` alone is never a primary key in either table.
3. `geolocation` has no enforced primary key due to multiple rows per zip code prefix and duplicate coordinate entries.
4. Some orders contain multiple review records, so deduplication is required before analysis.
5. 610 products have a NULL `product_category_name`.
6. `order_status` includes non-delivered states that should be explicitly filtered depending on the analysis (revenue vs. funnel vs. operational).
7. Orders with NULL `order_delivered_customer_date` will break delivery-delay calculations unless filtered.

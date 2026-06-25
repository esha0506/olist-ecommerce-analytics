-- ============================================================
-- OLIST E-COMMERCE ANALYTICS PROJECT
-- Schema: Table Creation
-- Database: olist_ecommerce
-- ============================================================

-- Clean slate (safe to re-run during setup)
DROP TABLE IF EXISTS order_reviews CASCADE;
DROP TABLE IF EXISTS order_payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS geolocation CASCADE;
DROP TABLE IF EXISTS category_translation CASCADE;

-- ------------------------------------------------------------
-- customers
-- Grain: one row per customer_id (per-order customer instance)
-- ------------------------------------------------------------
CREATE TABLE customers (
    customer_id              VARCHAR(32) PRIMARY KEY,
    customer_unique_id        VARCHAR(32) NOT NULL,
    customer_zip_code_prefix  VARCHAR(5),
    customer_city             VARCHAR(100),
    customer_state            VARCHAR(2)
);

-- ------------------------------------------------------------
-- orders
-- Grain: one row per order
-- ------------------------------------------------------------
CREATE TABLE orders (
    order_id                       VARCHAR(32) PRIMARY KEY,
    customer_id                    VARCHAR(32) NOT NULL REFERENCES customers(customer_id),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       TIMESTAMP,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP
);

-- ------------------------------------------------------------
-- sellers
-- Grain: one row per seller
-- ------------------------------------------------------------
CREATE TABLE sellers (
    seller_id              VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5),
    seller_city            VARCHAR(100),
    seller_state            VARCHAR(2)
);

-- ------------------------------------------------------------
-- category_translation
-- Grain: one row per category name mapping (lookup table)
-- ------------------------------------------------------------
CREATE TABLE category_translation (
    product_category_name          VARCHAR(100) PRIMARY KEY,
    product_category_name_english  VARCHAR(100)
);

-- ------------------------------------------------------------
-- products
-- Grain: one row per product
-- ------------------------------------------------------------
CREATE TABLE products (
    product_id                  VARCHAR(32) PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_name_length         INT,
    product_description_length  INT,
    product_photos_qty          INT,
    product_weight_g            INT,
    product_length_cm           INT,
    product_height_cm           INT,
    product_width_cm            INT
);

-- ------------------------------------------------------------
-- order_items
-- Grain: one row per item line within an order
-- Composite PK: (order_id, order_item_id)
-- ------------------------------------------------------------
CREATE TABLE order_items (
    order_id             VARCHAR(32) NOT NULL REFERENCES orders(order_id),
    order_item_id        INT NOT NULL,
    product_id           VARCHAR(32) REFERENCES products(product_id),
    seller_id             VARCHAR(32) REFERENCES sellers(seller_id),
    shipping_limit_date   TIMESTAMP,
    price                 NUMERIC(10,2),
    freight_value         NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- ------------------------------------------------------------
-- order_payments
-- Grain: one row per payment transaction per order
-- Composite PK: (order_id, payment_sequential)
-- ------------------------------------------------------------
CREATE TABLE order_payments (
    order_id              VARCHAR(32) NOT NULL REFERENCES orders(order_id),
    payment_sequential    INT NOT NULL,
    payment_type          VARCHAR(20),
    payment_installments  INT,
    payment_value         NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- ------------------------------------------------------------
-- order_reviews
-- Grain: one row per review (mostly 1:1 with order_id, some dupes)
-- review_id is NOT guaranteed globally unique in raw data,
-- so PK is intentionally NOT enforced here -- see validation queries.
-- ------------------------------------------------------------
CREATE TABLE order_reviews (
    review_id                VARCHAR(32),
    order_id                  VARCHAR(32) NOT NULL REFERENCES orders(order_id),
    review_score              INT,
    review_comment_title      TEXT,
    review_comment_message    TEXT,
    review_creation_date      TIMESTAMP,
    review_answer_timestamp   TIMESTAMP
);

-- ------------------------------------------------------------
-- geolocation
-- Grain: one row per zip-prefix + lat/lng combination
-- NO natural primary key -- many duplicate/near-duplicate rows
-- per zip prefix. Must be pre-aggregated before joining (Phase 6).
-- ------------------------------------------------------------
CREATE TABLE geolocation (
    geolocation_zip_code_prefix  VARCHAR(5),
    geolocation_lat               NUMERIC(11,8),
    geolocation_lng               NUMERIC(11,8),
    geolocation_city               VARCHAR(100),
    geolocation_state              VARCHAR(2)
);

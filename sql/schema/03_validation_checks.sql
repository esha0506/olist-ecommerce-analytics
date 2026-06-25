-- ============================================================
-- OLIST E-COMMERCE ANALYTICS PROJECT
-- Validation Queries: Post-Load Integrity Checks
-- ============================================================

-- 1. Row counts per table
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation
ORDER BY table_name;

-- 2. Confirm customer_id vs customer_unique_id quirk (Phase 2 finding)
SELECT
    COUNT(*)                          AS total_customer_rows,
    COUNT(DISTINCT customer_id)        AS distinct_customer_id,
    COUNT(DISTINCT customer_unique_id) AS distinct_unique_person
FROM customers;

-- 3. Confirm order_items grain (multiple items per order exist)
SELECT
    COUNT(*)                  AS total_item_rows,
    COUNT(DISTINCT order_id)   AS distinct_orders_with_items
FROM order_items;

-- 4. Check for duplicate review rows per order (Phase 2 data quality flag)
SELECT
    order_id,
    COUNT(*) AS review_count
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_count DESC
LIMIT 10;

-- 5. Check for NULL product categories (Phase 2 data quality flag)
SELECT
    COUNT(*) AS products_with_null_category
FROM products
WHERE product_category_name IS NULL;

-- 6. Check geolocation duplication per zip prefix (Phase 2 data quality flag)
SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS row_count
FROM geolocation
GROUP BY geolocation_zip_code_prefix
ORDER BY row_count DESC
LIMIT 5;

-- 7. Order status breakdown (relevant for funnel/revenue filtering decisions)
SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 8. Orders missing delivered_customer_date (relevant for delivery delay calc)
SELECT
    order_status,
    COUNT(*) AS orders_missing_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY orders_missing_delivery_date DESC;

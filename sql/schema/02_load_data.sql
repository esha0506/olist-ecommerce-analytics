-- ============================================================
-- OLIST E-COMMERCE ANALYTICS PROJECT
-- Data Loading: CSV Import via \copy
--
-- Load order matters due to foreign key constraints:
-- 1. Independent/lookup tables first (customers, sellers, products,
--    category_translation, geolocation)
-- 2. orders (depends on customers)
-- 3. order_items, order_payments, order_reviews (depend on orders)
-- ============================================================

-- ============================================================
-- OLIST E-COMMERCE ANALYTICS PROJECT
-- Data Loading: CSV Import via \copy
-- ============================================================

-- ============================================================
-- 1. Load customers (independent table)
-- ============================================================
\copy customers 
FROM 'C:/olist_project/data/olist_customers_dataset.csv' 
WITH (FORMAT csv, HEADER true, QUOTE '"');

-- ============================================================
-- 2. Load sellers (independent table)
-- ============================================================
\copy sellers 
FROM 'C:/olist_project/data/olist_sellers_dataset.csv' 
WITH (FORMAT csv, HEADER true, QUOTE '"');

-- ============================================================
-- 3. Load category translation (lookup table)
-- ============================================================
\copy category_translation 
FROM 'C:/olist_project/data/product_category_name_translation.csv' 
WITH (FORMAT csv, HEADER true, QUOTE '"');

-- ============================================================
-- 4. Load products (depends on category mapping)
-- ============================================================
\copy products 
FROM 'C:/olist_project/data/olist_products_dataset.csv' 
WITH (FORMAT csv, HEADER true, QUOTE '"');

-- ============================================================
-- 5. Load geolocation (independent but large dataset)
-- ============================================================
\copy geolocation 
FROM 'C:/olist_project/data/olist_geolocation_dataset.csv' 
WITH (FORMAT csv, HEADER true, QUOTE '"');

-- ============================================================
-- 6. Load orders (depends on customers)
-- ============================================================
\copy orders 
FROM 'C:/olist_project/data/olist_orders_dataset.csv' 
WITH (FORMAT csv, HEADER true, QUOTE '"');

-- ============================================================
-- 7. Load order items (depends on orders, products, sellers)
-- ============================================================
\copy order_items 
FROM 'C:/olist_project/data/olist_order_items_dataset.csv' 
WITH (FORMAT csv, HEADER true, QUOTE '"');

-- ============================================================
-- 8. Load order payments (depends on orders)
-- ============================================================
\copy order_payments 
FROM 'C:/olist_project/data/olist_order_payments_dataset.csv' 
WITH (FORMAT csv, HEADER true, QUOTE '"');

-- ============================================================
-- 9. Load order reviews (depends on orders)
-- ============================================================
\copy order_reviews 
FROM 'C:/olist_project/data/olist_order_reviews_dataset.csv' 
WITH (FORMAT csv, HEADER true, QUOTE '"');

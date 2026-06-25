-- ============================================================
-- OLIST E-COMMERCE ANALYTICS PROJECT
-- Indexing: Performance Optimization
--
-- Why these indexes:
-- - PostgreSQL auto-indexes PRIMARY KEY columns, but NOT foreign
--   keys. Every FK used in a JOIN here gets an explicit index.
-- - geolocation has no PK, so we index its join/group column directly.
-- - orders.order_purchase_timestamp is indexed because almost every
--   revenue/trend query in Phase 6 filters or groups by date.
-- - customers.customer_unique_id is indexed because retention/repeat
--   analysis (Phase 6) joins/groups on it constantly.
-- ============================================================

-- Foreign key indexes (orders)
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- Foreign key indexes (order_items)
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_seller_id ON order_items(seller_id);

-- Foreign key indexes (order_payments)
CREATE INDEX idx_order_payments_order_id ON order_payments(order_id);

-- Foreign key indexes (order_reviews)
CREATE INDEX idx_order_reviews_order_id ON order_reviews(order_id);

-- Products: category join is used constantly in Phase 6 revenue-by-category queries
CREATE INDEX idx_products_category_name ON products(product_category_name);

-- Customers: retention/cohort analysis groups on the real person ID
CREATE INDEX idx_customers_unique_id ON customers(customer_unique_id);

-- Geolocation: no PK, but always grouped/joined on zip prefix
CREATE INDEX idx_geolocation_zip_prefix ON geolocation(geolocation_zip_code_prefix);

-- Orders: date-based filtering/grouping is the backbone of revenue trend analysis
CREATE INDEX idx_orders_purchase_timestamp ON orders(order_purchase_timestamp);
CREATE INDEX idx_orders_status ON orders(order_status);

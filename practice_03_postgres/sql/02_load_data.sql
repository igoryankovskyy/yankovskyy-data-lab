

-- CUSTOMERS
COPY customers(customer_id, email, full_name, phone, country, city, registered_at)
FROM '/data/customers.csv'
WITH (FORMAT csv, HEADER true);

-- PRODUCTS
COPY products(product_id,sku, name, brand, category, price, stock, is_active, attributes)
FROM '/data/products.csv'
WITH (FORMAT csv, HEADER true);

-- ORDERS
COPY orders(order_id, customer_id, status, created_at)
FROM '/data/orders.csv'
WITH (FORMAT csv, HEADER true);

-- ORDER_ITEMS
COPY orders(order_id, product_id, quantity, unit_price)
FROM '/data/order_items.csv'
WITH (FORMAT csv, HEADER true);

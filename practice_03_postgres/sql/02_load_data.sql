
-- bash command:
-- docker exec -i shop-practice-db-1 psql -U postgres -d shop \
--  -c "\copy customers (customer_id,email,full_name,phone,country,city,registered_at) \
-- FROM stdin WITH (FORMAT csv, HEADER true);" < data/customers.csv

-- SELECT column_name 
-- FROM information_schema.columns 
-- WHERE table_schema = 'public' 
--   AND table_name = 'customers';

-- CUSTOMERS
COPY customers (customer_id, email, full_name, phone, country, city, registered_at)
FROM '/data/customers.csv'
WITH (FORMAT csv, HEADER true);



SELECT pg_get_serial_sequence('customers', 'customer_id');
SELECT currval('customers_customer_id_seq');
SELECT last_value FROM customers_customer_id_seq;
SELECT count(*) from customers;

-- PRODUCTS
COPY products (product_id,sku, name, brand, category, price, stock, is_active, attributes)
FROM '/data/products.csv'
WITH (FORMAT csv, HEADER true);

-- ORDERS
COPY orders (order_id, customer_id, status, created_at)
FROM '/data/orders.csv'
WITH (FORMAT csv, HEADER true);

-- ORDER_ITEMS
COPY order_items (order_id, product_id, quantity, unit_price)
FROM '/data/order_items.csv'
WITH (FORMAT csv, HEADER true);

ALTER TABLE customers 
ALTER COLUMN customer_id 
RESTART WITH 41;

SELECT setval(
    pg_get_serial_sequence('products', 'product_id'), 
    COALESCE(1 + (SELECT MAX(product_id) FROM products), 1),
    -- третій аргумент: true, якщо таблиця не порожня, або false, якщо порожня
    (SELECT COUNT(*) > 0 FROM products)
);

SELECT setval(
    pg_get_serial_sequence('customers', 'customer_id'), 
    COALESCE(1 + (SELECT MAX(customer_id) FROM customers), 1),
    -- третій аргумент: true, якщо таблиця не порожня, або false, якщо порожня
    (SELECT COUNT(*) > 0 FROM customers)
);

SELECT setval(
    pg_get_serial_sequence('orders', 'order_id'), 
    COALESCE(1 + (SELECT MAX(order_id) FROM orders), 1),
    -- третій аргумент: true, якщо таблиця не порожня, або false, якщо порожня
    (SELECT COUNT(*) > 0 FROM orders)
);


-- Додайте командою INSERT нового покупця, 
-- не вказуючи customer_id і registered_at: 
-- email nazar.kravets@example.com, 
-- імʼя Назар Кравець, 
-- телефон +380671234567, 
-- країна UA, 
-- місто Тернопіль. 
-- Тією самою командою поверніть customer_id і registered_at доданого рядка.

INSERT INTO customers (email, full_name, phone, country, city)
VALUES ('nazar.kravets@example.com', 'Назар Кравець', '+380671234567', 'UA', 'Тернопіль')
RETURNING customer_id, registered_at;

-- Пересуньте лічильники ідентифікаторів у таблицях 
-- customers, products і orders: 
-- наступне значення, яке видасть база, має бути на одиницю більшим за 
-- найбільший ідентифікатор із відповідного файла.
SELECT setval(
    pg_get_serial_sequence('customers', 'customer_id'), 
    1 + (SELECT MAX(customer_id) FROM customers)
);

SELECT nextval('customers_customer_id_seq');


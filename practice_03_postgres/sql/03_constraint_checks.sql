
-- 1. Додайте покупця з email, який уже належить покупцю з customer_id = 1.
-- ERROR: duplicate key value violates unique constraint "customers_email_key"
INSERT INTO customers (email, full_name, phone, country, city)
VALUES (
    'olena.koval@example.com', 
    'user 46', '+380671234567', 
    'UA', 'Тернопіль')
RETURNING customer_id, registered_at;

-- 2. Дodайте товар із ціною 0
-- ERROR: new row for relation "products" violates check constraint "products_price_check"
INSERT INTO products (sku, name, brand, category, price, stock, is_active)
VALUES (
    'SKU-0046',
    'product 46', 
    'brand 46', 
    'category 46', 
    0, 
    100, 
    true
)
RETURNING product_id;

-- 3. Дodайте в замовлення з order_id = 1 позицію з товаром, якого немає в таблиці products.
-- ERROR: insert or update on table "order_items" violates foreign key constraint "order_items_product_id_fkey" 
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (
    1,
    9999, -- неіснуючий product_id
    1,
    100.00
) RETURNING order_id, product_id;

-- 4. Дodайте в замовлення з order_id = 1 позицію з товаром, який у цьому замовленні вже є.
-- ERROR: duplicate key value violates unique constraint "order_items_pkey"
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (
    1,
    18, -- product_id, який уже є в order_id = 1
    1,
    100.00
) RETURNING order_id, product_id;


-- 5. Змініть статус замовлення з order_id = 1 на returned.
-- ERROR: new row for relation "orders" violates check constraint "orders_status_check"
UPDATE orders
SET status = 'returned'
WHERE order_id = 1
RETURNING order_id, status;

-- 6. Видаліть покупця з customer_id = 1.
-- ERROR: update or delete on table "customers" violates foreign key constraint "orders_customer_id_fkey" on table "orders"
DELETE FROM customers
WHERE customer_id = 1
RETURNING customer_id;  
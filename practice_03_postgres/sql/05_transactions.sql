
-- Завдання 5.1. Оформлення замовлення


-- Покупець з email nazar.kravets@example.com замовляє два товари: 
-- APL-IPD11-A16 — 2 штуки 
-- і SNY-XM5 — 1 штуку. 
-- Ціна продажу дорівнює поточній ціні товару.

-- 5.1.1. Відкрийте транзакцію.
begin;

-- 5.1.2. Заблокуйте рядки обох товарів запитами, які читають їхній залишок. 
-- Рядки блокуйте за зростанням product_id.
select stock 
from products 
where sku in ('APL-IPD11-A16', 'SNY-XM5') 
order by product_id;


-- 5.1.3.0. перевірка лічильника таблиці orders
SELECT setval('orders_order_id_seq', (SELECT MAX(order_id) FROM orders));

-- 5.1.3. Додайте замовлення покупця, не вказуючи статус і момент створення. 
-- Тією самою командою поверніть order_id.
insert into orders (customer_id)
select customer_id
from customers
where email = 'nazar.kravets@example.com'
returning order_id, customer_id;

-- 5.1.4. Додайте дві позиції цього замовлення однією командою INSERT.
with target_customer as (
    -- Знаходимо ID покупця за email
    select customer_id
    from customers
    where email = 'nazar.kravets@example.com'
),
target_order as (
    -- Знаходимо останнє замовлення цього покупця
    select o.order_id 
    from orders o
    join target_customer tc on o.customer_id = tc.customer_id
    order by o.created_at desc
    limit 1
)
-- Вставляємо товари у знайдене замовлення
insert into order_items (order_id, product_id, quantity, unit_price)
select 
    (select order_id from target_order), 
    p.product_id, 
    case p.sku 
        when 'APL-IPD11-A16' then 2
        when 'SNY-XM5' then 1
    end as quantity,
    p.price as unit_price
from products p
where p.sku in ('APL-IPD11-A16', 'SNY-XM5')
returning order_id, product_id, quantity, unit_price;


-- 5.1.5. Зменште залишок кожного з двох товарів на замовлену кількість. 
-- Нове значення обчислюйте в самій команді від поточного залишку,  
-- товари змінюйте за зростанням product_id.
with target_customer as (
    -- Знаходимо ID покупця за email
    select customer_id
    from customers
    where email = 'nazar.kravets@example.com'
),
target_order as (
    -- Знаходимо останнє замовлення цього покупця
    select o.order_id 
    from orders o
    join target_customer tc on o.customer_id = tc.customer_id
    order by o.created_at desc
    limit 1
)
-- Оновлюємо залишки товарів на основі позицій у цьому замовленні
update products p
set stock = p.stock - oi.quantity
from order_items oi
where p.product_id = oi.product_id
  -- Використовуємо підзапит замість прямого звернення
  and oi.order_id = (select order_id from target_order) 
returning p.product_id, p.stock;

-- 5.1.6.    Зафіксуйте транзакцію.
commit;


-- test point
rollback;


-- Завдання 5.2. 
--
-- Замовлення, яке зупиняє обмеження
-- Покупець з customer_id = 1 замовляє 3 штуки товару APL-MBA13-M4, 
-- на складі їх менше.

-- 5.2.1. Відкрийте транзакцію.
begin;

-- 5.2.2. Додайте замовлення покупця і поверніть order_id.
insert into orders (customer_id)
values (1)
returning order_id, customer_id,status, created_at; 

-- 5.2.3. Додайте позицію замовлення: 3 штуки товару за поточною ціною.
WITH latest_order AS (
    SELECT order_id 
    FROM orders 
    WHERE customer_id = 1 
    ORDER BY created_at DESC 
    LIMIT 1
)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 
    lo.order_id,
    p.product_id, 
    3 AS quantity,
    p.price AS unit_price
FROM products p
CROSS JOIN latest_order lo
WHERE p.sku = 'APL-MBA13-M4'
RETURNING order_id, product_id, quantity, unit_price; 

-- 5.2.4. Зменште залишок товару на 3 штуки.
UPDATE products 
SET stock = stock - 3
WHERE sku = 'APL-MBA13-M4';

-- 5.2.5. Завершіть транзакцію командою, яку приймає перервана транзакція.
commit;

-- Отримати на виході. 
-- Після виконання цього блоку в orders немає нового замовлення, 
-- в таблиці order_items немає його позицій, 
-- в таблиці products залишок товару APL-MBA13-M4 не змінився.


--Завдання 5.3. 
--
-- Прайс-лист постачальника
-- Постачальник надіслав прайс-лист із чотирьох товарів. 
-- Частина з них уже є в таблиці products, решта — нові. 
-- Водночас навушники JBL-T520BT знято з продажу.

-- 5.3.1. Відкрийте транзакцію.
begin;

-- 5.3.2. Завантажте всі чотири рядки прайс-листа однією командою INSERT: 
-- товар з новим sku додається, а в товару з наявним sku оновлюються price і stock. 
-- Тією самою командою поверніть sku, стару і нову ціну кожного рядка.

-- 5.3.2.1. перевірка лічильника таблиці categories
SELECT setval('categories_category_id_seq', (SELECT MAX(category_id) FROM categories));

-- 5.3.2.2. Автоматично витягуємо унікальні категорії з прайс-листа 
-- і додаємо їх у довідник (якщо їх ще немає)
INSERT INTO categories (name)
SELECT DISTINCT category_name 
FROM (
    VALUES 
        ('APL-APP3', 'AirPods Pro 3', 'Apple', 'Навушники', 11999.00, 42),
        ('SMS-S25-256', 'Galaxy S25 256GB', 'Samsung', 'Смартфони', 35999.00, 20),
        ('GGL-PX10-128', 'Pixel 10 128GB', 'Google', 'Смартфони', 34999.00, 15),
        ('LNV-TABP12', 'Tab P12', 'Lenovo', 'Планшети', 15499.50, 10)
) AS incoming_data(sku, name, brand, category_name, price, stock)
ON CONFLICT (name) DO NOTHING;

-- 5.3.2.3. перевірка лічильника таблиці products
SELECT setval('products_product_id_seq', (SELECT MAX(product_id) FROM products));

-- 5.3.2.4. Вставляємо або оновлюємо самі товари, зв'язуючи їх із таблицею categories через підзапит
-- INSERT INTO products (sku, name, brand, category_id, price, stock)
-- SELECT 
--     v.sku, 
--     v.name, 
--     v.brand, 
--     c.category_id, 
--     v.price, 
--     v.stock
-- FROM (
--     VALUES 
--         ('APL-APP3', 'AirPods Pro 3', 'Apple', 'Навушники', 11999.00, 42),
--         ('SMS-S25-256', 'Galaxy S25 256GB', 'Samsung', 'Смартфони', 35999.00, 20),
--         ('GGL-PX10-128', 'Pixel 10 128GB', 'Google', 'Смартфони', 34999.00, 15),
--         ('LNV-TABP12', 'Tab P12', 'Lenovo', 'Планшети', 15499.50, 10)
-- ) AS v(sku, name, brand, category_name, price, stock)
-- JOIN categories c ON c.name = v.category_name
-- ON CONFLICT (sku) DO UPDATE
-- SET price = excluded.price,
--     stock = excluded.stock,
--     category_id = excluded.category_id
-- RETURNING 
--     products.product_id,
--     products.sku, 
--     products.price AS old_price, 
--     excluded.price AS new_price;
INSERT INTO products (sku, name, brand, category_id, price, stock)
VALUES 
    ('APL-APP3', 'AirPods Pro 3', 'Apple', 2, 11999.00, 42),
    ('SMS-S25-256', 'Galaxy S25 256GB', 'Samsung', 1, 35999.00, 20),
    ('GGL-PX10-128', 'Pixel 10 128GB', 'Google', 1, 34999.00, 15),
    ('LNV-TABP12', 'Tab P12', 'Lenovo', 5, 15499.50, 10)
ON CONFLICT (sku) DO UPDATE
SET price = excluded.price,
    stock = excluded.stock,
    category_id = excluded.category_id
-- PostgreSQL 18+ (з'явилися old і new у RETURNING):
RETURNING product_id, sku,
          old.price AS old_price,   -- NULL для нових рядків
          new.price AS new_price;



-- 5.3.3. Створіть точку збереження before_discontinue.
savepoint before_discontinue;


-- 5.3.4. Виконайте команду, яка видаляє товар JBL-T520BT з таблиці products. 
-- База відхилить її, бо товар є в позиціях замовлень.
delete from products
where sku = 'JBL-T520BT';


-- 5.3.5. Відкотіть транзакцію до точки збереження before_discontinue.
rollback to savepoint before_discontinue;


-- 5.3.6. Позначте товар JBL-T520BT як такий, що не продається.
update products
set is_active = false
where sku = 'JBL-T520BT';   


-- 5.3.7. Зафіксуйте транзакцію.
commit;



-- TEST POINT
rollback;


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
--rollback;

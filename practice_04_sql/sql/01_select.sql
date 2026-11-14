SET TIME ZONE 'UTC';



-- Active: 1794534791691@@maglev.proxy.rlwy.net@19669@shop_db


-- Завдання 4.1.1. 

-- Покупці без електронної пошти
-- Маркетинг готує SMS-розсилку для нових польських покупців, які не залишили електронної пошти.
-- Виберіть із shop.customers покупців із Польщі, 
-- які зареєструвалися у грудні 2025 року і не вказали електронну пошту.
-- Відсортуйте від найновішої реєстрації до найдавнішої, 
--за однакового часу — за customer_id.
-- ℹ️ Підказка.
-- Місяць задається двома порівняннями:
-- від його першого дня включно до першого дня наступного місяця не включно.
-- Отримати на виході.
-- Один рядок — один покупець.
-- Колонки: customer_id, first_name, last_name, phone, registered_at.

select 
    cc.customer_id "ID", 
    cc.first_name "Ім'я", 
    cc.last_name "Прізвище", 
    cc.phone "Телефон", 
    cc.registered_at "Дата реєстрації"
from shop.customers as cc 
where cc.country_code = 'PL'
    and cc.email is null
    and cc.registered_at >= '2025-12-01' 
    and cc.registered_at < '2026-01-01'
order by cc.registered_at desc, cc.customer_id;


-- Завдання 4.1.2. Пошук у каталозі

-- Відділ закупівель хоче бачити лінійку Pro серед смартфонів і планшетів окремо від флагманів Pro Max.
-- Виберіть із shop.products товари з артикулом sku, 
-- що починається з PHN- або TAB-, 
-- і назвою, яка містить Pro, але не містить Pro Max.
-- Відсортуйте за вагою за спаданням, за однакової ваги — за sku.

-- РЕЗУЛЬТАТ.
-- Один рядок — один товар. 
-- Колонки: product_id, sku, name, weight_kg.

select 
    pp.product_id as "ID", 
    pp.sku as "Артикул", 
    pp.name as "Назва", 
    pp.weight_kg as "Вага, кг"
from shop.products as pp
join shop.categories as cc on pp.category_id = cc.category_id
where cc.name in ('Смартфони', 'Планшети')
    and (pp.sku like 'PHN-%' or pp.sku like 'TAB-%')
    and pp.name ilike '%Pro%'
    and pp.name not ilike '%Pro Max%'
order by pp.weight_kg desc, pp.sku; 


-- Завдання 4.1.3. Варіанти оплати

-- Фінансовий відділ хоче знати, які способи оплати і строки розстрочки
-- справді трапляються в кожній країні.
-- Виведіть із shop.orders усі різні поєднання країни, способу оплати і кількості внесків.
-- Відсортуйте за країною, способом оплати і кількістю внесків.

-- РЕЗУЛЬТАТ. 
-- Один рядок — одне унікальне поєднання.
-- Колонки: country_code, payment_method, installments_count.

select 
    oo.country_code "Код країни", 
    oo.payment_method "Спосіб оплати", 
    sum(oo.installments_count) "Кількість внесків"
from shop.orders as oo
group by oo.country_code, oo.payment_method
order by oo.country_code, oo.payment_method;


-- Завдання 4.1.4.
-- Третя сторінка списку повернених замовлень
-- Служба підтримки переглядає в адмінпанелі посторінково найдорожчі українські замовлення 2025 року, повернені відправнику.
-- Виберіть із shop.orders замовлення з України зі статусом returned_to_sender, створені у 2025 році.
-- Відсортуйте за сумою замовлення за спаданням і виведіть третю сторінку цього списку по 25 рядків.

-- ℹ️ Підказка. 
-- Замовлень з однаковою сумою багато. 
-- Щоб сторінки не перетиналися і не губили рядки, сортування має бути однозначним.

-- РЕЗУЛЬТАТ. 
-- 25 рядків, один рядок — одне замовлення. 
-- Колонки: order_id, created_at, total_amount, payment_method.

select 
    oo.order_id "ID", 
    to_char(oo.created_at, 'YYYY-MM-DD hh24:MI') "Дата створення", 
    oo.total_amount "Сума замовлення", 
    oo.payment_method "Спосіб оплати"
from shop.orders as oo
where oo.country_code = 'UA'
    and oo.status = 'returned_to_sender'
    and oo.created_at >= '2025-01-01' and oo.created_at < '2026-01-01'
order by oo.total_amount desc, oo.order_id
limit 25 offset 50



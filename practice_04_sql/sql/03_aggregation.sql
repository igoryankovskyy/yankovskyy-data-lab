

-- Завдання 4.3.1. Підсумки 2025 року за країнами

-- Керівництво підбиває підсумки 2025 року і порівнює Україну та Польщу за отриманими замовленнями.
-- Для кожної країни порахуйте за замовленнями зі статусом received, створеними у 2025 році:
-- orders_cnt — кількість замовлень;
-- customers_cnt — кількість різних покупців;
-- total_sum — загальна сума;
-- avg_check — середня сума замовлення з округленням до двох знаків після коми;
-- min_check — найменша сума замовлення;
-- max_check — найбільша сума замовлення.
-- Відсортуйте за кодом країни.

-- РЕЗУЛЬТАТ.
-- Один рядок — одна країна.
-- Колонки:
-- country_code, orders_cnt, customers_cnt, total_sum, avg_check, min_check, max_check.

select 
    oo.country_code as "Код країни",
    count(*) as "Кількість замовлень",
    count(distinct oo.customer_id) as "Кількість покупців",
    sum(oo.total_amount) as "Загальна сума",
    round(avg(oo.total_amount), 2) as "Середня сума замовлення",
    min(oo.total_amount) as "Найменша сума замовлення",
    max(oo.total_amount) as "Найбільша сума замовлення"
from shop.orders as oo
where oo.country_code in ('UA', 'PL')
    and oo.status = 'received'
    and oo.created_at >= '2025-01-01' and oo.created_at < '2026-01-01'
group by oo.country_code
order by oo.country_code;   



-- Завдання 4.3.2. Помісячна динаміка в Україні

-- Відділ продажів хоче бачити, як змінювалися продажі в Україні від місяця до місяця.
-- Для кожного календарного місяця створення замовлення
-- порахуйте за замовленнями з України зі статусом received за весь період, що є в базі:
-- order_month — місяць датою його першого дня, без часу;
-- orders_cnt — кількість замовлень;
-- customers_cnt — кількість різних покупців;
-- total_sum — загальна сума;
-- avg_check — середня сума замовлення з округленням до двох знаків після коми.
-- Відсортуйте від найдавнішого місяця до найновішого.

-- ℹ️ Підказка. Номер місяця не розрізняє роки: січень 2024 року і січень 2025 року мають потрапити в різні групи.
-- РЕЗУЛЬТАТ.
-- Один рядок — один місяць. 
-- Колонки: order_month, orders_cnt, customers_cnt, total_sum, avg_check.

select 
    date_trunc('month', oo.created_at)::date as "Місяць",
    count(*) as "Кількість замовлень",
    count(distinct oo.customer_id) as "Кількість покупців",
    sum(oo.total_amount) as "Загальна сума",
    round(avg(oo.total_amount), 2) as "Середня сума замовлення"
from shop.orders as oo
where oo.country_code = 'UA'
    and oo.status = 'received'
group by date_trunc('month', oo.created_at)
order by date_trunc('month', oo.created_at);    


-- Завдання 4.3.3. Замовлення за годинами доби
-- Кол-центр планує графік змін і хоче знати,
-- на які години доби припадає найбільше замовлень у кожній країні.

-- Для кожної країни і кожної години доби за UTC порахуйте за нескасованими замовленнями,
-- створеними у 2025 році:
-- order_hour — година доби від 0 до 23 цілим числом;
-- orders_cnt — кількість замовлень;
-- avg_check — середня сума замовлення з округленням до двох знаків після коми.
-- Відсортуйте за країною і годиною.

-- Отримати на виході.
-- Один рядок — одна година доби в одній країні.
-- Колонки:
-- country_code, order_hour, orders_cnt, avg_check.

select 
    oo.country_code as "Код країни",
    extract(hour from oo.created_at) as "Година доби",
    count(*) as "Кількість замовлень",
    round(avg(oo.total_amount), 2) as "Середня сума замовлення"
from shop.orders as oo
where oo.status != 'canceled'
    and oo.created_at >= '2025-01-01' and oo.created_at < '2026-01-01'
group by oo.country_code, extract(hour from oo.created_at)
order by oo.country_code, extract(hour from oo.created_at); 


-- Завдання 4.3.4. Постійні покупці

-- Маркетинг відбирає найцінніших українських покупців для програми лояльності.
-- Для кожного покупця порахуйте за його замовленнями з України
-- зі статусом received за весь період, що є в базі:
-- orders_cnt — кількість таких замовлень;
-- total_sum — їхня загальна сума;
-- first_order_date — дата першого замовлення без часу;
-- last_order_date — дата останнього замовлення без часу.
-- Залиште покупців із 15 і більше такими замовленнями на загальну суму від 500 000 гривень,
-- відсортуйте за total_sum за спаданням, за однакової суми — за customer_id, і виведіть перших 20.

-- Отримати на виході.
-- 20 рядків, один рядок — один покупець.
-- Колонки:
-- customer_id, orders_cnt, total_sum, first_order_date, last_order_date.

select 
    oo.customer_id as "ID покупця",
    count(*) as "Кількість замовлень",
    sum(oo.total_amount) as "Загальна сума",
    min(oo.created_at)::date as "Дата першого замовлення",
    max(oo.created_at)::date as "Дата останнього замовлення"
from shop.orders as oo      
where oo.country_code = 'UA'
    and oo.status = 'received'
group by oo.customer_id     
having count(*) >= 15 and sum(oo.total_amount) >= 500000
order by sum(oo.total_amount) desc, oo.customer_id
limit 20;


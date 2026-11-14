SET TIME ZONE 'UTC';

-- Завдання 4.5.1. Стрічка подій замовлення

-- Служба підтримки розбирає скаргу покупця
-- і хоче бачити всю історію замовлення 271060 однією стрічкою.

-- Зберіть в один результат події замовлення
-- з order_id = 271060 із таблиць shop.orders, shop.payments і shop.shipments:
-- замовлення створено — з shop.orders, з часом створення і сумою замовлення;
-- платіж успішний або платіж відхилено
-- — кожен платіж із shop.payments з часом і сумою платежу
--   (за статусом succeeded або failed);
-- відправлено — з shop.shipments, з часом shipped_at, без суми
--   (лише якщо час заповнено);
-- отримано — з shop.shipments, з часом received_at, без суми
--   (лише якщо час заповнено).
-- Відсортуйте за часом події від найдавнішої до найновішої.

-- РЕЗУЛЬТАТ.
-- Один рядок — одна подія замовлення.
-- Колонки:
-- event_at, event, amount.

select
    oo.created_at as "Час події",
    'Замовлення створено' as "Подія",
    oo.total_amount as "Сума"
from shop.orders as oo
where oo.order_id = 271060

union all

select
    pp.created_at,
    case pp.status
        when 'succeeded' then 'Платіж успішний'
        when 'failed'    then 'Платіж відхилено'
        else 'Платіж: ' || pp.status
    end,
    pp.amount
from shop.payments as pp
where pp.order_id = 271060

union all

select
    ev.event_at,
    ev.event_name,
    null::numeric
from shop.shipments as ss
cross join lateral (
    values
        ('Відправлено', ss.shipped_at),
        ('Прибуло',     ss.arrived_at),
        ('Отримано',    ss.received_at),
        ('Повернено',   ss.returned_at)
) as ev(event_name, event_at)
where ss.order_id = 271060
  and ev.event_at is not null

order by "Час події";


-- Завдання 5.2. Звірка сум за грудень 2025 року
-- Бухгалтерія звіряє за грудень 2025 року суми замовлень,
-- їхніх позицій і успішних платежів, щоб знайти розбіжності.

-- Для замовлень, створених у грудні 2025 року,
-- порахуйте окремо для кожної країни три показники і виведіть їх одним результатом,
-- кожен показник кожної країни — окремим рядком:
-- замовлення — сума total_amount цих замовлень;
-- позиції — сума добутків кількості на ціну одиниці за всіма позиціями цих замовлень;
-- успішні платежі — сума платежів за цими замовленнями з типом payment і статусом succeeded.
-- Відсортуйте за кодом країни і назвою показника.

-- ℹ️ Підказка. Таблиці shop.order_items і shop.payments обидві повʼязані із замовленням звʼязком «один до багатьох». Якщо зʼєднати їх із замовленнями в одному SELECT, рядки розмножаться і суми завищаться. Рахуйте кожен показник окремим запитом на власному рівні деталізації.

-- РЕЗУЛЬТАТ.
-- Шість рядків: три показники для кожної з двох країн.
-- Колонки: 
-- country_code, metric, amount.

select
    oo.country_code,
    'Сума замовлень' as "metric",
    sum(oo.total_amount) as "amount"
from shop.orders as oo
where oo.created_at >= '2025-12-01' and oo.created_at < '2026-01-01'
group by oo.country_code

union all

select
    oo.country_code,
    'Сума позицій' as "metric",
    sum(oi.quantity * oi.unit_price) as "amount"
from shop.orders as oo
join shop.order_items as oi on oo.order_id = oi.order_id
where oo.created_at >= '2025-12-01' and oo.created_at < '2026-01-01'
  and oi.quantity is not null
  and oi.unit_price is not null
group by oo.country_code

union ALL

select
    oo.country_code,
    'Сума успішних платежів' as "metric",
    sum(pp.amount) as "amount"
from shop.orders as oo
join shop.payments as pp on oo.order_id = pp.order_id
where oo.created_at >= '2025-12-01' and oo.created_at < '2026-01-01'
  and pp.status = 'succeeded'
group by oo.country_code

order by country_code, "metric";  
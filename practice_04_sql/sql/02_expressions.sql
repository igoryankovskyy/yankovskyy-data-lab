SET TIME ZONE 'UTC';


-- Завдання 4.2.1. 
-- Графік розстрочки

-- Фінансовий відділ планує надходження від польських розстрочок, оформлених у грудні 2025 року.
-- Виберіть із shop.orders замовлення з Польщі, оформлені в розстрочку і створені у грудні 2025 року, і додайте колонки:
-- order_label — текст виду Замовлення № 12345, де число — ідентифікатор замовлення;
-- order_date — дата створення замовлення без часу;
-- monthly_payment — сума одного внеску: сума замовлення, поділена на кількість внесків, з округленням до двох знаків після коми;
-- term_years — строк розстрочки в роках з округленням до двох знаків після коми;
-- term_group — короткий до 4 внесків включно, середній для 5 або 6 внесків, довгий для решти.
-- Відсортуйте за monthly_payment за спаданням, за однакового внеску — за order_id.

-- ℹ️ Підказка. Колонка installments_count цілочисельна.
-- Ділення цілого числа на ціле в PostgreSQL відкидає дробову частину.
-- РЕЗУЛЬТАТ. 
-- Один рядок — одне замовлення.
-- Колонки:
-- order_id, order_label, order_date, total_amount, installments_count, monthly_payment, term_years, term_group.

select 
    oo.order_id,
    'Замовлення № ' || oo.order_id as order_label,
    oo.created_at::date as "Дата замовлення",
    oo.total_amount as "Сума замовлення",
    oo.installments_count as "Кількість внесків",
    round(1.0 * oo.total_amount / oo.installments_count, 2) as "Сума одного внеску",
    round(oo.installments_count / 12.0, 2) as "Строк розстрочки (р.)",
    case 
        when oo.installments_count <= 4 then 'короткий'
        when oo.installments_count in (5, 6) then 'середній'
        else 'довгий'
    end as "Термін розстрочки" 
from shop.orders as oo
where oo.country_code = 'PL'
    and oo.payment_method = 'installments'
    and oo.created_at >= '2025-12-01' and oo.created_at < '2026-01-01'
order by "Сума одного внеску" desc, oo.order_id;


-- Завдання 4.2.2. Стан відправлень

-- Служба доставки хоче бачити, що відбувається з посилками передноворічного тижня:
-- де кожна з них зараз і скільки днів їхала.
-- Виберіть із shop.shipments відправлення, створені з 25 по 31 грудня 2025 року, і додайте колонки:
-- shipped_date — дата відправлення без часу;
-- transit_days — днів від дати відправлення до дати прибуття (порожньо, якщо ще не прибуло);
-- state — повернено, отримано, очікує отримання, у дорозі або не відправлено, за останньою подією;
-- last_event_at — час останньої події
-- (перше заповнене значення з returned_at, received_at, arrived_at, shipped_at, created_at).
-- Відсортуйте від найсвіжішої події до найдавнішої, за однакового часу — за shipment_id.

-- ℹ️ Підказка.
-- В отриманого відправлення заповнено водночас і shipped_at, і arrived_at, і received_at.
-- Умови CASE перевіряються згори донизу, і спрацьовує перша істинна.

-- РЕЗУЛЬТАТ.
-- Один рядок — одне відправлення.
-- Колонки:
-- shipment_id, order_id, tracking_number, shipped_date, transit_days, state, last_event_at.

select ss.shipment_id as "Відправлення №",
    ss.order_id as "Замовлення №", 
    ss.created_at as "Дата створення",
    ss.tracking_number as "Трек-номер", 
    ss.shipped_at::date as "Дата відправлення",
    (ss.arrived_at::date - ss.shipped_at::date) as "Тривалість транзиту",
    case 
        when ss.returned_at is not null then 'повернено'
        when ss.received_at is not null then 'отримано'
        when ss.arrived_at is not null then 'прибуло'
        when ss.shipped_at is not null then 'відправлено'
        else 'не відправлено'
    end as "Стан замовлення",
    coalesce(ss.returned_at, ss.received_at, ss.arrived_at, ss.shipped_at, ss.created_at) as "Час останньої події"
from shop.shipments as ss
where ss.created_at >= '2025-12-01' and ss.created_at < '2026-01-01'
-- order by "Час останньої події" desc, ss.shipment_id;
order by 3 desc, 1;


-- Завдання 4.2.3. Контакти нових покупців

-- Маркетинг готує окрему розсилку для нових українських покупців із поштою на ukr.net і тих, хто пошти не вказав.
-- Виберіть із shop.customers покупців з України, які зареєструвалися у грудні 2025 року і мають пошту в домені
-- ukr.net (незалежно від регістру літер) або не мають її зовсім, і додайте колонки:
-- full_name — імʼя, пробіл і прізвище великими літерами;
-- contact — електронна пошта, а якщо її немає — телефон;
-- contact_type — email або телефон, залежно від того, що потрапило в contact;
-- birth_year — рік народження цілим числом;
-- days_registered — днів від дати реєстрації до дня запуску запиту.
-- Відсортуйте за часом реєстрації від найдавнішої, за однакового часу — за customer_id.

-- РЕЗУЛЬТАТ.
-- Один рядок — один покупець.
-- Колонки:
-- customer_id, full_name, contact, contact_type, birth_year, days_registered.

select 
    cc.customer_id as "ID", 
    upper(cc.first_name || ' ' || cc.last_name) as "ПІБ", 
    coalesce(cc.email, cc.phone) as "Контакт", 
    case 
        when cc.email is not null then 'email'
        else 'телефон'
    end as "Тип контакту",
    date_part('year', cc.birth_date) as "Рік народження",
    (current_date - cc.registered_at::date) as "Днів з реєстрації"
from shop.customers as cc
where cc.country_code = 'UA'
    and cc.registered_at >= '2025-12-01' and cc.registered_at < '2026-01-01'
    and (cc.email ilike '%@ukr.net' or cc.email is null)
order by cc.registered_at, cc.customer_id;




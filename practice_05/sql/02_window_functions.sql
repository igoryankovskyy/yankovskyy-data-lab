SET TIME ZONE 'UTC'

-- Завдання 2.1. Частка замовлення в денній виручці

-- Маркетинг хоче бачити, яку частку денної виручки дало кожне замовлення на початку грудневого розпродажу.

-- Виберіть із shop.orders замовлення з Польщі, створені з 1 по 3 грудня 2025 року включно, без скасованих,
-- і додайте колонки:
-- order_date — дата створення без часу;
-- day_amount — сума всіх вибраних замовлень того самого дня;
-- share_pct — частка замовлення в day_amount у відсотках з округленням до двох знаків після коми.
-- Відсортуйте за датою, у межах дня — за share_pct за спаданням, за однакової частки — за order_id.

-- РЕЗУЛЬТАТ
-- Один рядок — одне замовлення.
-- Колонки:
-- order_id, order_date, total_amount, day_amount, share_pct.

select 
    order_id,
    created_at::date as order_date,
    total_amount,
    sum(total_amount) over(partition by created_at::date) as day_amount,
    round(100*total_amount / sum(total_amount) over (partition by created_at::date), 2) as share_pct
from shop.orders
where 
    country_code = 'PL'
    and status <> 'cancelled'
    and created_at >='2025-12-01' and created_at < '2025-12-04'
order by order_date, share_pct desc, order_id;


-- Завдання 2.2. Виручка від початку місяця

-- Фінансовий відділ стежить, як у грудні 2025 року наростала виручка в кожній країні.

-- За замовленнями з shop.orders, створеними у грудні 2025 року,
-- без скасованих, порахуйте для кожної країни і кожного дня:
-- order_date — дата без часу;
-- amount — сума замовлень країни за день;
-- running_amount — сума замовлень країни від 1 грудня до цього дня включно.
-- Відсортуйте за кодом країни і датою.

-- РЕЗУЛЬТАТ.
-- Отримати на виході.
-- Один рядок — одна країна за один день.
-- Колонки: country_code, order_date, amount, running_amount.


with day_orders as (
    select 
        country_code,
        created_at::date as order_date,
        sum(total_amount) as amount 
    from shop.orders
    where created_at >= '2025-12-01' and created_at < '2026-01-01'
        and status <> 'cancelled'
    group by country_code, order_date
)
select 
    country_code,
    order_date,
    amount,
    sum (amount) over (partition by country_code order by order_date) as running_total
from day_orders
order by country_code, order_date;



-- Завдання 2.3. Ковзне середнє за тиждень

-- Аналітик продажів хоче бачити тенденцію польської виручки у грудні 2025 року без щоденних коливань.

-- За замовленнями з Польщі зі shop.orders,
-- створеними у грудні 2025 року,
-- без скасованих,
-- порахуйте для кожного дня:
-- order_date — дата без часу;
-- amount — сума замовлень за день;
-- avg_7d — середнє значення amount за цей день і шість попередніх днів з округленням до двох знаків після коми (для 1–6 грудня — за наявні дні, починаючи з 1 грудня).
-- Відсортуйте за датою.

-- РЕЗУЛЬТАТ.
-- Один рядок — один день.
-- Колонки:
-- order_date, amount, avg_7d.

with day_orders as (
    select 
        created_at::date as order_date,
        sum(total_amount) as amount 
    from shop.orders
    where created_at >= '2025-12-01' and created_at < '2026-01-01'
        and status <> 'cancelled'
        and country_code = 'PL'
    group by order_date
)
select 
    order_date,
    amount,
    round(avg(amount) over (order by order_date ROWS BETWEEN 6 PRECEDING and current row), 2) as avg_7d
from day_orders
order by order_date;


-- Завдання 2.4. Перша й остання ціна року

-- Відділ ціноутворення порівнює, як змінювалися ціни планшетів у Польщі впродовж 2025 року.

-- Виберіть із shop.product_prices записи про ціни в Польщі
-- товарів категорії «Планшети» (category_id = 9)
-- з датою valid_from у 2025 році,
-- без записів із порожньою ціною,
-- і додайте колонки:
-- first_price — ціна з найранішого вибраного запису цього товару;
-- last_price — ціна з найпізнішого вибраного запису цього товару.
-- Відсортуйте за product_id і valid_from.

-- ℹ️ Підказка. Перевірте результат на товарі з кількома записами: 
-- first_price і last_price мають бути однаковими в усіх його рядках.

-- РЕЗУЛЬТАТ.
-- Один рядок — один запис про ціну.
-- Колонки:
-- product_id, valid_from, price, first_price, last_price.

select 
    pp.product_id,
    valid_from,
    price,
    first_value(price) over (partition by pp.product_id order by valid_from) as first_price,
    first_value(price) over (partition by pp.product_id order by valid_from desc) as last_price 
from shop.product_prices as pp
join shop.products as pid
on pp.product_id = pid.product_id
where 
    country_code = 'PL'
    and category_id = 9
    and valid_from >= '2025-01-01' and valid_from < '2026-01-01'
    and price is not NULL
order by pp.product_id, valid_from


-- Завдання 2.5. Рейтинг ноутбуків за вагою

-- Маркетинг готує добірку найлегших ноутбуків і хоче показати місце кожного за вагою.

-- Виберіть із shop.products товари категорії «Ноутбуки» (category_id = 8)
-- і додайте колонки:
-- weight_rank — місце за вагою від найлегшого: однакова вага — однакове місце,
-- а після групи однакових значень номери пропускаються (1, 2, 2, 4);
-- weight_dense_rank — місце за вагою від найлегшого
-- без пропусків після однакових значень (1, 2, 2, 3).
-- Відсортуйте за вагою, за однакової ваги — за product_id.

-- РЕЗУЛЬТАТ.
-- Один рядок — один товар.
-- Колонки:
-- product_id, name, weight_kg, weight_rank, weight_dense_rank.

SELECT
    product_id,
    name,
    weight_kg,
    RANK() over (order by weight_kg) as weight_rank,
    DENSE_RANK() over (order by weight_kg) as weight_dense_rank
from shop.products
where category_id = 8
order by weight_kg, product_id;


-- Завдання 2.6. Зміна виручки від місяця до місяця

-- Фінансовий відділ порівнює виручку кожного місяця 2025 року з попереднім місяцем.

-- За замовленнями з shop.orders, створеними у 2025 році, без скасованих,
-- порахуйте для кожної країни і кожного місяця:
-- month — перший день місяця, дата без часу;
-- amount — сума замовлень за місяць;
-- prev_amount — сума замовлень цієї країни за попередній місяць (порожньо для січня);
-- change_pct — зміна amount відносно prev_amount у відсотках
-- з округленням до одного знака після коми (порожньо для січня).

-- Відсортуйте за кодом країни і місяцем.

-- РЕЗУЛЬТАТ.
-- Один рядок — одна країна за один місяць.
-- Колонки:
-- country_code, month, amount, prev_amount, change_pct.

with 
    month_orders as (
        select 
            country_code, 
            date_trunc('month', created_at)::date as "month",
            sum(total_amount) as amount
        from shop.orders
        where 
            created_at >= '2025-01-01' and created_at < '2026-01-01'
            and status != 'cancelled'
        group by country_code, date_trunc('month', created_at)
    )
SELECT
    country_code,
    month,
    amount,
    lag(amount) over(partition by country_code order by month) as prev_amount,
    round(100 * amount / lag(amount) over(partition by country_code order by month) - 100, 1) as change_pct
FROM 
    month_orders
order by country_code, "month"


-- Завдання 2.7. Три найпопулярніші товари кожної категорії

-- Відділ закупівель планує поставки на основі грудневих продажів в Україні.

-- За позиціями shop.order_items українських замовлень, створених у грудні 2025 року, без скасованих,
-- виберіть у кожній категорії три товари з найбільшою кількістю проданих одиниць:
-- units_sold — сума quantity товару в цих замовленнях;
-- place — місце товару в категорії від 1 до 3; за однакової кількості вище стоїть товар із меншим product_id;
-- у категорії, де продано менше трьох різних товарів, — стільки рядків, скільки товарів продано.
-- Відсортуйте за category_id і place.

-- РЕЗУЛЬТАТ.
-- Один рядок — один товар.
-- Колонки:
-- category_id, category_name, place, product_id, product_name, units_sold.

with
    monthly_products as (
        select
            oi.product_id,
            sum(oi.quantity) as units_sold
        from shop.order_items as oi
        join shop.orders as oo
            on oi.order_id = oo.order_id
        where
            oo.country_code = 'UA'
            and oo.created_at >= '2025-12-01'
            and oo.created_at < '2026-01-01'
            and oo.status <> 'cancelled'
        group by oi.product_id
    ),
    ranked_products as (
        select
            cc.category_id,
            cc.name as category_name,
            row_number() over (
                partition by cc.category_id
                order by mp.units_sold desc, mp.product_id
            ) as place,
            mp.product_id,
            pp.name as product_name,
            mp.units_sold
        from monthly_products as mp
        join shop.products as pp
            on pp.product_id = mp.product_id
        join shop.categories as cc
            on cc.category_id = pp.category_id
    )
select
    category_id,
    category_name,
    place,
    product_id,
    product_name,
    units_sold
from ranked_products
where place <= 3
order by category_id, place;



-- Завдання 2.8. Останній оплачений внесок розстрочки

-- Фінансовий відділ хоче бачити, до якого внеску дійшов кожен покупець,
-- що оформив розстрочку в жовтні 2025 року.

-- Для замовлень з Польщі зі shop.orders,
-- оформлених у розстрочку (installments) і створених у жовтні 2025 року,
-- виберіть із shop.payments останній успішний платіж
-- (тип payment, статус succeeded) кожного замовлення:
-- останнім вважається платіж із найпізнішим created_at,
-- за однакового часу — з більшим payment_id;
-- замовлення без жодного успішного платежу в результат не потрапляють.
-- Відсортуйте за order_id.

-- РЕЗУЛЬТАТ.
-- Один рядок — одне замовлення.
-- Колонки:
-- order_id, payment_id, installment_no, amount, created_at.

-- РІШЕННЯ ЧЕРЕЗ DISTINCT ON ()

with ins_orders as (
    select order_id
    from shop.orders
    where
        country_code = 'PL'
        and created_at >= '2025-10-01'
        and created_at < '2025-11-01'
        and payment_method = 'installments'
)
select distinct on (pp.order_id)
    pp.order_id,
    pp.payment_id,
    pp.installment_no,
    pp.amount,
    pp.created_at
from ins_orders as oo
join shop.payments as pp
    on pp.order_id = oo.order_id
where
    pp.payment_type = 'payment'
    and pp.status = 'succeeded'
order by
    pp.order_id,
    pp.created_at desc,
    pp.payment_id desc;


-- РІШЕННЯ ЧЕРЕЗ ROW_NUMBER()

with ins_orders as (
    select order_id
    from shop.orders
    where
        country_code = 'PL'
        and created_at >= '2025-10-01'
        and created_at < '2025-11-01'
        and payment_method = 'installments'
),
ranked_payments as (
    select
        pp.order_id,
        pp.payment_id,
        pp.installment_no,
        pp.amount,
        pp.created_at,
        row_number() over (
            partition by pp.order_id
            order by pp.created_at desc, pp.payment_id desc
        ) as rn
    from ins_orders as oo
    join shop.payments as pp
        on pp.order_id = oo.order_id
    where
        pp.payment_type = 'payment'
        and pp.status = 'succeeded'
)
select
    order_id,
    payment_id,
    installment_no,
    amount,
    created_at
from ranked_payments
where rn = 1
order by order_id;



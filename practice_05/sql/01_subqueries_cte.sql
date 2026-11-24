SET TIME ZONE 'UTC';


-- Завдання 5.1.1. Найбільші замовлення місяця

-- Фінансовий відділ перевіряє нетипово великі польські замовлення 
-- грудня 2025 року.

-- Виберіть із shop.orders замовлення з Польщі,
-- створені у грудні 2025 року,
-- сума яких більш ніж упʼятеро перевищує середню суму всіх польських замовлень цього місяця незалежно від статусу,
-- і додайте колонку:
-- avg_amount — ця середня сума з округленням до двох знаків після коми.
-- Відсортуйте за сумою замовлення за спаданням, за однакової суми — за order_id.

-- РЕЗУЛЬТАТ.  
-- Один рядок — одне замовлення. 
-- Колонки:
-- order_id, created_at, total_amount, avg_amount.

with avg_amount_cte as (
    select round(avg(total_amount), 2) as avg_amount
    from shop.orders
    where country_code = 'PL'
      and created_at >= '2025-12-01' and created_at < '2026-01-01'
)
select 
    oo.order_id,
    oo.created_at,
    oo.total_amount,
    a.avg_amount
from shop.orders as oo
cross join avg_amount_cte as a          
where oo.country_code = 'PL'
  and oo.created_at >= '2025-12-01' and oo.created_at < '2026-01-01'
  and oo.total_amount > 5 * a.avg_amount
order by oo.total_amount desc, oo.order_id; 


-- Завдання 5.1.2.1. Повторні покупки за рік (СТАРА РЕДАКЦІЯ ОПИСУ)

-- Маркетинг оцінює, як часто покупці повертаються по нову покупку протягом року.
-- За замовленнями з shop.orders, створеними у 2025 році незалежно від статусу, порахуйте для кожної країни:
-- customers_cnt — кількість покупців, які мають хоча б одне таке замовлення;
-- repeat_customers_cnt — кількість покупців із двома і більше такими замовленнями;
-- avg_orders — середня кількість таких замовлень на одного покупця з customers_cnt,
-- з округленням до двох знаків після коми.
-- Відсортуйте за кодом країни.

-- ℹ️ Підказка. Спершу потрібна кількість замовлень кожного покупця,
-- і вже з цих кількостей рахуються показники країни.

-- РЕЗУЛЬТАТ.  
-- Один рядок — одна країна.
-- Колонки:
-- country_code, customers_cnt, repeat_customers_cnt, avg_orders.

with customer_orders as (
    select 
        country_code,
        customer_id, 
        count(*) as "orders_cnt"
    from shop.orders
    group by country_code, customer_id
    having count(*) >= 2
)
select
    country_code,
    count(distinct customer_id) as "customers_cnt",
    count(distinct case when customer_orders.orders_cnt >= 3 then customer_id end) as "repeat_customers_cnt",
    round(avg(customer_orders.orders_cnt) - 1, 2) as "avg_orders"   
from customer_orders
group by country_code
order by country_code;


-- Завдання 5.1.2.2. Повторні покупки за рік (НОВА РЕДАКЦІЯ)

-- Маркетинг оцінює, як часто покупці повертаються по нову покупку протягом року.
-- За замовленнями з shop.orders, створеними у 2025 році незалежно від статусу, 
-- порахуйте для кожної країни:
-- customers_cnt — кількість покупців, які мають хоча б одне замовлення 2025 року;
-- repeat_customers_cnt — кількість покупців, які мають два чи більше замовлень 2025 року (покупець з одним замовленням сюди не входить);
-- avg_orders — середня кількість замовлень на покупця
-- з округленням до двох знаків після коми.
-- Відсортуйте за кодом країни.

-- РЕЗУЛЬТАТ.  
-- Один рядок — одна країна.
-- Колонки:
-- country_code, customers_cnt, repeat_customers_cnt, avg_orders.

with customer_orders as (
    select 
        country_code,
        customer_id,
        count(*) as orders_cnt
    from shop.orders
    where created_at >= '2025-01-01' and created_at < '2026-01-01'
    group by country_code, customer_id
    having count(*) >= 1
    )
select
    country_code,
    count(*) as "customers_cnt",
    count(*) filter (where orders_cnt >= 2) as "repeat_customers_cnt",
    round(avg(customer_orders.orders_cnt), 2) as "avg_orders"
from customer_orders
group by country_code
order by country_code;   



-- Завдання 5.1.3. Покупці з поверненими посилками
-- Служба підтримки обдзвонює покупців, чиї посилки повернулися відправнику, щоб зʼясувати причину.

-- Виберіть із shop.customers покупців,
-- які мають хоча б одне замовлення з України зі статусом returned_to_sender,
-- створене в листопаді 2025 року.
-- Відсортуйте за customer_id.

-- РЕЗУЛЬТАТ.
-- Один рядок — один покупець, навіть якщо в нього більше одного такого замовлення.
-- Колонки:
-- customer_id, first_name, last_name, phone.

select customer_id, first_name, last_name, phone 
from customers
where customer_id in (
    SELECT
        distinct customer_id
    from shop.orders
    WHERE 1=1
        and country_code = 'UA'
        and status = 'returned_to_sender'
        and created_at >= '2025-11-01' and created_at < '2025-12-01'
)
order by customer_id;


-- Завдання 5.1.4. Товари, важчі за середній у своїй категорії

-- Склад розміщує на нижніх полицях ноутбуки й планшети,
-- важчі за типовий товар своєї категорії.
-- Виберіть із shop.products товари категорій «Ноутбуки» (category_id = 8) і «Планшети» (category_id = 9),
-- вага яких більша за середню вагу товарів тієї самої категорії,
-- і додайте колонку:
-- category_avg_weight — середня вага товарів категорії з округленням до трьох знаків після коми.
-- Відсортуйте за category_id,
-- потім за вагою за спаданням,
-- за однакової ваги — за product_id.

-- РЕЗУЛЬТАТ
-- Один рядок — один товар.
-- Колонки:
-- product_id, sku, name, category_id, weight_kg, category_avg_weight.


with avg_weight_cte as (
    SELECT
        category_id,
        round(avg(weight_kg), 3) as category_avg_weight
    from shop.products
    group by category_id
)
SELECT
    product_id,
    sku,
    name,
    pp.category_id,
    weight_kg,
    category_avg_weight
from shop.products as pp
join avg_weight_cte as cte
on pp.category_id = cte.category_id
WHERE 1=1
    and pp.category_id in (8, 9)
    and weight_kg > category_avg_weight
order by pp.category_id, weight_kg desc, product_id;


-- Завдання 1.5. Точки видачі без замовлень

-- Служба доставки шукає в Ужгороді точки видачі,
-- куди у грудні 2025 року не надійшло жодного замовлення.

-- Виберіть із shop.pickup_points точки видачі населеного пункту з назвою Ужгород у shop.cities,
-- для яких немає жодного замовлення, створеного у грудні 2025 року з доставкою в цю точку.
-- Відсортуйте за point_id.
-- ℹ️ Підказка.
-- У курʼєрських замовлень pickup_point_id порожній.
-- Переконайтеся, що ці NULL не роблять результат порожнім.

-- РЕЗУЛЬТАТ
-- Один рядок — одна точка видачі.
-- Колонки:
-- point_id, point_type, number, address.

select
    pp.point_id, 
    pp.point_type, 
    count(oo.order_id) as number,
    pp.address
from shop.pickup_points as pp
left join (
    select order_id, pickup_point_id
    from shop.orders
    where created_at >= '2025-12-01' and created_at < '2026-01-01'
) as oo
on oo.pickup_point_id = pp.point_id
where 
    pp.city_id in (select city_id from cities where name ilike 'Ужгород') 
group by pp.point_id, oo.pickup_point_id
having count(oo.order_id) = 0
order by pp.point_id;


-- Альтернативний запит від ШІ
select
    pp.point_id,
    pp.point_type,
    0 as number,
    pp.address
from shop.pickup_points as pp
join cities as c
    on c.city_id = pp.city_id
where c.name ilike 'Ужгород'
    and not exists (
        select 1
        from shop.orders as oo
        where oo.pickup_point_id = pp.point_id
            and oo.created_at >= '2025-12-01'
            and oo.created_at < '2026-01-01'
    )
order by pp.point_id;


-- Завдання 1.6. Дні з продажами вище середнього

-- Фінансовий відділ хоче знати,
-- у які дні грудня 2025 року польські продажі перевищили середньоденний рівень.

-- За замовленнями з Польщі зі shop.orders,
-- створеними у грудні 2025 року, без скасованих (cancelled),
-- порахуйте показники кожного дня
-- і залиште дні, денна сума яких більша за середню денну суму грудня:

-- order_date — дата без часу;
-- orders_cnt — кількість замовлень за день;
-- amount — сума замовлень за день;
-- avg_daily_amount — середнє значення amount за всі дні грудня з округленням до двох знаків після коми.
-- Відсортуйте за датою.

-- РЕЗУЛЬТАТю
-- Один рядок — один день.
-- Колонки:
-- order_date, orders_cnt, amount, avg_daily_amount.

with dec_2025_orders as (
    SELECT
        created_at::date as order_date,
        count(order_id) as orders_cnt,
        sum(total_amount) as amount
    from shop.orders
    where
        country_code = 'PL'
        and created_at >= '2025-12-01' and created_at < '2026-01-01'
        and status <> 'cancelled'
    group by order_date
),
avg_amount as (
    select round(avg(amount), 2) as avg_daily_amount
    from dec_2025_orders
)
select
    order_date,
    orders_cnt,
    amount,
    avg_daily_amount
from dec_2025_orders
cross join avg_amount
where amount > avg_daily_amount
order by order_date;
    


-- Завдання 1.7.1. Товари в розділах каталогу

-- Відділ закупівель хоче знати,
-- скільки товарів у кожному розділі каталогу разом з усіма вкладеними підкатегоріями.

-- Для кожного розділу каталогу — категорії зі shop.categories,
-- батьківська категорія якої є кореневою (має порожній parent_id), 
-- порахуйте:
-- products_cnt — кількість товарів зі shop.products, привʼязаних до самого розділу
--      або до його підкатегорій на всіх рівнях вкладеності.
-- Відсортуйте за products_cnt за спаданням, за однакової кількості — за section_id.

-- ℹ️ Підказка. Гілки дерева категорій мають різну глибину, 
-- і з часом у ньому можуть зʼявитися нові рівні.
-- Запит має рахувати правильно за довільної кількості рівнів,
-- тому кількість зʼєднань у ньому не має залежати від глибини дерева.

-- РЕЗУЛЬТАТ.
-- Один рядок — один розділ.
-- Колонки:
-- section_id, section_name, products_cnt, де section_id і section_name — ідентифікатор і назва розділу.


WITH RECURSIVE sections AS (
    SELECT
        c.category_id AS section_id,
        c.name AS section_name
    FROM shop.categories AS c
    JOIN shop.categories AS parent
        ON parent.category_id = c.parent_id
    WHERE parent.parent_id IS NULL
),
section_categories AS (
    -- Сам розділ
    SELECT
        section_id,
        section_name,
        section_id AS category_id
    FROM sections
    UNION ALL
    -- Усі вкладені категорії
    SELECT
        sc.section_id,
        sc.section_name,
        child.category_id
    FROM section_categories AS sc
    JOIN shop.categories AS child
        ON child.parent_id = sc.category_id
)
SELECT
    s.section_id,
    s.section_name,
    COUNT(p.product_id) AS products_cnt
FROM sections AS s
LEFT JOIN section_categories AS sc
    ON sc.section_id = s.section_id
LEFT JOIN shop.products AS p
    ON p.category_id = sc.category_id
GROUP BY
    s.section_id,
    s.section_name
ORDER BY
    products_cnt DESC,
    s.section_id;


-- Завдання 1.7.2. Альтернативне рішення.
-- Підрахунок товарів у ВСІХ категоріях

WITH RECURSIVE category_tree AS (
    -- всі категорії можуть мати власні товари
    SELECT category_id AS child_id,
           category_id AS ancestor_id
    FROM shop.categories
    -- якщо у категорій нема власних товарів 
    -- SELECT category_id AS child_id,
    --        parent_id   AS ancestor_id
    -- FROM shop.categories
    -- WHERE parent_id IS NOT NULL
    UNION ALL   -- або UNION, якщо в даних можливі цикли
    SELECT c.category_id,
           t.ancestor_id
    FROM category_tree AS t
    JOIN shop.categories AS c
      ON c.parent_id = t.child_id
),
product_counts AS (
    SELECT category_id, count(*) AS qty
    FROM shop.products
    GROUP BY category_id
)
SELECT
    t.ancestor_id AS parent_id,
    cc.name,
    coalesce(sum(pc.qty), 0) AS product_cnt
FROM category_tree AS t
LEFT JOIN product_counts AS pc
  ON pc.category_id = t.child_id
left join categories as cc on t.ancestor_id = cc.category_id
GROUP BY t.ancestor_id, cc.name
ORDER BY t.ancestor_id;



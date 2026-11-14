

-- Завдання 4.4.1. Продажі брендів

-- Відділ закупівель вирішує, які бренди дозамовити, за підсумками четвертого кварталу 2025 року.

-- Для кожної країни і кожного бренду
-- порахуйте за позиціями замовлень зі статусом received,
-- створених у четвертому кварталі 2025 року (жовтень–грудень):
-- country — назва країни з shop.countries;
-- brand — назва бренду з shop.brands;
-- orders_cnt — кількість різних замовлень із товарами бренду;
-- units_sold — кількість проданих одиниць товару;
-- revenue — виручка: сума добутків кількості на ціну одиниці.
-- Відсортуйте за назвою країни,
-- у межах країни — за виручкою за спаданням,
-- за однакової виручки — за назвою бренду.

-- РЕЗУЛЬТАТ.
-- Один рядок — один бренд в одній країні. 
-- Колонки:
-- country, brand, orders_cnt, units_sold, revenue.

select 
    cc.name as "Країна",
    bb.name as "Бренд",
    count(distinct oo.order_id) as "Кількість замовлень",
    sum(oi.quantity) as "Кількість проданих одиниць",
    sum(oi.quantity * oi.unit_price) as "Виручка"
from shop.order_items as oi
join shop.orders as oo on oi.order_id = oo.order_id
join shop.products as pp on oi.product_id = pp.product_id
join shop.brands as bb on pp.brand_id = bb.brand_id
join shop.countries as cc on oo.country_code = cc.country_code
where oo.status = 'received'
    and oo.created_at >= '2025-10-01' and oo.created_at < '2026-01-01'
group by cc.name, bb.name
order by cc.name, "Виручка" desc, bb.name;  


-- Завдання 4.4.2. Товари без продажів

-- Склад шукає товари, які жодного разу не продалися, щоб вирішити, чи лишати їх в асортименті.

-- Виберіть із shop.products товари, яких немає в жодній позиції жодного замовлення, і додайте колонки:
-- brand — назва бренду товару;
-- category — назва категорії товару.
-- Відсортуйте за product_id.

-- РЕЗУЛЬТАТ.
-- Один рядок — один товар без продажів.
-- Колонки:
-- product_id, sku, name, brand, category.

select 
    pp.product_id as "ID", 
    pp.sku as "Артикул", 
    pp.name as "Назва", 
    bb.name as "Бренд", 
    cc.name as "Категорія"
from shop.products as pp
join shop.brands as bb on pp.brand_id = bb.brand_id
join shop.categories as cc on pp.category_id = cc.category_id
where pp.product_id not in (
    select distinct oi.product_id
    from shop.order_items as oi
)
order by pp.product_id; 


-- Завдання 4.4.3. Дерево каталогу

-- Контент-менеджер перевіряє структуру каталогу: яка категорія в яку вкладена і де немає товарів.

-- Виведіть усі категорії з shop.categories з колонками:
-- category — назва категорії;
-- parent — назва батьківської категорії (порожньо, якщо батьківської немає);
-- products_cnt — кількість товарів, які належать безпосередньо до цієї категорії (нуль, якщо товарів немає).
-- Відсортуйте за category_id.

-- ℹ️ Підказка. COUNT(*) рахує рядки, а COUNT(колонка) — лише значення, відмінні від NULL.
-- Для групи, якій зовнішнє зʼєднання не знайшло пари, ці два записи дають різний результат.

-- РЕЗУЛЬТАТ.
-- Один рядок — одна категорія, у результаті є всі категорії таблиці.
-- Колонки:
-- category_id, category, parent, products_cnt.

select 
    cc.category_id as "ID", 
    cc.name as "Категорія", 
    pp.name as "Батьківська категорія",
    count(ppp.product_id) as "Кількість товарів"
from shop.categories as cc
left join shop.categories as pp on cc.parent_id = pp.category_id
left join shop.products as ppp on cc.category_id = ppp.category_id
group by cc.category_id, cc.name, pp.name
order by cc.category_id;    


-- Завдання 4.4.4. Країни і перевізники

-- Логістика переглядає контракти з перевізниками
-- і хоче бачити навантаження кожного з них у кожній країні за грудень 2025 року.

-- Побудуйте всі можливі пари «країна — перевізник» з shop.countries і shop.carriers з колонками:
-- country — назва країни;
-- carrier — назва перевізника;
-- orders_cnt — кількість замовлень цієї країни, створених у грудні 2025 року і доставлених цим перевізником (нуль, якщо замовлень немає).
-- Відсортуйте за назвою країни і назвою перевізника.

-- ℹ️ Підказка.
-- Умова на праву таблицю зовнішнього зʼєднання, записана у WHERE, прибирає рядки без пари.
-- Та сама умова в ON їх зберігає.

-- РЕЗУЛЬТАТ.
-- Один рядок — одна пара країни і перевізника, у результаті є всі пари.
-- Колонки:
-- country, carrier, orders_cnt.

select 
    cc.name as "Країна", 
    cr.name as "Перевізник", 
    count(oo.order_id) as "Кількість замовлень"
from shop.countries as cc
cross join shop.carriers as cr
left join shop.orders as oo
on cc.country_code = oo.country_code
    and cr.carrier_id = oo.carrier_id
    and oo.created_at >= '2025-12-01' and oo.created_at < '2026-01-01'
group by cc.name, cr.name
order by cc.name, cr.name;  


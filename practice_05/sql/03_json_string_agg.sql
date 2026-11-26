SET TIME ZONE 'UTC'


-- Завдання 3.1. Характеристики ноутбуків

-- Контент-менеджер переносить характеристики ноутбуків у таблицю порівняння на сайті.

-- Виберіть із shop.products товари категорії «Ноутбуки» (category_id = 8)
-- і додайте колонки зі значеннями з attributes:
-- processor — значення ключа chip, а якщо його немає — ключа cpu, текстом;
-- ram_gb — обсяг оперативної памʼяті, ціле число;
-- storage_gb — обсяг накопичувача, ціле число;
-- screen_in — діагональ екрана, число з дробовою частиною.
-- Відсортуйте за ram_gb за спаданням, потім за storage_gb за спаданням, за однакових значень — за product_id.

-- РЕЗУЛЬТАТ.
-- Один рядок — один товар.
-- Колонки:
-- product_id, name, processor, ram_gb, storage_gb, screen_in.

SELECT
    product_id,
    name,
    COALESCE(attributes ->> 'chip', attributes ->> 'cpu') as processor,
    attributes ->> 'ram_gb' as ram_gb,
    attributes ->> 'storage_gb' as storage_gb,
    attributes ->> 'screen_in' as screen_in
from shop.products
where category_id = 8;



-- Завдання 3.2. Великі планшети

-- Маркетинг готує добірку планшетів із великим екраном і місткою памʼяттю.

-- Виберіть із shop.products товари категорії «Планшети» (category_id = 9)
-- з діагоналлю екрана від 11 дюймів включно
-- і накопичувачем від 256 ГБ включно
-- та додайте колонки зі значеннями з attributes:
-- chip — процесор, текстом;
-- screen_in — діагональ екрана, число з дробовою частиною;
-- storage_gb — обсяг накопичувача, ціле число.
-- Відсортуйте за screen_in за спаданням, потім за storage_gb за спаданням,
-- за однакових значень — за product_id.

-- ℹ️ Підказка.
-- Серед планшетів є моделі з екраном 8.3 і 8.7 дюйма та з накопичувачем 1024 ГБ.
-- Перевірте, що перші в результат не потрапляють, а другі потрапляють.

-- РЕЗУЛЬТАТ.
-- Один рядок — один товар.
-- Колонки:
-- product_id, name, chip, screen_in, storage_gb.

SELECT
    product_id,
    name,
    attributes ->> 'chip' as chip,
    (attributes ->> 'screen_in')::numeric as screen_in,
    (attributes ->> 'storage_gb')::numeric as storage_gb
FROM    shop.products
where   category_id = 8
    AND (attributes ->> 'screen_in')::numeric >= 11
    AND (attributes ->> 'storage_gb')::numeric >= 256
order BY
    screen_in desc,
    storage_gb DESC,
    product_id;


-- Завдання 3.3. Годинники з мобільним звʼязком

-- Оператор мобільного звʼязку просить список розумних годинників
-- із власною SIM-картою для спільної акції.

-- Виберіть із shop.products товари категорії «Розумні годинники» (category_id = 4),
-- у яких в attributes ключ lte або ключ cellular має значення true,
-- і додайте колонку:
-- color — колір з attributes, текстом.
-- Відсортуйте за product_id.

-- ℹ️ Підказка. У частини годинників ці ключі є, але мають значення false.

-- РЕЗУЛЬТАТ.
-- Один рядок — один товар.
-- Колонки:
-- product_id, name, color.

SELECT  product_id,
        name,
        attributes ->> 'color' as color
        -- ((attributes ->> 'lte')::BOOLEAN OR (attributes ->> 'cellular')::BOOLEAN) as sim
FROM    shop.products
WHERE
        category_id = 4
        AND ((attributes ->> 'lte')::BOOLEAN OR (attributes ->> 'cellular')::BOOLEAN)
order BY    
    product_id;
    


-- Завдання 3.4. Картки зовнішніх SSD для партнера

-- Партнерський маркетплейс приймає каталог як окремий JSON-документ на кожен товар.

-- Для товарів категорії «Зовнішні SSD» (category_id = 22) зі shop.products
-- побудуйте колонку card типу jsonb — JSON-обʼєкт із ключами:
-- sku, name — артикул і назва товару;
-- brand — назва бренду зі shop.brands;
-- storage_gb, read_mbps — обсяг і швидкість читання з attributes, числами JSON (без лапок);
-- interface — інтерфейс з attributes, рядком JSON.
-- Відсортуйте за product_id.

-- РЕЗУЛЬТАТ.
-- Один рядок — один товар.
-- Колонки:
-- product_id, card.

SELECT  product_id,
    jsonb_build_object(
        'sku', sku, 
        'name', pp.name,
        'brand', bb.name,
        'storage_gb', (attributes ->> 'storage_gb')::numeric,
        'read_mbps', (attributes ->> 'read_mbps')::numeric,
        'interface', attributes -> 'interface'
        ) as card
from shop.products as pp
join shop.brands as bb on bb.brand_id = pp.brand_id
where pp.category_id = 22



-- 

-- 1. Відкрийте транзакцію, щоб усі зміни були атомарними.
begin;

-- 2. Створіть таблицю categories з двома колонками: 
-- category_id — первинний ключ, значення видає база; 
-- name — назва категорії, обовʼязкова, у двох категорій не збігається.
create table if not exists categories (
    category_id bigint generated always as identity primary key,
    name varchar(255) not null unique
);

-- 3. Дodайте в таблицю categories пʼять категорій, перелічених в описі файла products.csv.
insert into categories (name)
select distinct category
from products
returning category_id, name;

-- 4. Дoдайте в таблицю products колонку category_id — зовнішній ключ на categories. 
-- Категорію, до якої належить хоча б один товар, видалити не можна.
alter table products 
add column category_id 
    BIGINT 
    REFERENCES categories(category_id)
    ON DELETE NO ACTION; -- 

-- 5. Оновіть таблицю products, заповнивши колонку category_id значеннями з таблиці categories.
update products p
set category_id = c.category_id
from categories c
where p.category = c.name;  

-- 6. Зробіть колонку products.category_id обовʼязковою.
alter table products
alter column category_id set not null;  

-- 7. Видаліть із таблиці products колонку category.
alter table products
drop column category;   

-- 8. Зафіксуйте транзакцію.
commit; 

-- У файлі sql/01_create_tables.sql додайте таблицю categories до команди, 
-- яка видаляє таблиці перед створенням.
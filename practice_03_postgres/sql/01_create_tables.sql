
DROP TABLE IF EXISTS
    customers,
    products,
    orders,
    order_items;

-- таблиця customers
CREATE TABLE customers (
    customer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email       text NOT NULL UNIQUE,
    full_name   text NOT NULL,
    phone       text,
    country     text NOT NULL 
                CHECK (country in ('PL', 'UA')),
    registered_at  timestamptz NOT NULL DEFAULT now()
);

-- таблиця products
CREATE TABLE products (
    product_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku         text NOT NULL UNIQUE,
    name        text NOT NULL,
    brand       text NOT NULL,
    category    text NOT NULL,
    price       numeric(10, 2) NOT NULL CHECK (price > 0),
    stock       integer NOT NULL DEFAULT 0 CHECK (stock >= 0),
    is_active   boolean NOT NULL DEFAULT true,
    attributes  jsonb
);

-- таблиця orders
-- orders	order_id	первинний ключ; для нового замовлення значення видає база
-- orders	customer_id	обовʼязковий; посилається на наявного покупця; покупця, у якого є замовлення, видалити не можна
-- orders	status	    обовʼязковий; лише new, paid, shipped, delivered або cancelled; якщо значення не вказано, записується new
-- orders	created_at	обовʼязковий; якщо значення не вказано, записується момент вставки рядка
CREATE TABLE orders (
    order_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id bigint NOT NULL
                REFERENCES customers (customer_id) ON DELETE RESTRICT,
    status      text NOT NULL DEFAULT 'new'
                CHECK (status IN ('new', 'paid', 'shipped', 'delivered', 'cancelled')),
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- таблиця order_items
-- order_items	order_id	посилається на наявне замовлення; під час видалення замовлення його позиції видаляються разом із ним
-- order_items	product_id	посилається на наявний товар; товар, який є в позиціях замовлень, видалити не можна
-- order_items	unit_price	обовʼязкова; більша за нуль; зберігається без похибки, з копійками
-- order_items	order_id + product_id	первинний ключ: той самий товар трапляється в замовленні лише один раз
-- order_items	quantity	обовʼязкова; більша за нуль
CREATE TABLE order_items (
    order_id    bigint NOT NULL
                REFERENCES orders (order_id) ON DELETE CASCADE,
    product_id  bigint NOT NULL
                REFERENCES products (product_id) ON DELETE RESTRICT,
    PRIMARY KEY (order_id, product_id),
    quantity    integer NOT NULL DEFAULT 0 CHECK (quantity > 0),
    unit_price  numeric(10, 2) NOT NULL CHECK (price > 0)
);

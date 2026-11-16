-- Sample online-shop database for the daily sales report demo.
-- Safe to run again: it drops the tables and creates fresh data
-- for the last 60 days (relative to today), so "yesterday" always has sales.

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;

CREATE TABLE products (
    id        SERIAL PRIMARY KEY,
    name      TEXT NOT NULL,
    category  TEXT NOT NULL,
    price     NUMERIC(10,2) NOT NULL
);

CREATE TABLE orders (
    id            SERIAL PRIMARY KEY,
    order_date    TIMESTAMP NOT NULL,
    customer_name TEXT NOT NULL,
    city          TEXT NOT NULL,
    status        TEXT NOT NULL CHECK (status IN ('delivered', 'pending', 'cancelled'))
);

CREATE TABLE order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INT NOT NULL REFERENCES orders(id),
    product_id  INT NOT NULL REFERENCES products(id),
    quantity    INT NOT NULL,
    unit_price  NUMERIC(10,2) NOT NULL
);

INSERT INTO products (name, category, price) VALUES
    ('Cotton Panjabi',        'Clothing',    1450),
    ('Jamdani Saree',         'Clothing',    6800),
    ('Printed Three-Piece',   'Clothing',    2200),
    ('Kids T-Shirt',          'Clothing',     450),
    ('Leather Wallet',        'Accessories',  850),
    ('Ladies Handbag',        'Accessories', 1950),
    ('Analog Wrist Watch',    'Accessories', 2400),
    ('Wireless Earbuds',      'Electronics', 1850),
    ('Power Bank 10000mAh',   'Electronics', 1500),
    ('Smart Watch',           'Electronics', 3200),
    ('Mezban Masala Pack',    'Food',         350),
    ('Premium Shutki 500g',   'Food',         900);

-- 8 to 25 orders per day for the last 60 days (not including today)
INSERT INTO orders (order_date, customer_name, city, status)
SELECT
    d + (random() * interval '14 hours') + interval '9 hours',
    (ARRAY['Rahim','Karim','Nusrat','Tania','Sakib','Mitu','Arif','Jannat','Rafi','Sumaiya'])[1 + floor(random()*10)::int],
    (ARRAY['Chattogram','Chattogram','Chattogram','Dhaka','Dhaka','Cumilla','Sylhet','Cox''s Bazar'])[1 + floor(random()*8)::int],
    CASE WHEN random() < 0.80 THEN 'delivered'
         WHEN random() < 0.75 THEN 'pending'
         ELSE 'cancelled' END
FROM generate_series(current_date - 60, current_date - 1, interval '1 day') AS d,
     LATERAL generate_series(1, 8 + floor(random()*18)::int + (0 * extract(day from d))::int);

-- 1 to 3 items per order
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.id, p.id, 1 + floor(random()*3)::int, p.price
FROM orders o
CROSS JOIN LATERAL (
    SELECT id, price FROM products
    WHERE o.id IS NOT NULL
    ORDER BY random()
    LIMIT 1 + floor(random()*3)::int
) p;

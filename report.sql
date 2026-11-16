-- Daily sales report: yesterday vs. the day before.
-- Returns ONE row. Paste this into the n8n Postgres node ("Execute Query").
-- Cancelled orders are not counted as sales.

WITH sales AS (
    SELECT
        o.order_date::date        AS day,
        o.id                      AS order_id,
        o.city,
        p.name                    AS product,
        p.category,
        oi.quantity,
        oi.quantity * oi.unit_price AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN products p     ON p.id = oi.product_id
    WHERE o.status <> 'cancelled'
      AND o.order_date::date IN (current_date - 1, current_date - 2)
),
totals AS (
    SELECT
        COALESCE(SUM(revenue)          FILTER (WHERE day = current_date - 1), 0) AS revenue_yesterday,
        COALESCE(SUM(revenue)          FILTER (WHERE day = current_date - 2), 0) AS revenue_day_before,
        COUNT(DISTINCT order_id)       FILTER (WHERE day = current_date - 1)     AS orders_yesterday,
        COUNT(DISTINCT order_id)       FILTER (WHERE day = current_date - 2)     AS orders_day_before
    FROM sales
),
top_products AS (
    SELECT json_agg(t ORDER BY t.revenue DESC) AS list
    FROM (
        SELECT product, SUM(quantity) AS units, SUM(revenue) AS revenue
        FROM sales WHERE day = current_date - 1
        GROUP BY product
        ORDER BY revenue DESC
        LIMIT 5
    ) t
),
by_category AS (
    SELECT json_agg(t ORDER BY t.revenue DESC) AS list
    FROM (
        SELECT category, SUM(revenue) AS revenue
        FROM sales WHERE day = current_date - 1
        GROUP BY category
    ) t
),
by_city AS (
    SELECT json_agg(t ORDER BY t.orders DESC) AS list
    FROM (
        SELECT city, COUNT(DISTINCT order_id) AS orders
        FROM sales WHERE day = current_date - 1
        GROUP BY city
    ) t
),
cancelled AS (
    SELECT COUNT(*) AS cancelled_yesterday
    FROM orders
    WHERE status = 'cancelled' AND order_date::date = current_date - 1
)
SELECT
    to_char(current_date - 1, 'DD Mon YYYY')                      AS report_date,
    t.revenue_yesterday,
    t.revenue_day_before,
    CASE WHEN t.revenue_day_before = 0 THEN NULL
         ELSE ROUND((t.revenue_yesterday - t.revenue_day_before) * 100.0 / t.revenue_day_before, 1)
    END                                                           AS revenue_change_pct,
    t.orders_yesterday,
    t.orders_day_before,
    CASE WHEN t.orders_yesterday = 0 THEN 0
         ELSE ROUND(t.revenue_yesterday / t.orders_yesterday, 0)
    END                                                           AS avg_order_value,
    c.cancelled_yesterday,
    tp.list AS top_products,
    bc.list AS by_category,
    bci.list AS by_city
FROM totals t, top_products tp, by_category bc, by_city bci, cancelled c;

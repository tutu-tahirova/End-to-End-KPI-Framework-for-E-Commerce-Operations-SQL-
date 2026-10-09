-- 1. Məhsullar cədvəli
CREATE TABLE IF NOT EXISTS olist_products (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

-- 2. Müştəri rəyləri cədvəli
CREATE TABLE IF NOT EXISTS olist_order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

-- 3. Satıcılar cədvəli
CREATE TABLE IF NOT EXISTS olist_sellers (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

-- 4. Kateqoriya tərcümə cədvəli
CREATE TABLE IF NOT EXISTS product_category_name_translation (
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT
);

-- Q1.1: Row counts

SELECT 'orders' AS table_name, COUNT(*) AS row_count
FROM orders

UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items

UNION ALL
SELECT 'olist_products', COUNT(*) FROM olist_products

UNION ALL
SELECT 'olist_order_reviews', COUNT(*) FROM olist_order_reviews

UNION ALL
SELECT 'olist_sellers', COUNT(*) FROM olist_sellers

UNION ALL
SELECT 'customers', COUNT(*) FROM customers

UNION ALL
SELECT 'product_category_name_translation',
       COUNT(*)
FROM product_category_name_translation;


-- Q1.2: Orders və order_items kardinallığı
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_id) AS total_items,
    ROUND(
        1.0 * COUNT(oi.order_id)
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS avg_items_per_order
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id;

-- Q2: Analytical base view

DROP VIEW IF EXISTS v_order_analytics;

CREATE VIEW v_order_analytics AS

WITH review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS review_score,
        COUNT(*) AS review_count
    FROM olist_order_reviews
    GROUP BY order_id
)

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,

    p.product_category_name,

    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category_name_english,

    r.review_score,
    COALESCE(r.review_count, 0) AS review_count

FROM orders o

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

LEFT JOIN olist_products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name

LEFT JOIN review_by_order r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered';


--Q3
-- Yalnız order_items və delivered orders üzərindən birbaşa cəm
SELECT 
    'order_items' AS calculation_method,
    SUM(oi.price) AS total_revenue
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'

UNION ALL

-- Bizim yaratdığımız v_order_analytics VIEW-u üzərindən cəm
SELECT 
    'v_order_analytics' AS calculation_method,
    SUM(price) AS total_revenue
FROM v_order_analytics;  --bu iki reqemin eyni cixmasi onu gosterir ki double counting yoxdur 

--Q4
WITH revenue_kpi AS (
    SELECT
        SUM(price) AS total_revenue,
        COUNT(DISTINCT order_id) AS total_orders
    FROM v_order_analytics
),
order_kpi AS (
    SELECT
        order_id,
        MAX(
            julianday(order_delivered_customer_date)
            - julianday(order_purchase_timestamp)
        ) AS delivery_days,
        MAX(review_score) AS review_score
    FROM v_order_analytics
    GROUP BY order_id
),
service_kpi AS (
    SELECT
        AVG(delivery_days) AS avg_delivery_days,
        AVG(review_score) AS avg_review_score
    FROM order_kpi
)
SELECT
    ROUND(r.total_revenue, 2) AS total_revenue,
    ROUND(
        r.total_revenue / NULLIF(r.total_orders, 0), 2
    ) AS average_order_value,
    ROUND(s.avg_delivery_days, 1) AS avg_delivery_days,
    ROUND(s.avg_review_score, 2) AS avg_review_score
FROM revenue_kpi r
CROSS JOIN service_kpi s;

-- Q5: KPI by English product category

WITH category_orders AS (
    SELECT
        order_id,
        product_category_name_english,
        SUM(price) AS category_revenue,
        MAX(
            julianday(order_delivered_customer_date)
            - julianday(order_purchase_timestamp)
        ) AS delivery_days,
        MAX(review_score) AS review_score
    FROM v_order_analytics
    GROUP BY order_id, product_category_name_english
)
SELECT
    product_category_name_english,
    COUNT(*) AS order_count,
    ROUND(SUM(category_revenue), 2) AS total_revenue,
    ROUND(AVG(category_revenue), 2) AS average_order_value,
    ROUND(AVG(delivery_days), 1) AS avg_delivery_days,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM category_orders
GROUP BY product_category_name_english
ORDER BY total_revenue DESC;
  
 
--Q6
--sifarislerin aylar uzre nece paylandigina baxiriq
SELECT STRFTIME('%Y-%m', order_purchase_timestamp) AS order_month,--tarixi il ay formatina saliriq
COUNT(DISTINCT order_id) AS total_orders, 
ROUND(SUM(price), 2) AS total_revenue,
ROUND(SUM(price) / COUNT(DISTINCT order_id), 2) AS aov
FROM v_order_analytics
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY order_month
ORDER BY order_month ASC;


-- Q7.1: Top 5 categories by revenue

WITH category_orders AS (
    SELECT
        order_id,
        product_category_name_english,
        SUM(price) AS category_revenue
    FROM v_order_analytics
    GROUP BY order_id, product_category_name_english
)
SELECT
    product_category_name_english,
    COUNT(*) AS order_count,
    ROUND(SUM(category_revenue), 2) AS total_revenue
FROM category_orders
GROUP BY product_category_name_english
HAVING COUNT(*) >= 100
ORDER BY total_revenue DESC
LIMIT 5;


-- Q7.2: Bottom 5 categories by revenue

WITH category_orders AS (
    SELECT
        order_id,
        product_category_name_english,
        SUM(price) AS category_revenue
    FROM v_order_analytics
    GROUP BY order_id, product_category_name_english
)
SELECT
    product_category_name_english,
    COUNT(*) AS order_count,
    ROUND(SUM(category_revenue), 2) AS total_revenue
FROM category_orders
GROUP BY product_category_name_english
HAVING COUNT(*) >= 100
ORDER BY total_revenue ASC
LIMIT 5;


--Q8
--Ən çox gəlir gətirən top 10 satıcı
SELECT seller_id,
COUNT(DISTINCT order_id) AS total_orders,
COUNT(product_id) AS total_items_sold,
ROUND(SUM(price), 2) AS total_revenue
FROM v_order_analytics
GROUP BY seller_id
ORDER BY total_revenue DESC
LIMIT 10;

--Q9
--çatdırılma zamanı yaranan gecikmələrin analizi
SELECT COUNT(order_id) AS total_delivered_orders,
SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) AS delayed_orders_count, -- Təxmini tarixdən gec çatdırılan sifarişlərin sayı
ROUND(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(order_id), 2) AS delay_percentage,  -- Gecikmə faizi (%)
ROUND(AVG(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date -- Orta gecikmə günü (yalnız gecikən sifarişlər üzrə)
THEN julianday(order_delivered_customer_date) - julianday(order_estimated_delivery_date) END), 1) AS avg_delay_days
FROM v_order_analytics;

-- Q10: Kateqoriyalar üzrə orta çatdırılma müddəti və orta rəy balı
SELECT product_category_name_english, 
COUNT(DISTINCT order_id) AS total_orders,
ROUND(AVG(julianday(order_delivered_customer_date) - julianday(order_purchase_timestamp)), 1) AS avg_delivery_days,
ROUND(AVG(review_score), 2) AS avg_review_score
FROM v_order_analytics
GROUP BY product_category_name_english
HAVING total_orders > 10 -- az sifarişi olan kateqoriyaları filtrləyirik
ORDER BY avg_delivery_days DESC;

--Bonus1
--Hər bir sifariş üzrə vaxtında çatdırılıb-çatdırılmadığını yoxlayırıq (təkrarları önləmək üçün GROUP BY istifadə edirik)
WITH order_delivery_status AS (
    SELECT order_id,
    MAX(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) AS is_on_time
    FROM v_order_analytics
    WHERE order_delivered_customer_date IS NOT NULL 
      AND order_estimated_delivery_date IS NOT NULL
    GROUP BY order_id
)
SELECT 
    COUNT(order_id) AS total_delivered_orders,
    SUM(is_on_time) AS on_time_orders_count,
    ROUND(SUM(is_on_time) * 100.0 / COUNT(order_id), 2) AS on_time_delivery_rate_pct
FROM order_delivery_status;

--bonus2
--rey yazilmamis sifarislerin payi
WITH unique_orders AS (
    SELECT 
        o.order_id,
        MAX(CASE WHEN r.review_score IS NULL THEN 1 ELSE 0 END) AS is_unreviewed
    FROM orders o
    LEFT JOIN olist_order_reviews r ON o.order_id = r.order_id 
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
)
SELECT 
    COUNT(order_id) AS total_delivered_orders,
    SUM(is_unreviewed) AS unreviewed_orders_count,
    ROUND(SUM(is_unreviewed) * 100.0 / COUNT(order_id), 2) AS unreviewed_share_pct
FROM unique_orders;

--bonus3
--burda dasinma xercinin gelire olan nisbetine baxiriq eger 15 % den coxdursa yuksek eroziya olaraq qebul edirik
SELECT product_category_name_english,
ROUND(SUM(price), 2) AS total_revenue,
ROUND(SUM(freight_value), 2) AS total_freight,
ROUND(SUM(freight_value) * 100.0 / SUM(price), 2) AS freight_pct,
CASE WHEN (SUM(freight_value) * 100.0 / SUM(price)) > 15.0 THEN 'High Freight Erosion (Flagged)'
ELSE 'Healthy'
END AS margin_erosion_flag
FROM v_order_analytics
GROUP BY product_category_name_english
ORDER BY freight_pct DESC;

--bonus4
WITH monthly_category_revenue AS (SELECT 
STRFTIME('%Y-%m', order_purchase_timestamp) AS order_month,
product_category_name_english,
SUM(price) AS cat_revenue
FROM v_order_analytics
GROUP BY order_month, product_category_name_english
)
SELECT order_month,
product_category_name_english,
ROUND(cat_revenue, 2) AS category_revenue,
ROUND(cat_revenue * 100.0 / SUM(cat_revenue) OVER (PARTITION BY order_month),2) AS monthly_revenue_pct
FROM monthly_category_revenue
ORDER BY order_month DESC, monthly_revenue_pct DESC;

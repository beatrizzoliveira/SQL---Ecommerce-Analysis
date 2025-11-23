-- Total Orders

SELECT COUNT(*) AS total_orders
FROM customer_orders;

-- Total Clients

SELECT COUNT(DISTINCT customer_id) AS total_clients
FROM customer_orders;

-- Total number of unique products sold

SELECT COUNT(DISTINCT product_id) AS unique_products_sold
FROM customer_orders;

-- Total revenue and quantity sold per product (Top-Selling)
SELECT product_name,
       SUM(quantity) AS total_quantity,
       SUM(quantity * unit_price) AS total_sales
FROM customer_orders
GROUP BY product_name
ORDER BY total_sales DESC;


-- Total revenue and quantity sold per category

SELECT category,
       SUM(quantity) AS total_quantity,
       SUM(quantity * unit_price) AS total_sales
FROM customer_orders
GROUP BY category
ORDER BY total_sales DESC;

-- Count of unique products per category

SELECT category, COUNT(DISTINCT product_id) AS num_products
FROM customer_orders
GROUP BY category
ORDER BY num_products DESC;

-- Average order value
SELECT 
    AVG(order_total) AS avg_order_value
FROM (
    SELECT order_id, SUM(quantity * unit_price) AS order_total
    FROM customer_orders
    GROUP BY order_id
) AS order_totals;

-- Top 10 clients by total spending 

SELECT customer_id, first_name, last_name,
       SUM(quantity * unit_price) AS total_spent
FROM customer_orders
GROUP BY customer_id, first_name, last_name
ORDER BY total_spent DESC
LIMIT 10;

-- Number of customers by age group

SELECT age_group, COUNT(DISTINCT customer_id) AS num_customers
FROM customer_orders
GROUP BY age_group;

-- Number of customers by gender

SELECT gender, COUNT(DISTINCT customer_id) AS num_customers
FROM customer_orders
GROUP BY gender;

-- Number of orders by status

SELECT order_status, COUNT(*) AS num_orders
FROM customer_orders
GROUP BY order_status;

-- Number of orders by payment

SELECT payment_method, COUNT(*) AS num_orders
FROM customer_orders
GROUP BY payment_method;

-- Total revenue by country

SELECT country, SUM(quantity * unit_price) AS total_sales
FROM customer_orders
GROUP BY country
ORDER BY total_sales DESC;

-- Products with low rating and review

SELECT product_name, rating, review_text
FROM customer_orders
WHERE rating <= 2 AND (review_text = 'bad' OR review_text = 'very bad')
ORDER BY rating ASC
LIMIT 10;

-- Number of orders per month

SELECT DATE_TRUNC('month', order_date) AS month, COUNT(*) AS num_orders
FROM customer_orders
GROUP BY month
ORDER BY month;

-- Clients who signed up in the last year

SELECT customer_id, first_name, last_name, signup_date
FROM customer_orders
WHERE signup_date >= CURRENT_DATE - INTERVAL '12 months'
ORDER BY signup_date DESC;

-- Customer ranking by total spending

WITH customer_spending AS (
    SELECT customer_id, first_name, last_name,
           SUM(quantity * unit_price) AS total_spent
    FROM customer_orders
    GROUP BY customer_id, first_name, last_name
)
SELECT customer_id, first_name, last_name, total_spent,
       RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM customer_spending;

-- Top 3 best-selling products per country

WITH country_sales AS (
    SELECT country, product_name,
           SUM(quantity * unit_price) AS total_sales
    FROM customer_orders
    GROUP BY country, product_name
),
ranked_sales AS (
    SELECT country, product_name, total_sales,
           RANK() OVER (PARTITION BY country ORDER BY total_sales DESC) AS rank_in_country
    FROM country_sales
)
SELECT country, product_name, total_sales, rank_in_country
FROM ranked_sales
WHERE rank_in_country <= 3
ORDER BY country, rank_in_country;

-- Month-to-month sales growth

WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', order_date) AS month,
           SUM(quantity * unit_price) AS total_sales
    FROM customer_orders
    GROUP BY month
)
SELECT month,
       total_sales,
       total_sales - LAG(total_sales) OVER (ORDER BY month) AS month_difference,
       ROUND((total_sales - LAG(total_sales) OVER (ORDER BY month)) / LAG(total_sales) OVER (ORDER BY month) * 100, 2) AS growth_pct
FROM monthly_sales;

-- Customer segmentation by spending

WITH customer_totals AS (
    SELECT customer_id,
           SUM(quantity * unit_price) AS total_spent
    FROM customer_orders
    GROUP BY customer_id
)
SELECT customer_id,
       CASE
           WHEN total_spent >= 1000 THEN 'Premium'
           WHEN total_spent >= 500 THEN 'Standard'
           ELSE 'Occasional'
       END AS customer_segment,
       total_spent
FROM customer_totals
ORDER BY total_spent DESC;

-- Top 10 products by average rating

SELECT p.product_id, p.product_name,
       AVG(r.rating) AS avg_rating,
       COUNT(r.review_id) AS num_reviews
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN reviews r ON oi.order_id = r.order_id
GROUP BY p.product_id, p.product_name
ORDER BY avg_rating DESC
LIMIT 10;

-- Total quantity sold per product by country

SELECT c.country, p.product_name, SUM(oi.quantity) AS total_quantity
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.country, p.product_name
ORDER BY c.country, total_quantity DESC;

-- Count of repeat vs one-time customers
WITH customer_order_counts AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS orders_count
    FROM customer_orders
    GROUP BY customer_id
)
SELECT
    CASE 
        WHEN orders_count = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(*) AS num_customers
FROM customer_order_counts
GROUP BY customer_type;

-- Monthly count of new vs returning customers
WITH customer_first_order AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM customer_orders
    GROUP BY customer_id
)
SELECT DATE_TRUNC('month', o.order_date) AS month,
       SUM(CASE WHEN o.order_date = f.first_order_date THEN 1 ELSE 0 END) AS new_customers,
       SUM(CASE WHEN o.order_date > f.first_order_date THEN 1 ELSE 0 END) AS returning_customers
FROM customer_orders o
JOIN customer_first_order f ON o.customer_id = f.customer_id
GROUP BY month
ORDER BY month;

-- Average product rating by customer segment
WITH customer_segment AS (
    SELECT customer_id,
           CASE
               WHEN SUM(quantity * unit_price) >= 1000 THEN 'Premium'
               WHEN SUM(quantity * unit_price) >= 500 THEN 'Standard'
               ELSE 'Occasional'
           END AS segment
    FROM customer_orders
    GROUP BY customer_id
)
SELECT cs.segment, 
       AVG(co.rating) AS avg_rating,
       COUNT(co.review_id) AS num_reviews
FROM customer_orders co
JOIN customer_segment cs ON co.customer_id = cs.customer_id
GROUP BY cs.segment
ORDER BY avg_rating DESC;

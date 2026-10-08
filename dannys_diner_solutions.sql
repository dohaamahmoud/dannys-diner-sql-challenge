CREATE DATABASE DannysDiner;
USE DannysDiner;

/* ===================================================
   8 Week SQL Challenge - Case Study #1: Danny's Diner
   Author : Doha Mahmoud
   Tool   : SQL Server (SSMS)
   Source : https://8weeksqlchallenge.com/case-study-1/
   =================================================== */

CREATE TABLE sales (
    customer_id VARCHAR(1),
    order_date  DATE,
    product_id  INT
);

INSERT INTO sales (customer_id, order_date, product_id) VALUES
('A', '2021-01-01', 1),
('A', '2021-01-01', 2),
('A', '2021-01-07', 2),
('A', '2021-01-10', 3),
('A', '2021-01-11', 3),
('A', '2021-01-11', 3),
('B', '2021-01-01', 2),
('B', '2021-01-02', 2),
('B', '2021-01-04', 1),
('B', '2021-01-11', 1),
('B', '2021-01-16', 3),
('B', '2021-02-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-07', 3);

CREATE TABLE menu (
    product_id   INT,
    product_name VARCHAR(5),
    price        INT
);

INSERT INTO menu (product_id, product_name, price) VALUES
(1, 'sushi', 10),
(2, 'curry', 15),
(3, 'ramen', 12);

CREATE TABLE members (
    customer_id VARCHAR(1),
    join_date   DATE
);

INSERT INTO members (customer_id, join_date) VALUES
('A', '2021-01-07'),
('B', '2021-01-09');

SELECT * FROM sales;
SELECT * FROM menu;      
SELECT * FROM members;  

--1-- What is the total amount each customer spent at the restaurant?
SELECT 
    customer_id,
    SUM(price) AS total_spent
FROM sales
JOIN menu
    ON sales.product_id = menu.product_id
GROUP BY customer_id;

--2-- How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS visit_days 
FROM sales
GROUP BY customer_id;

--3-- What was the first item from the menu purchased by each customer?
WITH first_purchase AS (
    SELECT customer_id, MIN(order_date) AS first_date
    FROM sales
    GROUP BY customer_id
)
SELECT DISTINCT sales.customer_id, menu.product_name
FROM sales
JOIN first_purchase
  ON sales.customer_id = first_purchase.customer_id
 AND sales.order_date = first_purchase.first_date
JOIN menu ON sales.product_id = menu.product_id
ORDER BY sales.customer_id;

--4-- Most purchased item overall
SELECT TOP 1 menu.product_name,
       COUNT(sales.product_id) AS purchase_count
FROM sales
JOIN menu ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY COUNT(sales.product_id) DESC;

--5-- Most popular item for each customer
WITH purchase_counts AS(
SELECT customer_id,
product_id, 
COUNT(product_id) AS purchase_count
FROM sales 
GROUP BY customer_id, product_id ),
ranked_products AS ( 
SELECT
customer_id,
product_id, 
purchase_count,
RANK() OVER (
PARTITION BY customer_id 
ORDER BY purchase_count DESC
) AS product_rank 
FROM purchase_counts 
) 
SELECT ranked_products.customer_id,
menu.product_name,
ranked_products.purchase_count
FROM ranked_products 
JOIN menu
ON ranked_products.product_id = menu.product_id
WHERE product_rank = 1;

--6--First item purchased after becoming a member
WITH first_order AS (
SELECT sales.customer_id, MIN(sales.order_date) AS first_order_date
FROM sales
JOIN members
ON sales.customer_id = members.customer_id 
WHERE sales.order_date >= members.join_date 
GROUP BY sales.customer_id
) 
SELECT first_order.customer_id, menu.product_name 
FROM first_order 
JOIN sales 
ON first_order.customer_id = sales.customer_id AND first_order.first_order_date = sales.order_date
JOIN menu
ON sales.product_id = menu.product_id;

--7--Item purchased just before becoming a member
WITH last_purchase AS ( 
SELECT sales.customer_id, MAX(sales.order_date) AS last_date
FROM sales 
JOIN members
ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id 
) 
SELECT last_purchase.customer_id, menu.product_name
FROM last_purchase 
JOIN sales
ON last_purchase.customer_id = sales.customer_id AND last_purchase.last_date = sales.order_date 
JOIN menu 
ON sales.product_id = menu.product_id 
ORDER BY last_purchase.customer_id;

--8-- Total items and amount spent before membership
SELECT sales.customer_id, COUNT(sales.product_id) AS total_items, SUM(menu.price) AS total_spent
FROM sales 
JOIN members
ON sales.customer_id = members.customer_id
JOIN menu
ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date 
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

--9-- Customer points
SELECT sales.customer_id, SUM( CASE WHEN menu.product_name = 'sushi' THEN menu.price * 20 ELSE menu.price * 10 END )
AS total_points
FROM sales
JOIN menu 
ON sales.product_id = menu.product_id 
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

--10--Points at the end of January
SELECT
    sales.customer_id,
    SUM(
        CASE
            WHEN sales.order_date BETWEEN members.join_date
                                      AND DATEADD(DAY, 6, members.join_date)
                THEN menu.price * 20

            WHEN menu.product_name = 'sushi'
                THEN menu.price * 20

            ELSE menu.price * 10
        END
    ) AS total_points
FROM sales
JOIN members
    ON sales.customer_id = members.customer_id
JOIN menu
    ON sales.product_id = menu.product_id
WHERE sales.order_date <= '2021-01-31'
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- Bonus 1 — Join All The Things
SELECT
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    CASE
        WHEN sales.order_date >= members.join_date THEN 'Y'
        ELSE 'N'
    END AS member
FROM sales
JOIN menu
    ON sales.product_id = menu.product_id
LEFT JOIN members
    ON sales.customer_id = members.customer_id
ORDER BY
    sales.customer_id,
    sales.order_date;

-- Bonus 2 — Rank All The Things
SELECT
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    'N' AS member,
    CAST(NULL AS bigint) AS ranking
FROM sales
JOIN menu
    ON sales.product_id = menu.product_id
LEFT JOIN members
    ON sales.customer_id = members.customer_id
WHERE members.join_date IS NULL
   OR sales.order_date < members.join_date

UNION ALL

SELECT
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    'Y' AS member,
    RANK() OVER (
        PARTITION BY sales.customer_id
        ORDER BY sales.order_date
    ) AS ranking
FROM sales
JOIN menu
    ON sales.product_id = menu.product_id
JOIN members
    ON sales.customer_id = members.customer_id
WHERE sales.order_date >= members.join_date

ORDER BY
    customer_id,
    order_date;
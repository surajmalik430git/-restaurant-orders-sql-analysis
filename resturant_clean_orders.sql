SELECT * FROM restaurant_orders;
--Cleaning messy data (e.g., inconsistent capitalization, missing values, incorrect time formats)
UPDATE restaurant_orders
SET day_of_week = INITCAP(TRIM(day_of_week));

--correct the wrong value
UPDATE  restaurant_orders
SET order_time = '8:05'
WHERE order_time = '08:5';
--correct time formats
ALTER TABLE  restaurant_orders
ALTER COLUMN order_time TYPE TIME
USING CASE 
    WHEN order_time ~ '^\d{1,2}:\d{2}$'          THEN TO_TIMESTAMP(order_time, 'HH24:MI')::TIME
    WHEN order_time ~ '^\d{1,2}:\d{2} (AM|PM)$'  THEN TO_TIMESTAMP(order_time, 'HH12:MI AM')::TIME
    ELSE NULL
END;

--correct the wrong values

UPDATE restaurant_orders
SET rating = 5
WHERE rating = 'five';

--changing data type of rating column from text to numaric


ALTER TABLE restaurant_orders
ALTER COLUMN rating TYPE NUMERIC(10,0)
USING NULLIF(rating, '')::NUMERIC(10,0);

--filling the null value according to the payment_method 
UPDATE restaurant_orders AS t1
SET rating = (
    SELECT AVG(rating)
    FROM restaurant_orders AS t2
    WHERE t2.payment_method = t1.payment_method
      AND t2.rating IS NOT NULL 
	  )
	  WHERE t1.rating IS NULL;

-- fill null values 

UPDATE restaurant_orders
SET order_time = '0:00'
WHERE order_time IS NULL;

-- fillinig the null value of the price according to the category

UPDATE restaurant_orders AS t1
SET price = (
    SELECT AVG(CAST(price AS NUMERIC))
    FROM restaurant_orders AS t2
    WHERE t2.category = t1.category
      AND t2.price IS NOT NULL
)::TEXT
WHERE t1.price IS NULL;

--change data type of column price form text to numeric 
ALTER TABLE restaurant_orders
ALTER COLUMN price TYPE NUMERIC (10,2)
USING NULLIF(price, '')::NUMERIC (10,2);

--changing data type 
ALTER TABLE  restaurant_orders
ALTER COLUMN quantity TYPE NUMERIC(10,2)
USING NULLIF (quantity,'')::NUMERIC(10,2);

--Filter: weekend orders only

SELECT * FROM restaurant_orders
WHERE day_of_week IN ('Saturday', 'Sunday');

--RE arrange the value
SELECT * FROM restaurant_orders WHERE category = 'Side';

UPDATE restaurant_orders
SET quantity = NULL
WHERE quantity < 0;

--Aggregate: total revenue per category

Aggregate: total revenue per category
SELECT category, SUM(price * quantity) AS total_revenue
FROM restaurant_orders
GROUP BY category
ORDER BY total_revenue DESC;

--Aggregate: average rating per item

SELECT item_name, ROUND(AVG(rating), 1) AS avg_rating
FROM restaurant_orders
GROUP BY item_name
ORDER BY avg_rating DESC;

--Filter + aggregate combined: revenue by order_type

SELECT order_type, SUM(price * quantity) AS total_revenue, COUNT(*) AS orders
FROM restaurant_orders
WHERE price > 5
GROUP BY order_type
ORDER BY total_revenue DESC;

--Aggregate
SELECT payment_method, COUNT(*) AS orders
FROM restaurant_orders
GROUP BY payment_method
ORDER BY orders DESC;

--rating of every item

SELECT item_name, ROUND(AVG(rating), 1) AS avg_rating
FROM restaurant_orders
GROUP BY item_name
ORDER BY avg_rating DESC;

--order_type and total revenue 

SELECT order_type , ROUND(SUM (price*quantity),1)AS total_revenue,COUNT(*)
FROM restaurant_orders 
GROUP BY order_type ORDER BY total_revenue DESC ;

--which payment method use most

 SELECT payment_method , COUNT(*)AS used_most FROM restaurant_orders
 GROUP BY payment_method ORDER BY  used_most DESC;



-- uppercase the item_name column
UPDATE restaurant_orders
SET item_name= INITCAP(TRIM(item_name));

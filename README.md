# -restaurant-orders-sql-analysis
# Restaurant Orders Data Cleaning & Analysis (PostgreSQL)

## Problem
A raw restaurant orders dataset had inconsistent text casing, mixed time formats, missing values in price and rating, a misspelled rating entry, and a negative quantity value that distorted revenue totals when aggregated.

## What I fixed
- Standardized `day_of_week` and `item_name` casing/spacing using `INITCAP` and `TRIM`
- Corrected a malformed time value (`08:5` -> `8:05`) and converted `order_time` from mixed formats into a proper TIME column using pattern matching with `TO_TIMESTAMP`
- Filled missing `order_time` values with a default (`0:00`)
- Fixed a misspelled rating (`'five'` -> `5`) and converted `rating` to NUMERIC
- Filled missing `rating` values using the average rating of other orders with the same payment method
- Filled a missing `price` value using the average price of other orders in the same category
- Converted `price` and `quantity` from text into proper NUMERIC types
- Found and corrected a negative `quantity` value that was silently canceling out real revenue in the Side category when summed, set to NULL instead of left to distort totals

## Analysis
Using SQL filtering and aggregation (`WHERE`, `GROUP BY`, `SUM`, `AVG`, `COUNT`):

- **Filter:** isolated weekend orders (Saturday/Sunday)
- **Revenue by category:** Food leads by a wide margin ($135.02), followed by Drink ($17.50) and Side ($4.50, after correcting the negative-quantity bug that was zeroing it out)
- **Average rating by item:** Burger rated highest (4.8), Pizza rated lowest (3.0); Fries, Pasta, Soda, and Salad all averaged 4.0
- **Revenue by order type (orders above $5):** Dine-In generated the highest revenue ($105.8 across 7 orders), followed by Takeout ($28.5) and Delivery ($22.8)
- **Most used payment method:** Credit Card (6 orders), followed by Online (4), Cash (3), and Debit Card (1)

## Key finding
A negative quantity value in the Side category was silently canceling out real revenue when summed (a real order's revenue plus a -1 quantity row netted close to $0 in the raw total). This was caught by comparing the aggregated result against the raw rows, and fixed by treating the negative value as invalid data rather than including it in totals.

## Before / After

**Full table -- before cleaning:**
<img width="649" height="401" alt="Screenshot 2026-10-01 150338" src="https://github.com/user-attachments/assets/dccfb1f3-7893-444e-8799-7afdfe06fbb6" />


**Full table -- after cleaning:**
<img width="727" height="398" alt="Screenshot 2026-10-01 150301" src="https://github.com/user-attachments/assets/8b9d619e-3770-44c8-9553-31bda5030bb9" />


**item_name -- before:**
<img width="386" height="287" alt="Screenshot 2026-10-01 145055" src="https://github.com/user-attachments/assets/451add88-c59b-4f23-80a0-bb5f3d0aca09" />


**item_name -- after:**
<img width="370" height="287" alt="Screenshot 2026-10-01 145324" src="https://github.com/user-attachments/assets/1799fbc3-1047-46ba-98c2-81bda96132a2" />

**order_time -- before:**
<img width="429" height="362" alt="Screenshot 2026-10-01 145414" src="https://github.com/user-attachments/assets/3adc1ce4-c7c1-4407-a1a7-9366c6674425" />


**order_time -- after:**
<img width="361" height="362" alt="Screenshot 2026-10-01 145435" src="https://github.com/user-attachments/assets/9696d877-a681-4d5e-9979-c2c3c1b01d82" />


## Query results
<img width="346" height="203" alt="Screenshot 2026-10-01 150020" src="https://github.com/user-attachments/assets/f3aee867-ac72-4611-99a9-554ae2048b08" />
<img width="267" height="179" alt="Screenshot 2026-10-01 153015" src="https://github.com/user-attachments/assets/f2e75e15-47e0-4459-ae2e-55864d0b1949" />
<img width="426" height="203" alt="Screenshot 2026-10-01 153234" src="https://github.com/user-attachments/assets/feef65ab-b02b-4d3c-9123-1e5e5c0e245f" />
<img width="326" height="173" alt="Screenshot 2026-10-01 154416" src="https://github.com/user-attachments/assets/ab5bb3bf-450e-43cd-b0cf-a5cff2446a8a" />





## Tools
PostgreSQL, pgAdmin

## Dashboard
Built an interactive Power BI dashboard visualizing revenue by category, average rating by item, orders by payment method, revenue by order type, and order volume by day of week.
<img width="464" height="258" alt="Screenshot 2026-10-03 181607" src="https://github.com/user-attachments/assets/d50a2b87-1072-446c-95f7-1133a5e4d13c" />


## Files
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

SELECT category, SUM(price * quantity) AS total_revenue
FROM restaurant_orders
GROUP BY category  ORDER BY total_revenue DESC;

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

--Aggregate total revanue per category
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
 restaurant_orders

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'restaurant_orders' AND column_name = 'order_id';

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'restaurant_orders' AND column_name = 'order_id';

ALTER TABLE restaurant_orders
ALTER COLUMN order_id TYPE INTEGER
USING NULLIF(order_id, '')::INTEGER;

- Screenshots -- before/after proof and query results
- <img width="649" height="401" alt="Screenshot 2026-10-01 150338" src="https://github.com/user-attachments/assets/6cb2fd0a-afe7-41c1-9799-0bd6b55183dd" />
<img width="727" height="398" alt="Screenshot 2026-10-01 150301" src="https://github.com/user-attachments/assets/ed2fc6e2-babf-4e05-b7a1-3025d8c15d71" />


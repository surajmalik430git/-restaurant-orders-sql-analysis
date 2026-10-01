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

## Files
- `resturant_clean_orders.sql` -- full script: cleaning and analysis queries, with comments marking each step
- Screenshots -- before/after proof and query results

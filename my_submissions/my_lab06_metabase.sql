-- Question 1 — Doanh thu thiết bị điện tử theo ngày (Bar chart)
SELECT sale_date,
       SUM(total_amount) AS revenue,
       COUNT(*)          AS total_transactions
FROM   my_lab06_dw.fact_sales
GROUP  BY sale_date
ORDER  BY sale_date;

-- Question 2 — Top khách hàng theo doanh thu (Pie / Row chart)
SELECT c.customer_name,
       SUM(f.total_amount) AS revenue
FROM   my_lab06_dw.fact_sales f
JOIN   my_lab06_dw.dim_customer c ON c.customer_key = f.customer_key
WHERE  c.is_current = TRUE
GROUP  BY c.customer_name
ORDER  BY revenue DESC
LIMIT  10;

-- Question 3 — Doanh thu theo thương hiệu (Brand) (Bar chart)
SELECT d.brand,
       SUM(f.total_amount)   AS revenue,
       SUM(f.units)          AS units_sold
FROM   my_lab06_dw.fact_sales f
JOIN   my_lab06_dw.dim_device d ON d.device_key = f.device_key
GROUP  BY d.brand
ORDER  BY revenue DESC;

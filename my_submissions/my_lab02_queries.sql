-- =========================================================
-- MY LAB 02 — SQL Fundamentals → Advanced
-- Lĩnh vực: Điện máy & Thiết bị thông minh (Electronics Retail)
-- =========================================================

-- ---------------------------------------------------------
-- 0. Khởi tạo Schema và Mock Data
-- ---------------------------------------------------------
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS devices;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    region VARCHAR(50)
);

CREATE TABLE devices (
    device_id SERIAL PRIMARY KEY,
    device_name VARCHAR(100),
    brand VARCHAR(50),
    price NUMERIC(10, 2)
);

CREATE TABLE transactions (
    txn_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    device_id INT REFERENCES devices(device_id),
    txn_date DATE,
    amount NUMERIC(10, 2)
);

INSERT INTO users (full_name, region) VALUES
('Nguyen Thanh A', 'North'),
('Tran B', 'South'),
('Le Chi C', 'Central'),
('Vu D', 'North'),
('Phan E', 'South'); -- Khách không có giao dịch

INSERT INTO devices (device_name, brand, price) VALUES
('iPhone 15 Pro', 'Apple', 1000.00),
('Galaxy S24', 'Samsung', 900.00),
('AirPods Pro', 'Apple', 250.00),
('MacBook Air', 'Apple', 1200.00),
('Sony WH-1000XM5', 'Sony', 350.00);

INSERT INTO transactions (user_id, device_id, txn_date, amount) VALUES
(1, 1, CURRENT_DATE - INTERVAL '10 days', 1000.00),
(1, 3, CURRENT_DATE - INTERVAL '5 days', 250.00),
(2, 2, CURRENT_DATE - INTERVAL '2 days', 900.00),
(3, 4, CURRENT_DATE - INTERVAL '15 days', 1200.00),
(1, 4, CURRENT_DATE - INTERVAL '20 days', 1200.00),
(2, 5, CURRENT_DATE - INTERVAL '8 days', 350.00),
(4, 3, CURRENT_DATE - INTERVAL '3 days', 250.00),
(4, 5, CURRENT_DATE - INTERVAL '1 days', 350.00);


-- =========================================================
-- NHÓM 1 — SELECT / WHERE / ORDER BY
-- =========================================================

-- Bài 1: Lấy toàn bộ users
SELECT * FROM users;

-- Bài 2: Danh sách users sắp xếp theo region A-Z
SELECT full_name, region FROM users ORDER BY region ASC, full_name ASC;

-- Bài 3: Giao dịch có trị giá >= 900
SELECT * FROM transactions WHERE amount >= 900 ORDER BY amount DESC;

-- Bài 4: Lấy 3 giao dịch mới nhất
SELECT * FROM transactions ORDER BY txn_date DESC LIMIT 3;

-- Bài 5: Thiết bị Apple giá dưới 1100
SELECT device_name, price FROM devices WHERE brand = 'Apple' AND price < 1100;


-- =========================================================
-- NHÓM 2 — JOIN
-- =========================================================

-- Bài 6: INNER JOIN user và transaction
SELECT u.full_name, t.amount 
FROM users u INNER JOIN transactions t ON u.user_id = t.user_id;

-- Bài 7: LEFT JOIN (hiển thị cả user chưa mua)
SELECT u.full_name, t.txn_id, t.amount
FROM users u LEFT JOIN transactions t ON u.user_id = t.user_id;

-- Bài 8: RIGHT JOIN 
SELECT u.full_name, t.txn_id 
FROM users u RIGHT JOIN transactions t ON u.user_id = t.user_id;

-- Bài 9: FULL OUTER JOIN
SELECT u.full_name, t.amount
FROM users u FULL OUTER JOIN transactions t ON u.user_id = t.user_id;

-- Bài 10: JOIN 3 Bảng
SELECT u.full_name, d.device_name, d.brand, t.amount, t.txn_date
FROM transactions t
JOIN users u ON u.user_id = t.user_id
JOIN devices d ON d.device_id = t.device_id
ORDER BY t.txn_date DESC;


-- =========================================================
-- NHÓM 3 — SUBQUERY / CTE
-- =========================================================

-- Bài 11: Users chi tiêu nhiều hơn trung bình
SELECT user_id, SUM(amount) AS total
FROM transactions
GROUP BY user_id
HAVING SUM(amount) > (
    SELECT AVG(total_spent) FROM (
        SELECT SUM(amount) AS total_spent FROM transactions GROUP BY user_id
    ) sub
);

-- Bài 12: CTE lọc giao dịch tuần qua
WITH recent_txns AS (
    SELECT * FROM transactions WHERE txn_date >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT u.full_name, r.amount FROM users u JOIN recent_txns r ON u.user_id = r.user_id;

-- Bài 13: 2 CTEs tính doanh thu và rank
WITH user_revenue AS (
    SELECT user_id, SUM(amount) AS revenue FROM transactions GROUP BY user_id
),
ranked_users AS (
    SELECT user_id, revenue, RANK() OVER (ORDER BY revenue DESC) AS rnk FROM user_revenue
)
SELECT * FROM ranked_users;

-- Bài 14: Subquery đếm số lượng giao dịch
SELECT t.txn_id, t.user_id, t.amount,
    (SELECT COUNT(*) FROM transactions t2 WHERE t2.user_id = t.user_id) AS total_txns
FROM transactions t;

-- Bài 15: Recursive CTE chuỗi 7 ngày
WITH RECURSIVE date_series(d) AS (
    SELECT CURRENT_DATE::date
    UNION ALL
    SELECT (d - INTERVAL '1 day')::date
    FROM date_series
    WHERE d > (CURRENT_DATE - INTERVAL '6 days')::date
)
SELECT d::date, COALESCE(SUM(t.amount), 0) AS daily_revenue
FROM date_series ds LEFT JOIN transactions t ON ds.d = t.txn_date
GROUP BY d ORDER BY d;


-- =========================================================
-- NHÓM 4 — WINDOW FUNCTIONS
-- =========================================================

-- Bài 16: SUM OVER (Running Total)
SELECT user_id, txn_date, amount,
       SUM(amount) OVER (PARTITION BY user_id ORDER BY txn_date) AS running_total
FROM transactions;

-- Bài 17: ROW_NUMBER
SELECT user_id, txn_date, amount,
       ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY txn_date) AS purchase_seq
FROM transactions;

-- Bài 18: RANK vs DENSE_RANK
SELECT user_id, SUM(amount) AS total,
       RANK() OVER (ORDER BY SUM(amount) DESC) AS r_rank,
       DENSE_RANK() OVER (ORDER BY SUM(amount) DESC) AS d_rank
FROM transactions GROUP BY user_id;

-- Bài 19: OVER() giữ nguyên dòng vs GROUP BY
SELECT user_id, txn_id, amount,
       SUM(amount) OVER (PARTITION BY user_id) AS total_by_user
FROM transactions;

-- Bài 20: Top 2 giao dịch lớn nhất mỗi user
WITH ranked_txns AS (
    SELECT user_id, txn_id, amount,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) as rn
    FROM transactions
)
SELECT * FROM ranked_txns WHERE rn <= 2;


-- =========================================================
-- NHÓM 5 — OPTIMIZATION
-- =========================================================

-- Bài 21: EXPLAIN Scan trước index
EXPLAIN ANALYZE SELECT * FROM transactions WHERE user_id = 1;

-- Bài 22: Tạo index
CREATE INDEX idx_txn_user ON transactions(user_id);
CREATE INDEX idx_txn_date ON transactions(txn_date);

-- Bài 23: EXPLAIN sau index
EXPLAIN ANALYZE SELECT * FROM transactions WHERE user_id = 1;

-- Bài 24: Tránh SELECT *
EXPLAIN ANALYZE SELECT txn_id, amount FROM transactions WHERE txn_date >= CURRENT_DATE - INTERVAL '10 days';

-- Bài 25: Đọc cost so sánh
EXPLAIN ANALYZE SELECT user_id, SUM(amount) FROM transactions GROUP BY user_id;
EXPLAIN ANALYZE SELECT DISTINCT user_id, SUM(amount) OVER (PARTITION BY user_id) FROM transactions;

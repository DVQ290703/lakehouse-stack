CREATE SCHEMA IF NOT EXISTS my_ecommerce_dw;

-- Clean up
DROP TABLE IF EXISTS my_ecommerce_dw.mart_daily_brand_sales;
DROP TABLE IF EXISTS my_ecommerce_dw.fact_sales;
DROP TABLE IF EXISTS my_ecommerce_dw.dim_users;
DROP TABLE IF EXISTS my_ecommerce_dw.dim_devices;
DROP TABLE IF EXISTS my_ecommerce_dw.dim_calendar;

-- 1. Date Dimension
CREATE TABLE my_ecommerce_dw.dim_calendar (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    day INT
);

-- 2. Device Dimension
CREATE TABLE my_ecommerce_dw.dim_devices (
    device_key SERIAL PRIMARY KEY,
    device_id INT NOT NULL,
    device_name VARCHAR(100),
    brand VARCHAR(50),
    price NUMERIC(10,2)
);

-- 3. User Dimension (SCD tracking)
CREATE TABLE my_ecommerce_dw.dim_users (
    user_key SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    username VARCHAR(100),
    tier VARCHAR(30),
    address VARCHAR(100),
    effective_start DATE NOT NULL,
    effective_end DATE,
    is_active BOOLEAN DEFAULT TRUE,
    previous_address VARCHAR(100),
    current_address VARCHAR(100)
);

-- 4. Fact Sales
CREATE TABLE my_ecommerce_dw.fact_sales (
    sale_id INT PRIMARY KEY,
    date_key INT REFERENCES my_ecommerce_dw.dim_calendar(date_key),
    user_key INT REFERENCES my_ecommerce_dw.dim_users(user_key),
    device_key INT REFERENCES my_ecommerce_dw.dim_devices(device_key),
    units INT,
    revenue NUMERIC(12,2)
);

-- Seed Data
INSERT INTO my_ecommerce_dw.dim_calendar VALUES
(20261001, '2026-10-01', 2026, 4, 10, 1),
(20261002, '2026-10-02', 2026, 4, 10, 2);

INSERT INTO my_ecommerce_dw.dim_devices (device_id, device_name, brand, price) VALUES
(11, 'iPhone 15', 'Apple', 1000.00),
(22, 'Galaxy S24', 'Samsung', 900.00);

INSERT INTO my_ecommerce_dw.dim_users (user_id, username, tier, address, effective_start, effective_end, is_active, previous_address, current_address) VALUES
(1, 'Alice', 'Gold', 'Hanoi', '2026-01-01', NULL, TRUE, NULL, 'Hanoi'),
(2, 'Bob', 'Silver', 'HCM', '2026-01-01', NULL, TRUE, NULL, 'HCM'),
(3, 'Charlie', 'Platinum', 'Danang', '2026-01-01', NULL, TRUE, NULL, 'Danang');

INSERT INTO my_ecommerce_dw.fact_sales VALUES
(100, 20261001, 1, 1, 1, 1000.00),
(101, 20261001, 2, 2, 2, 1800.00),
(102, 20261002, 3, 1, 1, 1000.00);

-- ============================================
-- THỰC HÀNH SCD
-- ============================================

-- SCD Type 1: Alice đổi địa chỉ thành Haiphong (Overwrite trực tiếp)
UPDATE my_ecommerce_dw.dim_users
SET address = 'Haiphong', current_address = 'Haiphong'
WHERE user_id = 1 AND is_active = TRUE;

-- SCD Type 2: Bob đổi địa chỉ thành Can Tho (Tạo dòng mới, đóng dòng cũ)
UPDATE my_ecommerce_dw.dim_users
SET effective_end = '2026-09-30', is_active = FALSE
WHERE user_id = 2 AND is_active = TRUE;

INSERT INTO my_ecommerce_dw.dim_users (user_id, username, tier, address, effective_start, effective_end, is_active, previous_address, current_address)
VALUES (2, 'Bob', 'Silver', 'Can Tho', '2026-10-01', NULL, TRUE, 'HCM', 'Can Tho');

-- SCD Type 6: Charlie đổi địa chỉ về Hue (Tạo dòng mới + update dòng cũ)
UPDATE my_ecommerce_dw.dim_users
SET effective_end = '2026-12-31', is_active = FALSE, current_address = 'Hue'
WHERE user_id = 3 AND is_active = TRUE;

INSERT INTO my_ecommerce_dw.dim_users (user_id, username, tier, address, effective_start, effective_end, is_active, previous_address, current_address)
VALUES (3, 'Charlie', 'Platinum', 'Hue', '2027-01-01', NULL, TRUE, 'Danang', 'Hue');


-- ============================================
-- TẠO DATA MART TỔNG HỢP THEO THƯƠNG HIỆU
-- ============================================
CREATE TABLE my_ecommerce_dw.mart_daily_brand_sales AS
SELECT 
    d.full_date,
    dev.brand,
    SUM(f.units) AS total_units,
    SUM(f.revenue) AS total_revenue
FROM my_ecommerce_dw.fact_sales f
JOIN my_ecommerce_dw.dim_calendar d ON f.date_key = d.date_key
JOIN my_ecommerce_dw.dim_devices dev ON f.device_key = dev.device_key
GROUP BY d.full_date, dev.brand
ORDER BY d.full_date, dev.brand;

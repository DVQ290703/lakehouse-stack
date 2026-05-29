CREATE SCHEMA IF NOT EXISTS my_lab06_dw;

-- Drop existings to be safe
DROP TABLE IF EXISTS my_lab06_dw.fact_sales;
DROP TABLE IF EXISTS my_lab06_dw.dim_customer;
DROP TABLE IF EXISTS my_lab06_dw.dim_device;

-- Dimension: Customer (SCD Type 2)
CREATE TABLE my_lab06_dw.dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id INT,
    customer_name TEXT,
    tier TEXT,
    effective_from DATE,
    effective_to DATE,
    is_current BOOLEAN
);

-- Dimension: Device
CREATE TABLE my_lab06_dw.dim_device (
    device_key SERIAL PRIMARY KEY,
    device_id INT,
    device_name TEXT,
    brand TEXT
);

-- Fact: Sales
CREATE TABLE my_lab06_dw.fact_sales (
    sale_key SERIAL PRIMARY KEY,
    sale_id INT,
    sale_date DATE,
    customer_key INT REFERENCES my_lab06_dw.dim_customer(customer_key),
    device_key INT REFERENCES my_lab06_dw.dim_device(device_key),
    units INT,
    total_amount NUMERIC(12,2)
);

-- Load Sample Data
INSERT INTO my_lab06_dw.dim_customer (customer_id, customer_name, tier, effective_from, effective_to, is_current) VALUES 
(1, 'Alice Nguyen', 'Gold', '2026-01-01', NULL, TRUE),
(2, 'Bob Tran', 'Silver', '2026-01-01', NULL, TRUE);

INSERT INTO my_lab06_dw.dim_device (device_id, device_name, brand) VALUES
(100, 'iPhone 15', 'Apple'),
(101, 'Galaxy S24', 'Samsung');

INSERT INTO my_lab06_dw.fact_sales (sale_id, sale_date, customer_key, device_key, units, total_amount) VALUES
(1001, '2026-05-01', 1, 1, 1, 1000.00),
(1002, '2026-05-01', 2, 2, 2, 1800.00),
(1003, '2026-05-02', 1, 2, 1, 900.00);

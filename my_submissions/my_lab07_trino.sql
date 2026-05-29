-- Táº¡o Schema cho 3 lá»›p Medallion Architecture
CREATE SCHEMA IF NOT EXISTS hive.lakehouse.my_bronze WITH (location = 's3://lakehouse/bronze/');
CREATE SCHEMA IF NOT EXISTS hive.lakehouse.my_silver WITH (location = 's3://lakehouse/silver/');
CREATE SCHEMA IF NOT EXISTS hive.lakehouse.my_gold WITH (location = 's3://lakehouse/gold/');

-- DROP tables if exist
DROP TABLE IF EXISTS hive.lakehouse.my_gold.ecommerce_sales;
DROP TABLE IF EXISTS hive.lakehouse.my_silver.ecommerce_clean;
DROP TABLE IF EXISTS hive.lakehouse.my_bronze.ecommerce_raw;

-- 1. BRONZE LAYER (Báº£ng External trá» tá»›i file Text gá»‘c)
CREATE TABLE IF NOT EXISTS hive.lakehouse.my_bronze.ecommerce_raw (
    txn_id VARCHAR,
    user_id VARCHAR,
    amount VARCHAR,
    txn_date VARCHAR
) WITH (
    format = 'TEXTFILE',
    external_location = 's3://lakehouse/bronze/ecommerce'
);

-- Giáº£ láº­p náº¡p dá»¯ liá»‡u (bao gá»“m 1 hÃ ng lá»—i bad_amount)
INSERT INTO hive.lakehouse.my_bronze.ecommerce_raw VALUES 
('1', '101', '150.5', '2026-05-01'),
('2', '102', 'bad_amount', '2026-05-02'),
('3', '101', '250.0', '2026-05-03');

-- 2. SILVER LAYER (Lá»c sáº¡ch, Ã©p kiá»ƒu vÃ  lÆ°u dÆ°á»›i format siÃªu nhanh Parquet)
CREATE TABLE IF NOT EXISTS hive.lakehouse.my_silver.ecommerce_clean WITH (
    format = 'PARQUET',
    external_location = 's3://lakehouse/silver/ecommerce_clean'
) AS
SELECT 
    CAST(txn_id AS INTEGER) AS txn_id,
    CAST(user_id AS INTEGER) AS user_id,
    CAST(TRY(CAST(amount AS DOUBLE)) AS DOUBLE) AS amount,
    CAST(TRY(CAST(txn_date AS DATE)) AS DATE) AS txn_date
FROM hive.lakehouse.my_bronze.ecommerce_raw
WHERE TRY(CAST(amount AS DOUBLE)) IS NOT NULL; -- Bá» rÃ¡c

-- 3. GOLD LAYER (Tá»•ng há»£p phá»¥c vá»¥ bÃ¡o cÃ¡o Doanh thu ngÆ°á»i dÃ¹ng)
CREATE TABLE IF NOT EXISTS hive.lakehouse.my_gold.ecommerce_sales WITH (
    format = 'PARQUET',
    external_location = 's3://lakehouse/gold/ecommerce_sales'
) AS
SELECT 
    user_id,
    COUNT(txn_id) AS total_orders,
    SUM(amount) AS total_revenue
FROM hive.lakehouse.my_silver.ecommerce_clean
GROUP BY user_id;


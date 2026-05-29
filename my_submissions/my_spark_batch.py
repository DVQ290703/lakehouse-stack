from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lower, trim, to_timestamp, to_date, sum as _sum, count as _count

# Khởi tạo Spark Session với cấu hình AWS S3 kết nối tới MinIO
spark = (
    SparkSession.builder
    .appName("MyEcommerceSparkBatch")
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000")
    .config("spark.hadoop.fs.s3a.access.key", "minio")
    .config("spark.hadoop.fs.s3a.secret.key", "minio12345")
    .config("spark.hadoop.fs.s3a.path.style.access", "true")
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
    .getOrCreate()
)

raw_path = "s3a://lakehouse/raw/ecommerce/"
silver_path = "s3a://lakehouse/silver/ecommerce/"
gold_path = "s3a://lakehouse/gold/ecommerce_sales/"

# 1. READ RAW (Bronze)
df_raw = spark.read.option("header", True).option("inferSchema", True).csv(raw_path)
print("=== BRONZE LAYER ===")
df_raw.show(truncate=False)

# 2. TRANSFORM TO SILVER (Làm sạch, định dạng schema)
df_silver = (
    df_raw
    .withColumn("txn_timestamp", to_timestamp(col("order_timestamp"), "yyyy-MM-dd HH:mm:ss"))
    .withColumn("qty", col("quantity").cast("int"))
    .withColumn("price", col("unit_price").cast("double"))
    .withColumn("status", lower(trim(col("order_status"))))
    .withColumn("payment", lower(trim(col("payment_method"))))
    .withColumn("total_amt", col("qty") * col("price"))
    .filter(col("order_id").isNotNull())
)

print("=== SILVER LAYER ===")
df_silver.show(truncate=False)

# Ghi xuống S3 (Parquet)
df_silver.write.mode("overwrite").parquet(silver_path)

# 3. TRANSFORM TO GOLD (Aggregate)
df_silver_read = spark.read.parquet(silver_path)
df_gold = (
    df_silver_read
    .withColumn("txn_date", to_date(col("txn_timestamp")))
    .groupBy("txn_date", "payment")
    .agg(
        _count("*").alias("count_txn"),
        _sum("total_amt").alias("revenue")
    )
    .orderBy("txn_date", "payment")
)

print("=== GOLD LAYER ===")
df_gold.show(truncate=False)

# Ghi xuống S3 (Parquet)
df_gold.write.mode("overwrite").parquet(gold_path)

spark.stop()

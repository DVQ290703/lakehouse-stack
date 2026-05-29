from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date

# Khởi tạo Spark Session
spark = (
    SparkSession.builder
    .appName("MyLakehouseOptimization")
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000")
    .config("spark.hadoop.fs.s3a.access.key", "minio")
    .config("spark.hadoop.fs.s3a.secret.key", "minio12345")
    .config("spark.hadoop.fs.s3a.path.style.access", "true")
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
    .getOrCreate()
)

print("=== 1. READ SILVER LAYER ===")
silver_df = spark.read.parquet("s3a://lakehouse/silver/ecommerce/")

print("=== 2. PARTITIONING BY DATE ===")
# Tạo folder riêng cho từng ngày giúp truy vấn WHERE date = ... cực nhanh
gold_df = (
    silver_df
    .withColumn("txn_date", to_date(col("txn_timestamp")))
    .groupBy("txn_date", "payment")
    .sum("total_amt")
    .withColumnRenamed("sum(total_amt)", "total_revenue")
)
(gold_df.write
    .mode("overwrite")
    .partitionBy("txn_date")
    .parquet("s3a://lakehouse/gold/ecommerce_sales_partitioned/"))

print("=== 3. MÔ PHỎNG LỖI SMALL FILE PROBLEM ===")
# Chia nhỏ data thành 30 files Parquet rác vô nghĩa
(silver_df
    .repartition(30)
    .write
    .mode("overwrite")
    .parquet("s3a://lakehouse/silver/ecommerce_many_small_files/"))

print("=== 4. COMPACTION (Thu gom file rác) ===")
# Dùng coalesce để nén 30 files nhỏ thành 2 files lớn
small_df = spark.read.parquet("s3a://lakehouse/silver/ecommerce_many_small_files/")
(small_df
    .coalesce(2)
    .write
    .mode("overwrite")
    .parquet("s3a://lakehouse/silver/ecommerce_compacted/"))

print("=== 5. CLUSTERING (Sắp xếp tăng cường) ===")
# Sắp xếp nội bộ dòng (sort) để giúp Metadata lưu max/min thông minh hơn, sau đó nén
(silver_df
    .sort("payment", "txn_timestamp")
    .coalesce(2)
    .write
    .mode("overwrite")
    .parquet("s3a://lakehouse/silver/ecommerce_clustered/"))

print("HOÀN TẤT CÁC THUẬT TOÁN TỐI ƯU!")
spark.stop()

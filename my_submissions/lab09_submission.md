# Bài nộp Lab 09 — Table Formats & Optimization

## 1. Chạy job tối ưu Spark
Đã chạy job: [my_spark_optimize.py](file:///d:/Python/VinUni/Data/lakehouse-stack/my_submissions/my_spark_optimize.py)

Job triển khai các kỹ thuật tối ưu:
1. **Partitioning**: ghi Gold có partition theo `txn_date` vào
   `s3a://lakehouse/gold/ecommerce_sales_partitioned/`.
2. **Small file simulation**: tạo nhiều file nhỏ tại
   `s3a://lakehouse/silver/ecommerce_many_small_files/`.
3. **Compaction**: gom file nhỏ bằng `coalesce(2)` vào
   `s3a://lakehouse/silver/ecommerce_compacted/`.
4. **Clustering**: sort dữ liệu theo `payment`, `txn_timestamp` trước khi ghi vào
   `s3a://lakehouse/silver/ecommerce_clustered/`.

## 2. Kết quả
- Các thư mục output cho partition/compaction/clustering đã được tạo thành công.
- Có thể dùng Trino/Spark kiểm tra tốc độ truy vấn và layout dữ liệu sau tối ưu.

## 3. Trả lời lý thuyết
- **File format vs Table format**:
  - File format (Parquet/ORC): định dạng lưu file.
  - Table format (Iceberg/Delta/Hudi): quản lý metadata/transaction/schema evolution/time travel.
- **Vì sao partition nhanh**: query có điều kiện partition key sẽ đọc ít dữ liệu hơn (partition pruning).
- **Small file problem**: quá nhiều file nhỏ làm tăng overhead metadata và giảm hiệu năng đọc.
- **Khi dùng Delta/Iceberg/Hudi**:
  - Delta: hệ Spark/Databricks.
  - Iceberg: đa engine (Spark/Trino/Flink...).
  - Hudi: workload streaming/upsert cao.

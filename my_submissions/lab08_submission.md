# Bài nộp Lab 08 — Spark Batch Processing

## 1. Chạy Spark batch job
Đã chạy Spark job: [my_spark_batch.py](file:///d:/Python/VinUni/Data/lakehouse-stack/my_submissions/my_spark_batch.py)

Lệnh chạy trong container Spark:
```bash
/opt/spark/bin/spark-submit ... /opt/spark/work-dir/my_submissions/my_spark_batch.py
```

Job thực hiện:
1. Đọc dữ liệu Raw từ `s3a://lakehouse/raw/ecommerce/`.
2. Làm sạch và chuẩn hoá dữ liệu sang Silver:
   - parse timestamp
   - cast kiểu số
   - chuẩn hoá text status/payment
   - tạo `total_amt`
3. Aggregate sang Gold theo ngày giao dịch và hình thức thanh toán.
4. Ghi dữ liệu dạng Parquet về:
   - `s3a://lakehouse/silver/ecommerce/`
   - `s3a://lakehouse/gold/ecommerce_sales/`

## 2. Kết quả
- Job chạy thành công, sinh dữ liệu Silver và Gold trên MinIO.
- Có thể truy vấn lại các output bằng Spark/Trino để kiểm tra doanh thu tổng hợp.

## 3. Trả lời lý thuyết
- **Driver vs Executor**: Driver lập kế hoạch và điều phối; Executor thực thi task trên dữ liệu phân tán.
- **DataFrame vs RDD**: DataFrame tối ưu hơn cho analytics nhờ schema + Catalyst Optimizer.
- **Lazy evaluation**: Spark chỉ thực thi khi gặp action (show/count/write), giúp tối ưu toàn pipeline trước khi chạy.

# Bài nộp Lab 07 — Data Lakehouse Architecture

## 1. Thiết lập Lakehouse local
Đã chạy stack gồm MinIO + Hive Metastore + Trino thành công bằng Docker Compose.

Bucket `lakehouse` đã có các lớp dữ liệu:
- `raw/`
- `bronze/`
- `silver/`
- `gold/`

## 2. Thực thi SQL trên Trino
Đã chạy file: [my_lab07_trino.sql](file:///d:/Python/VinUni/Data/lakehouse-stack/my_submissions/my_lab07_trino.sql)

Các bước đã thực hiện:
1. Tạo schema `my_bronze`, `my_silver`, `my_gold` trong catalog `hive.lakehouse`.
2. Tạo bảng Bronze `ecommerce_raw` (TEXTFILE, external location trên S3/MinIO).
3. Nạp dữ liệu mẫu có 1 dòng lỗi `bad_amount`.
4. Tạo bảng Silver `ecommerce_clean` (PARQUET) và lọc dữ liệu lỗi bằng `TRY(CAST(...))`.
5. Tạo bảng Gold `ecommerce_sales` để tổng hợp theo `user_id`.

Kết quả: pipeline Medallion chạy đúng, dữ liệu lỗi đã bị loại ở Silver, Gold tổng hợp thành công.

## 3. Trả lời lý thuyết
- **Lakehouse vs DWH**: Lakehouse giữ được dữ liệu đa định dạng chi phí thấp như Data Lake, đồng thời hỗ trợ truy vấn/metadata mạnh cho BI như DWH.
- **Vai trò Hive Metastore**: quản lý metadata bảng (schema, location, partition) để Trino/Spark truy vấn dữ liệu file như bảng SQL.
- **Bronze/Silver/Gold**:
  - Bronze: dữ liệu thô.
  - Silver: dữ liệu đã làm sạch, chuẩn hoá schema.
  - Gold: dữ liệu đã tổng hợp phục vụ báo cáo.

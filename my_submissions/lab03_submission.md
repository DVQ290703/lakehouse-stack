# Bài nộp Lab 03 — Data Modeling for Analytics

## 1. Kết quả khởi tạo Star Schema và truy vấn JOIN

Đã chạy file [my_lab03_setup.sql](file:///d:/Python/VinUni/Data/lakehouse-stack/my_submissions/my_lab03_setup.sql) thành công trên PostgreSQL container `de_postgres`. Schema `my_ecommerce_dw` được tạo với các bảng dimension và fact mới.

Kết quả JOIN fact + 3 dimension:
```text
 order_id | full_date  |  full_name   | product_name | quantity | gross_amount
----------+------------+--------------+--------------+----------+--------------
        1 | 2026-03-01 | Alice Nguyen | Notebook     |        2 |        31.00
        2 | 2026-03-01 | Bao Tran     | Pen Set      |        1 |        20.00
        3 | 2026-03-02 | Alice Nguyen | Desk Lamp    |        3 |        36.00
        4 | 2026-03-03 | Chi Le       | Notebook     |        5 |        77.50
(4 rows)
```

## 2. Thực hành Slowly Changing Dimensions (SCD)

### SCD Type 1 — Overwrite (Customer 101: Hanoi → Haiphong)
```sql
UPDATE bootcamp_dw.dim_customers
   SET city = 'Haiphong', current_city = 'Haiphong'
 WHERE customer_id = 101 AND current_flag = TRUE;
```
**Kết quả**: Dữ liệu cũ bị ghi đè hoàn toàn, không còn vết tích "Hanoi". Nếu query báo cáo doanh thu Q1 theo city thì Alice sẽ hiện là Haiphong dù lúc mua hàng cô ấy đang ở Hanoi.

### SCD Type 2 — Insert version mới (Customer 102: Danang → Hue)
```sql
-- Đóng version cũ
UPDATE bootcamp_dw.dim_customers
   SET end_date = '2026-03-31', current_flag = FALSE
 WHERE customer_id = 102 AND current_flag = TRUE;

-- Tạo version mới
INSERT INTO bootcamp_dw.dim_customers
  (customer_id, full_name, city, segment, effective_date, end_date, current_flag, previous_city, current_city)
VALUES
  (102, 'Bao Tran', 'Hue', 'Retail', '2026-04-01', NULL, TRUE, 'Danang', 'Hue');
```
**Kết quả**: Giữ nguyên cả 2 version — báo cáo Q1 vẫn thấy Danang, báo cáo Q2 thấy Hue. Đơn hàng cũ vẫn JOIN đúng vào version Danang.

### SCD Type 6 — Hybrid (Customer 103: HCMC → Vung Tau)
Kết hợp Type 1 + Type 2 + Type 3: vừa tạo version mới (Type 2), vừa cập nhật `current_city` ở version cũ (Type 1), đồng thời lưu `previous_city` (Type 3).

### Bảng dim_customers sau SCD:
```text
 customer_key | customer_id |  full_name   |   city   | effective_date |  end_date  | current_flag | previous_city | current_city
--------------+-------------+--------------+----------+----------------+------------+--------------+---------------+--------------
            1 |         101 | Alice Nguyen | Haiphong | 2026-01-01     |            | t            |               | Haiphong
            2 |         102 | Bao Tran     | Danang   | 2026-01-01     | 2026-03-31 | f            |               | Danang
            4 |         102 | Bao Tran     | Hue      | 2026-04-01     |            | t            | Danang        | Hue
            3 |         103 | Chi Le       | HCMC     | 2026-01-01     | 2026-06-30 | f            |               | Vung Tau
            5 |         103 | Chi Le       | Vung Tau | 2026-07-01     |            | t            | HCMC          | Vung Tau
(5 rows)
```

## 3. Data Mart — Tổng hợp doanh thu theo ngày và category

```text
 full_date  |  category   | total_qty | total_revenue
------------+-------------+-----------+---------------
 2026-03-01 | Stationery  |         3 |         51.00
 2026-03-02 | Home Office |         3 |         36.00
 2026-03-03 | Stationery  |         5 |         77.50
(3 rows)
```
Bảng mart `mart_daily_category_sales` được tạo bằng `CREATE TABLE ... AS SELECT` từ fact + dimension, phục vụ trực tiếp cho BI Dashboard.

## 4. Câu hỏi lý thuyết: Star Schema vs Snowflake?

**Lựa chọn**: Em chọn **Star Schema** cho dashboard doanh thu đầu tiên.

**Lý do**:
1. **Hiệu năng truy vấn cao**: Dimension đã được denormalized (mỗi bảng dim là phẳng, không chia nhỏ ra nhánh con). Khi BI tool query, chỉ cần JOIN fact với 2-3 bảng dim là đủ, không phải "đi vòng" qua nhiều bảng trung gian như Snowflake.
2. **Đơn giản, dễ hiểu**: Business user và Data Analyst có thể tự viết SQL hoặc kéo thả trên Metabase/Tableau mà không cần hiểu quan hệ phức tạp giữa hàng chục bảng con.
3. **Giao giá trị nhanh**: Theo triết lý Kimball "bottom-up", xây 1 data mart star schema là cách nhanh nhất để team có dashboard hoạt động, dù sẽ tốn thêm dung lượng lưu trữ do dữ liệu dư thừa.

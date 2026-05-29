# Bài nộp Lab 02 — SQL Fundamentals → Advanced

## 1. Tổ chức 25 bài SQL Challenge

File đáp án đầy đủ: [my_lab02_queries.sql](file:///d:/Python/VinUni/Data/lakehouse-stack/my_submissions/my_lab02_queries.sql) (file cá nhân mới tạo).

| Nhóm | Chủ đề                                      | Bài    |
|------|----------------------------------------------|--------|
| 1    | SELECT / WHERE / ORDER BY                    | 1–5    |
| 2    | JOIN (INNER / LEFT / RIGHT / FULL + 3-way)   | 6–10   |
| 3    | SUBQUERY / CTE (bao gồm CTE đệ quy)        | 11–15  |
| 4    | WINDOW FUNCTIONS (running total, ranking)    | 16–20  |
| 5    | OPTIMIZATION (EXPLAIN, INDEX)                | 21–25  |

Dữ liệu mẫu gồm 3 bảng: `customers` (5 dòng, có 1 khách chưa mua), `products` (5 dòng), `orders` (8 dòng).

## 2. Kết quả truy vấn tiêu biểu

### Bài 10 — JOIN 3 bảng (customers + orders + products)
```text
  customer   |    product     |  category   | amount  | order_date
-------------+----------------+-------------+---------+------------
 Pham Thi D  | Keyboard       | Accessories |  100.00 | 2026-05-28
 Nguyen Van A| Laptop Dell    | Electronics | 1500.00 | 2026-05-24
 Tran Thi B  | Keyboard       | Accessories |  100.00 | 2026-05-27
 Nguyen Van A| Monitor LG     | Electronics |  300.00 | 2026-05-09
 Le Van C    | Monitor LG     | Electronics |  300.00 | 2026-05-14
 Tran Thi B  | Laptop Dell    | Electronics | 1500.00 | 2026-05-19
 Pham Thi D  | Mouse Logitech | Accessories |   50.00 | 2026-05-26
 Nguyen Van A| Mouse Logitech | Accessories |   50.00 | 2026-04-19
(8 rows)
```

### Bài 13 — 2 CTE: tính doanh thu theo khách → xếp hạng
```text
 customer_id | total_revenue | rnk
-------------+---------------+-----
           1 |       1850.00 |   1
           2 |       1600.00 |   2
           3 |        300.00 |   3
           4 |        150.00 |   4
(4 rows)
```

### Bài 16 — Running total (SUM OVER) theo khách hàng
```text
 customer_id | order_date | amount  | running_total
-------------+------------+---------+--------------
           1 | 2026-04-19 |   50.00 |        50.00
           1 | 2026-05-09 |  300.00 |       350.00
           1 | 2026-05-24 | 1500.00 |      1850.00
           2 | 2026-05-19 | 1500.00 |      1500.00
           2 | 2026-05-27 |  100.00 |      1600.00
           3 | 2026-05-14 |  300.00 |       300.00
           4 | 2026-05-26 |   50.00 |        50.00
           4 | 2026-05-28 |  100.00 |       150.00
(8 rows)
```
**Nhận xét**: Window function giữ nguyên 8 dòng gốc, mỗi dòng hiện cột running_total cộng dồn theo thứ tự ngày. Khách 1 lũy kế từ 50 → 350 → 1850. Nếu dùng GROUP BY thì chỉ còn 4 dòng và mất thông tin chi tiết từng đơn.

### Bài 18 — RANK vs DENSE_RANK
```text
 customer_id | total_amount | r_rank | d_rank
-------------+--------------+--------+--------
           1 |      1850.00 |      1 |      1
           2 |      1600.00 |      2 |      2
           3 |       300.00 |      3 |      3
           4 |       150.00 |      4 |      4
(4 rows)
```

### Bài 21 — EXPLAIN ANALYZE (trước khi tạo index)
```text
                                         QUERY PLAN
--------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..1.10 rows=3 width=32) (actual time=0.009..0.011 rows=3 loops=1)
   Filter: (customer_id = 1)
   Rows Removed by Filter: 5
 Planning Time: 0.052 ms
 Execution Time: 0.024 ms
```
**Ghi chú**: Với chỉ 8 dòng, Postgres chọn Seq Scan vì chi phí khởi tạo Index Scan cao hơn lợi ích nó mang lại. Khi bảng đủ lớn (hàng trăm nghìn dòng), Postgres sẽ chuyển sang Index Scan nhờ index `idx_orders_customer_id` đã tạo ở Bài 22.

## 3. Trả lời câu hỏi lý thuyết

### Khi nào dùng JOIN?
- **INNER JOIN**: Khi chỉ cần lấy bản ghi có liên kết ở cả 2 bảng. VD: danh sách khách hàng đã mua hàng.
- **LEFT JOIN**: Khi cần giữ toàn bộ bảng bên trái, dù bên phải không có match (hiện NULL). VD: liệt kê tất cả khách hàng kể cả chưa có đơn.
- **FULL OUTER JOIN**: Khi muốn hợp tất cả dữ liệu từ cả 2 bảng, phục vụ kiểm tra dữ liệu mồ côi (orphan audit).

### Khi nào dùng CTE thay vì Subquery?
- **Subquery** phù hợp khi logic đơn giản, chạy 1 lần, nằm gọn trong WHERE hoặc FROM.
- **CTE** (`WITH ... AS`) phù hợp khi chuỗi xử lý phức tạp, nhiều bước, cần tái sử dụng kết quả trung gian. CTE giúp code dễ đọc, dễ debug, tránh lặp lại subquery giống nhau (DRY principle). CTE đệ quy còn giải được bài toán sinh chuỗi ngày (Bài 15).

### GROUP BY khác gì WINDOW FUNCTION?
- **GROUP BY**: Thu gọn (collapse) dữ liệu — mỗi nhóm chỉ còn 1 dòng đại diện. Mất chi tiết từng bản ghi gốc. Dùng khi chỉ cần giá trị tổng hợp.
- **WINDOW FUNCTION** (`OVER PARTITION BY`): Tính toán trên một phân vùng/khung dữ liệu nhưng **giữ nguyên toàn bộ số dòng gốc**, thêm cột kết quả bên cạnh. Dùng khi cần cả chi tiết đơn hàng lẫn tổng theo khách trên cùng 1 output.

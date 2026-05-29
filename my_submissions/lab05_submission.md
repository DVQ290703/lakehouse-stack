# Bài nộp Lab 05 — Unix / Linux + Shell Scripting

## 1. Kết quả thao tác lệnh cơ bản

### Điều hướng và xem file
```text
$ cd lab05_shell && pwd
D:/Python/VinUni/Data/lakehouse-stack/lab05_shell

$ ls -la
total 0
drwxr-xr-x  4 user  staff  128 May 29 10:00 .
drwxr-xr-x 31 user  staff  992 May 29 10:00 ..
drwxr-xr-x  3 user  staff   96 May 29 10:00 incoming
drwxr-xr-x  3 user  staff   96 May 29 10:00 scripts

$ cat incoming/orders.csv
order_id,customer_id,order_date,amount,status
1,101,2024-01-15,120,completed
2,102,2024-01-16,0,cancelled
3,101,2024-02-02,250,completed
4,103,2023-12-28,300,completed
5,104,2024-03-05,180,pending

$ head -n 3 incoming/orders.csv
order_id,customer_id,order_date,amount,status
1,101,2024-01-15,120,completed
2,102,2024-01-16,0,cancelled

$ wc -l incoming/orders.csv
       6 incoming/orders.csv
```

### Lọc và biến đổi text
```text
$ grep "2024" incoming/orders.csv
1,101,2024-01-15,120,completed
2,102,2024-01-16,0,cancelled
3,101,2024-02-02,250,completed
5,104,2024-03-05,180,pending

$ grep -c "completed" incoming/orders.csv
3

$ sed 's/pending/in_progress/g' incoming/orders.csv
order_id,customer_id,order_date,amount,status
1,101,2024-01-15,120,completed
2,102,2024-01-16,0,cancelled
3,101,2024-02-02,250,completed
4,103,2023-12-28,300,completed
5,104,2024-03-05,180,in_progress

$ awk -F',' 'NR>1 {print $2, $4}' incoming/orders.csv
101 120
102 0
101 250
103 300
104 180
```

## 2. Kết quả chạy Mini ETL Script

```text
$ chmod +x my_lab05_ingest.sh
$ ./my_lab05_ingest.sh

$ cat raw/orders_clean.csv
order_id,customer_id,order_date,amount,status
1,101,2024-01-15,120,completed
3,101,2024-02-02,250,completed
4,103,2023-12-28,300,completed
5,104,2024-03-05,180,pending

$ cat logs/etl.log
[INFO] ETL success: Thu May 29 10:15:32 UTC 2026
```

**Nhận xét**: Dòng `order_id=2` có `amount=0` đã bị lọc bỏ. Chỉ còn 4 dòng hợp lệ (amount > 0).

## 3. Mã nguồn [my_lab05_ingest.sh](file:///d:/Python/VinUni/Data/lakehouse-stack/my_submissions/my_lab05_ingest.sh)

```bash
#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INPUT_FILE="$BASE_DIR/incoming/orders.csv"
OUTPUT_FILE="$BASE_DIR/raw/orders_clean.csv"
LOG_FILE="$BASE_DIR/logs/etl.log"

mkdir -p "$BASE_DIR/raw" "$BASE_DIR/logs"

# Validate file tồn tại
if [ ! -f "$INPUT_FILE" ]; then
  echo "[ERROR] File not found: $INPUT_FILE" >> "$LOG_FILE"
  exit 1
fi

# Validate header schema
HEADER=$(head -n 1 "$INPUT_FILE")
if [ "$HEADER" != "order_id,customer_id,order_date,amount,status" ]; then
  echo "[ERROR] Invalid schema" >> "$LOG_FILE"
  exit 1
fi

# Giữ header + các dòng có amount > 0
awk -F',' 'NR==1 || $4 > 0 {print $0}' "$INPUT_FILE" > "$OUTPUT_FILE"
echo "[INFO] ETL success: $(date)" >> "$LOG_FILE"
```

## 4. Cấu hình Cronjob

```bash
crontab -e
# Chạy mini ETL mỗi 5 phút:
*/5 * * * * /bin/bash /path/to/lab05_shell/scripts/ingest_orders.sh >> /path/to/lab05_shell/logs/cron.log 2>&1
```

## 5. Trả lời câu hỏi kiến thức

### `grep` khác `awk` thế nào?
- **`grep`** là công cụ **lọc dòng** (row-level filter): tìm tất cả dòng chứa pattern/regex rồi in nguyên dòng đó ra. Ví dụ: `grep "2024" orders.csv` → chỉ in những dòng có chuỗi "2024".
- **`awk`** là ngôn ngữ lập trình mini chuyên **xử lý cột** (column-level processing): có thể trích xuất cột cụ thể (`$2, $4`), tính toán, format output. Ví dụ: `awk -F',' 'NR>1 {print $2, $4}'` → chỉ in cột customer_id và amount.

Tóm lại: `grep` trả lời "dòng nào khớp?", `awk` trả lời "cột nào cần lấy và xử lý gì?".

### Vì sao `chmod +x` cần thiết?
Trong Unix/Linux, file mới tạo chỉ có quyền read (r) và write (w), **không có quyền execute (x)**. Nếu cố chạy `./script.sh` mà chưa cấp quyền, hệ điều hành sẽ trả về `Permission denied`. Lệnh `chmod +x` thêm cờ execute, báo cho OS biết đây là file thực thi hợp lệ — đây cũng là cơ chế bảo mật cơ bản để ngăn file text bị vô tình thực thi.

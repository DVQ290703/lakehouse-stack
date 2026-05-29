#!/bin/bash
set -e

# Xác định file input/output trong cùng thư mục
INPUT_FILE="my_ecommerce_orders.csv"
OUTPUT_FILE="my_ecommerce_clean_bash.csv"
LOG_FILE="my_ingest.log"

# Kiểm tra file input
if [ ! -f "$INPUT_FILE" ]; then
  echo "[ERROR] Missing input file: $INPUT_FILE" >> "$LOG_FILE"
  exit 1
fi

# Validate header
HEADER=$(head -n 1 "$INPUT_FILE")
if [ "$HEADER" != "txn_id,user_id,txn_date,amount,txn_status" ]; then
  echo "[ERROR] Invalid Schema!" >> "$LOG_FILE"
  exit 1
fi

# Chạy awk: Giữ lại header (NR==1) HOẶC lọc các dòng có cột 4 (amount) lớn hơn 0
awk -F',' 'NR==1 || $4 > 0 {print $0}' "$INPUT_FILE" > "$OUTPUT_FILE"

# Ghi log thành công
echo "[INFO] Bash ETL completed successfully at $(date)" >> "$LOG_FILE"

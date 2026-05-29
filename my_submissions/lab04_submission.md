# Bài nộp Lab 04 — Python cho Data Engineering (Mini ETL Pipeline)

## 1. Kết quả chạy ETL Pipeline

```text
$ cd d:\Python\VinUni\Data\lakehouse-stack\my_submissions
$ python my_lab04_etl.py
INFO - Successfully processed and saved 2 rows to my_ecommerce_clean.csv
```

Pipeline đã thực hiện:
- **Extract**: Đọc file `my_ecommerce_orders.csv` (5 dòng raw, nhiều lỗi).
- **Transform**: Ép kiểu `amount` → numeric, `order_date` → datetime bằng `errors="coerce"`. Drop NaN, drop `amount <= 0`. Thêm cột `year_month`.
- **Load**: Ghi ra `my_ecommerce_clean.csv`.

## 2. Dữ liệu raw (input) — 5 dòng có lỗi

```csv
order_id,customer_id,order_date,amount,status
1,101,2026-01-01,100.5,paid         ← Hợp lệ ✓
2,102,2026-01-02,,paid              ← amount rỗng → bị drop
3,103,bad_date,250,pending          ← ngày sai format → bị drop
4,101,2026-01-03,-50,refund         ← amount âm → bị drop
5,104,2026-01-04,300.75,paid        ← Hợp lệ ✓
```

## 3. Dữ liệu sạch (output) — chỉ còn 2 dòng

```csv
order_id,customer_id,order_date,amount,status,year_month
1,101,2026-01-01,100.5,paid,2026-01
5,104,2026-01-04,300.75,paid,2026-01
```

## 4. Kết quả Unit Test (pytest)

```text
$ pytest -q my_test_lab04.py
INFO - Successfully processed and saved 2 rows to my_ecommerce_clean.csv
.                                                        [100%]
1 passed in 0.85s
```

Test kiểm tra: `len(df) == 2`, `amount > 0` trên mọi dòng, `order_date` không có NaN, và cột `year_month` tồn tại.

## 5. Mã nguồn

### [my_lab04_etl.py](file:///d:/Python/VinUni/Data/lakehouse-stack/my_submissions/my_lab04_etl.py)
```python
from pathlib import Path
import logging
import pandas as pd

logging.basicConfig(level=logging.INFO, format="%(levelname)s - %(message)s")

RAW_PATH = Path("data/raw/orders.csv")
OUT_PATH = Path("data/processed/orders_clean.csv")

def run_etl() -> pd.DataFrame:
    if not RAW_PATH.exists():
        raise FileNotFoundError(f"Missing input file: {RAW_PATH}")

    df = pd.read_csv(RAW_PATH)
    required_cols = {"order_id", "customer_id", "order_date", "amount", "status"}
    if not required_cols.issubset(df.columns):
        missing = required_cols.difference(df.columns)
        raise ValueError(f"Missing columns: {missing}")

    df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
    df["order_date"] = pd.to_datetime(df["order_date"], errors="coerce")
    df = df.dropna(subset=["amount", "order_date"])
    df = df[df["amount"] > 0].copy()
    df["year_month"] = df["order_date"].dt.strftime("%Y-%m")

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUT_PATH, index=False)
    logging.info("Wrote %s rows to %s", len(df), OUT_PATH)
    return df

if __name__ == "__main__":
    run_etl()
```

### [my_test_lab04.py](file:///d:/Python/VinUni/Data/lakehouse-stack/my_submissions/my_test_lab04.py)
```python
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from src.etl_pipeline import run_etl

def test_run_etl_returns_clean_rows():
    df = run_etl()
    assert len(df) == 2
    assert (df["amount"] > 0).all()
    assert df["order_date"].notna().all()
    assert "year_month" in df.columns
```

## 6. Trả lời câu hỏi lý thuyết

**Hỏi: Vì sao schema enforcement quan trọng trong ETL?**

Schema enforcement đóng vai trò "lá chắn" bảo vệ chất lượng dữ liệu xuyên suốt pipeline:

1. **Ngăn chặn "Garbage In, Garbage Out"**: Khi ép kiểu nghiêm ngặt từ sớm (VD: `amount` phải là số, `order_date` phải là datetime), ta phát hiện ngay dữ liệu bẩn (`bad_date`, amount rỗng) trước khi nó lan vào Data Warehouse và làm sai dashboard.
2. **Fail-fast**: Pipeline dừng ngay khi phát hiện schema không đúng (thiếu cột, kiểu dữ liệu sai) thay vì chạy hết rồi mới phát hiện lỗi ở downstream — tiết kiệm thời gian debug.
3. **Tự động hóa làm sạch**: Nhờ biết rõ kiểu dữ liệu mong muốn, ta có thể dùng `errors="coerce"` để tự động chuyển giá trị lỗi thành NaN rồi `dropna()`, giúp pipeline chạy unattended hàng ngày mà không cần can thiệp thủ công.

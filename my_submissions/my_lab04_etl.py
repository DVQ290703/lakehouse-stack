from pathlib import Path
import logging
import pandas as pd

logging.basicConfig(level=logging.INFO, format="%(levelname)s - %(message)s")

RAW_FILE = Path("my_ecommerce_orders.csv")
CLEAN_FILE = Path("my_ecommerce_clean.csv")

def run_my_etl() -> pd.DataFrame:
    if not RAW_FILE.exists():
        raise FileNotFoundError(f"Cannot find data file: {RAW_FILE}")

    df = pd.read_csv(RAW_FILE)
    
    # 1. Schema Check
    expected_cols = {"txn_id", "user_id", "txn_date", "amount", "txn_status"}
    if not expected_cols.issubset(df.columns):
        raise ValueError(f"Missing required columns")

    # 2. Data Casting & Cleaning
    # Ép kiểu dữ liệu, nếu lỗi thì biến thành NaN (coerce)
    df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
    df["txn_date"] = pd.to_datetime(df["txn_date"], errors="coerce")
    
    # Drop các dòng bị NaN ở 2 cột quan trọng
    df = df.dropna(subset=["amount", "txn_date"])
    
    # Lọc bỏ số âm
    df = df[df["amount"] > 0].copy()
    
    # 3. Add derived column
    df["txn_month"] = df["txn_date"].dt.strftime("%Y-%m")

    # 4. Load
    CLEAN_FILE.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(CLEAN_FILE, index=False)
    logging.info(f"Successfully processed and saved {len(df)} rows to {CLEAN_FILE}")
    
    return df

if __name__ == "__main__":
    run_my_etl()

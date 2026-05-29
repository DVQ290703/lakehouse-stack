import pytest
import pandas as pd
from my_lab04_etl import run_my_etl

def test_my_etl_pipeline():
    # Chạy hàm ETL
    df = run_my_etl()
    
    # Kiểm tra số lượng record trả về phải là 2 (từ 5 record gốc chứa lỗi)
    assert len(df) == 2, "Should only return 2 clean rows"
    
    # Kiểm tra amount luôn dương
    assert (df["amount"] > 0).all(), "All amounts must be positive"
    
    # Kiểm tra ngày tháng không bị null
    assert df["txn_date"].notna().all(), "All dates must be valid"
    
    # Kiểm tra cột mới được sinh ra
    assert "txn_month" in df.columns, "Derived column txn_month is missing"

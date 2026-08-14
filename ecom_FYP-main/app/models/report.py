from pydantic import BaseModel
from datetime import datetime
from typing import List

class SalesReportItem(BaseModel):
    product_id: str
    product_name: str
    quantity_sold: int
    revenue: float
    date: datetime

class InventoryReportItem(BaseModel):
    product_id: str
    product_name: str
    quantity_in_stock: int
    low_stock_threshold: int

class CustomerActivityReportItem(BaseModel):
    user_id: str
    total_orders: int
    total_spent: float
    last_order_date: datetime

class OrderStatusReportItem(BaseModel):
    order_id: str
    user_id: str
    status: str
    created_at: datetime
    last_updated: datetime

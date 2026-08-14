from pydantic import BaseModel, Field
from datetime import datetime
from typing import List, Optional


class OrderRequest(BaseModel):
    order_id: str

class ProductItem(BaseModel):
    product_id: str
    quantity: int

class TrackingHistory(BaseModel):
    status: str
    updated_at: datetime

class OrderCreate(BaseModel):
    user_id: str
    products: List[ProductItem]
    total_price: float
    tracking_history: List[TrackingHistory]



class OrderResponse(BaseModel):
    id: str
    user_id: str
    products: List[ProductItem]
    total_price: float
    status: str
    tracking_history: List[TrackingHistory]
    created_at: datetime

    class Config:
        # If using MongoDB, you might have _id, so rename it to id in the response
        alias_generator = lambda string: string if string != "_id" else "id"
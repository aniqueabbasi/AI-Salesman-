from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class PromotionCreate(BaseModel):
    promotion_code: str
    discount_type: str  # e.g., percentage, fixed
    discount_value: float
    start_date: datetime
    end_date: datetime
    products: Optional[List[str]] = []  # List of product IDs (optional)
    minimum_order_value: Optional[float] = 0
    usage_limit: Optional[int] = 0

class PromotionUpdate(BaseModel):
    discount_value: Optional[float]
    products: Optional[List[str]]
    minimum_order_value: Optional[float]
    usage_limit: Optional[int]

class PromotionResponse(BaseModel):
    promotion_code: str
    discount_type: str
    discount_value: float
    start_date: datetime
    end_date: datetime
    products: List[str]
    minimum_order_value: float
    usage_limit: int

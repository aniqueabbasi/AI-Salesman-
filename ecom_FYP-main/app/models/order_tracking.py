from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

class OrderStatusUpdate(BaseModel):
    status: str  # e.g., pending, shipped, delivered, canceled

class TrackingHistory(BaseModel):
    status: str
    updated_at: datetime

class OrderTrackingResponse(BaseModel):
    id: str
    status: str
    tracking_history: List[TrackingHistory]

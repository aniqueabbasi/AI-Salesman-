from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from bson import ObjectId

# Utility function to convert ObjectId to string
def objectid_to_str(obj):
    if isinstance(obj, ObjectId):
        return str(obj)
    return obj

class NotificationRequest(BaseModel):
    user_id: str

class NotificationCreate(BaseModel):
    user_id: str
    title: str
    message: str
    type: Optional[str] = "general"

class NotificationResponse(NotificationCreate):
    id: str
    is_read: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        # This config option tells Pydantic to use the objectid_to_str function
        json_encoders = {
            ObjectId: objectid_to_str
        }

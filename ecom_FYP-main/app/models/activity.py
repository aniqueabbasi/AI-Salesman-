from pydantic import BaseModel
from datetime import datetime

class UserActivityCreate(BaseModel):
    user_id: str
    action: str
    details: dict

class UserActivityResponse(UserActivityCreate):
    id: str
    timestamp: datetime

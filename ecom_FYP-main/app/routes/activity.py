from fastapi import APIRouter
from app.models.activity import UserActivityCreate
from app.services.activity_service import log_user_activity

router = APIRouter()

@router.post("/", response_model=str)
def log_activity(activity: UserActivityCreate):
    return {"activity_id": log_user_activity(activity)}

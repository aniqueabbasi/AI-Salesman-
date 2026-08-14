from fastapi import APIRouter, HTTPException
from app.models.notification import NotificationCreate, NotificationResponse,NotificationRequest
from app.services.notification_service import create_notification, get_user_notifications, mark_notification_as_read

router = APIRouter()

@router.post("/", response_model=NotificationResponse)
def send_notification(notification: NotificationCreate):
    return create_notification(notification)

@router.get("/user-notification", response_model=list)
def fetch_user_notifications(request: NotificationRequest):
    return get_user_notifications(request.user_id)

@router.put("/{notification_id}/read")
def mark_as_read(notification_id: str):
    mark_notification_as_read(notification_id)
    return {"message": "Notification marked as read"}

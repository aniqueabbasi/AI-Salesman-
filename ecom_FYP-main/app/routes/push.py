from fastapi import APIRouter, HTTPException
from app.services.push_service import send_push_notification
from app.models.push import PushNotificationRequest

router = APIRouter()

@router.post("/")
def push_notification(notification: PushNotificationRequest):
    try:
        response = send_push_notification(notification.token, notification.title, notification.body)
        return {"message": "Notification sent", "response": response}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

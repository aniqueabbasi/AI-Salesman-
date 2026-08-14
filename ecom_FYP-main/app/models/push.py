from pydantic import BaseModel

class PushNotificationRequest(BaseModel):
    token: str
    title: str
    body: str
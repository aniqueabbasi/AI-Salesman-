from app.db.database import db
from datetime import datetime
from bson.objectid import ObjectId

notifications_collection = db['notifications']

def create_notification(notification_data):
    notification = {
        "user_id": notification_data.user_id,
        "title": notification_data.title,
        "message": notification_data.message,
        "type": notification_data.type,
        "is_read": False,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    result = notifications_collection.insert_one(notification)
        # Retrieve the inserted notification, including the generated _id
    inserted_notification = notifications_collection.find_one({"_id": result.inserted_id})
    
    # Convert _id to id and return as NotificationResponse
    inserted_notification['id'] = str(inserted_notification['_id'])
    del inserted_notification['_id']  # Remove _id as it's no longer needed
    return inserted_notification

def get_user_notifications(user_id):
    notifications = list(notifications_collection.find({"user_id": user_id}))
    # Convert ObjectId to string for each notification
    for notification in notifications:
        notification['id'] = str(notification['_id'])
        del notification['_id']  # Remove _id as it's no longer needed
    return notifications

def mark_notification_as_read(notification_id):
    notifications_collection.update_one({"_id": ObjectId(notification_id)}, {"$set": {"is_read": True}})

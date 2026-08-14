from app.db.database import db
from datetime import datetime

user_activity_collection = db['user_activity']

def log_user_activity(activity_data):
    activity = {
        "user_id": activity_data.user_id,
        "action": activity_data.action,
        "details": activity_data.details,
        "timestamp": datetime.utcnow()
    }
    result = user_activity_collection.insert_one(activity)
    return str(result.inserted_id)

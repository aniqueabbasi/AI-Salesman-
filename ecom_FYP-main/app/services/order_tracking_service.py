from app.db.database import db
from datetime import datetime
from bson.objectid import ObjectId

orders_collection = db["orders"]

def update_order_status(order_id: str, status: str):
    tracking_entry = {
        "status": status,
        "updated_at": datetime.utcnow()
    }
    result = orders_collection.update_one(
        {"_id": ObjectId(order_id)},
        {
            "$set": {"status": status},
            "$push": {"tracking_history": tracking_entry}
        }
    )
    return result.matched_count > 0

def get_order_tracking(order_id: str):
    order = orders_collection.find_one({"_id": ObjectId(order_id)}, {"status": 1, "tracking_history": 1})
    if not order:
        return None
    return {
        "id": str(order["_id"]),
        "status": order["status"],
        "tracking_history": order.get("tracking_history", [])
    }

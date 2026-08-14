from app.db.database import db
from datetime import datetime
from bson.objectid import ObjectId
from app.services.inventory_service import deduct_inventory
orders_collection = db["orders"]

# def create_order(order_data):
#     new_order = {
#         "user_id": order_data.user_id,
#         "products": [item.dict() for item in order_data.products],
#         "total_price": order_data.total_price,
#         "status": "pending",  # Default status
#         "tracking_history": [
#             {"status": "pending", "updated_at": datetime.utcnow()}
#         ],
#         "created_at": datetime.utcnow()
#     }
#     result = orders_collection.insert_one(new_order)
#     return str(result.inserted_id)
def create_order(order_data):
    # Deduct inventory for each product
    for item in order_data.products:
        if not deduct_inventory(item.product_id, item.quantity):
            raise ValueError(f"Insufficient stock for product {item.product_id}")

    # Proceed with order creation
    new_order = {
        "user_id": order_data.user_id,
        "products": [item.dict() for item in order_data.products],
        "total_price": order_data.total_price,
        "status": "pending",
        "tracking_history": [
            {"status": "pending", "updated_at": datetime.utcnow()}
        ],
        "created_at": datetime.utcnow()
    }
    result = orders_collection.insert_one(new_order)
    return str(result.inserted_id)
def get_order(order_id):
    order = orders_collection.find_one({"_id": ObjectId(order_id)})
    if not order:
        return None
    order["id"] = str(order["_id"])
    del order["_id"]
    return order

def get_all_orders():
    orders = orders_collection.find()
    return [
        {
            "id": str(order["_id"]),  # Rename _id to id
            **{key: value for key, value in order.items() if key != "_id"}  # Remove _id from the final response
        }
        for order in orders
    ]

def update_order_status(order_id: str, status: str):
    tracking_entry = {"status": status, "updated_at": datetime.utcnow()}
    result = orders_collection.update_one(
        {"_id": ObjectId(order_id)},
        {
            "$set": {"status": status},
            "$push": {"tracking_history": tracking_entry}
        }
    )
    return result.matched_count > 0

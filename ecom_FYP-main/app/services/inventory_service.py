from app.db.database import db
from bson.objectid import ObjectId

inventory_collection = db["inventory"]

def create_inventory_entry(data):
    inventory = {
        "product_id": data.product_id,
        "quantity_in_stock": data.quantity_in_stock,
        "low_stock_threshold": data.low_stock_threshold
    }
    result = inventory_collection.insert_one(inventory)
    return str(result.inserted_id)

def update_inventory(product_id: str, quantity: int):
    result = inventory_collection.update_one(
        {"product_id": product_id},
        {"$set": {"quantity_in_stock": quantity}}
    )
    return result.matched_count > 0

def get_inventory(product_id: str):
    product_id = str(product_id)
    inventory = inventory_collection.find_one({"product_id": product_id})
    if not inventory:
        return None
    inventory["_id"] = str(inventory["_id"])
    del inventory["_id"]
    return inventory

def deduct_inventory(product_id: str, quantity: int):
    inventory = inventory_collection.find_one({"product_id": product_id})
    if not inventory or inventory["quantity_in_stock"] < quantity:
        return False
    new_quantity = inventory["quantity_in_stock"] - quantity
    update_inventory(product_id, new_quantity)
    return True

def check_low_stock(product_id: str):
    inventory = inventory_collection.find_one({"product_id": product_id})
    if not inventory:
        return False
    return inventory["quantity_in_stock"] <= inventory["low_stock_threshold"]

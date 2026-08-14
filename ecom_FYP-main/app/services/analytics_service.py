from app.db.database import db

orders_collection = db['orders']

def get_total_orders():
    return orders_collection.count_documents({})

def get_total_revenue():
    pipeline = [
        {"$group": {"_id": None, "total_revenue": {"$sum": "$total_price"}}}
    ]
    result = list(orders_collection.aggregate(pipeline))
    return result[0]['total_revenue'] if result else 0

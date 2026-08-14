from app.db.database import db
from datetime import datetime
from app.models.report import SalesReportItem, InventoryReportItem, CustomerActivityReportItem, OrderStatusReportItem
from app.services.inventory_service import get_inventory
from app.services.order_service import get_all_orders

orders_collection = db["orders"]
products_collection = db["products"]
users_collection = db["users"]

# Sales Report
def generate_sales_report(start_date: datetime, end_date: datetime):
    pipeline = [
        {"$match": {"created_at": {"$gte": start_date, "$lte": end_date}}},
        {"$unwind": "$products"},
        {"$group": {
            "_id": "$products.product_id",
            "quantity_sold": {"$sum": "$products.quantity"},
            "revenue": {"$sum": {"$multiply": ["$products.quantity", "$products.price"]}}
        }},
        {"$lookup": {
            "from": "products",
            "localField": "_id",
            "foreignField": "_id",
            "as": "product"
        }},
        {"$unwind": "$product"},
        {"$project": {
            "product_id": "$_id",
            "product_name": "$product.name",
            "quantity_sold": 1,
            "revenue": 1,
            "date": end_date
        }}
    ]
    sales_data = list(orders_collection.aggregate(pipeline))
    return [SalesReportItem(**data) for data in sales_data]

# Inventory Report
def generate_inventory_report():
    products = list(products_collection.find())
    inventory_report = []
    for product in products:
        inventory_data = get_inventory(product["_id"])
        inventory_report.append(InventoryReportItem(
            product_id=inventory_data["product_id"],
            product_name=product["name"],
            quantity_in_stock=inventory_data["quantity_in_stock"],
            low_stock_threshold=inventory_data["low_stock_threshold"]
        ))
    return inventory_report

# Customer Activity Report
def generate_customer_activity_report():
    users = list(users_collection.find())
    activity_report = []
    for user in users:
        orders = list(orders_collection.find({"user_id": user["_id"]}))
        total_orders = len(orders)
        total_spent = sum(order["total_price"] for order in orders)
        last_order_date = max(order["created_at"] for order in orders) if orders else None
        activity_report.append(CustomerActivityReportItem(
            user_id=user["_id"],
            total_orders=total_orders,
            total_spent=total_spent,
            last_order_date=last_order_date
        ))
    return activity_report

# Order Status Report
def generate_order_status_report(start_date: datetime, end_date: datetime):
    orders = list(orders_collection.find({"created_at": {"$gte": start_date, "$lte": end_date}}))
    status_report = []
    for order in orders:
        status_report.append(OrderStatusReportItem(
            order_id=str(order["_id"]),
            user_id=order["user_id"],
            status=order["status"],
            created_at=order["created_at"],
            last_updated=order["tracking_history"][-1]["updated_at"] if order.get("tracking_history") else order["created_at"]
        ))
    return status_report

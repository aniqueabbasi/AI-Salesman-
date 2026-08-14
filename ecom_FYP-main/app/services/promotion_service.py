from app.db.database import db
from datetime import datetime
from app.models.promotion import PromotionCreate, PromotionUpdate
from bson.objectid import ObjectId

promotions_collection = db["promotions"]

def create_promotion(data: PromotionCreate):
    promotion = {
        "promotion_code": data.promotion_code,
        "discount_type": data.discount_type,
        "discount_value": data.discount_value,
        "start_date": data.start_date,
        "end_date": data.end_date,
        "products": data.products,
        "minimum_order_value": data.minimum_order_value,
        "usage_limit": data.usage_limit,
        "used_count": 0  # Track how many times the promo has been used
    }
    result = promotions_collection.insert_one(promotion)
    return str(result.inserted_id)

def get_promotion(promotion_code: str):
    promotion = promotions_collection.find_one({"promotion_code": promotion_code})
    if not promotion:
        return None
    promotion["_id"] = str(promotion["_id"])
    return promotion

def apply_promotion(promotion_code: str, order_total: float, product_ids: list[str]):
    promotion = get_promotion(promotion_code)
    if not promotion:
        return None
    
    # Check if the promotion is active
    if datetime.utcnow() < promotion["start_date"] or datetime.utcnow() > promotion["end_date"]:
        return None

    # Check if the promotion is for specific products
    if promotion["products"] and not any(product_id in promotion["products"] for product_id in product_ids):
        return None

    # Check minimum order value
    if order_total < promotion["minimum_order_value"]:
        return None

    # Check usage limit
    if promotion["used_count"] >= promotion["usage_limit"]:
        return None

    # Apply discount
    discount = 0
    if promotion["discount_type"] == "percentage":
        discount = (order_total * promotion["discount_value"]) / 100
    elif promotion["discount_type"] == "fixed":
        discount = promotion["discount_value"]

    # Update usage count
    promotions_collection.update_one(
        {"promotion_code": promotion_code},
        {"$inc": {"used_count": 1}}
    )
    
    return discount

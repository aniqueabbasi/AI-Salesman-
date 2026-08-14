from typing_extensions import Optional
from app.db.database import db
from datetime import datetime
from bson.errors import InvalidId
from bson.objectid import ObjectId
from app.models.product import ProductResponse
products_collection = db['products']

def create_product(product_data, seller=None):
    """Insert a product. When `seller` is given the listing is owned by them."""
    product = {
        "name": product_data.name,
        "description": product_data.description,
        "price": product_data.price,
        "stock": product_data.stock,
        "category": product_data.category,
        "images": list(getattr(product_data, "images", []) or []),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    if seller:
        product["seller_id"] = str(seller.get("_id"))
        product["seller_email"] = seller.get("email")
        product["shop_name"] = seller.get("shop_name")
    result = products_collection.insert_one(product)
    return str(result.inserted_id)


def get_products_by_seller(seller_id: str):
    """Every listing owned by one seller, newest first."""
    products = list(
        products_collection.find({"seller_id": seller_id}).sort("created_at", -1)
    )
    return [ProductResponse.from_mongo(product) for product in products]

# def get_all_products():
#     products = list(products_collection.find({}))
#     # Convert MongoDB documents to ProductResponse instances
#     return [ProductResponse.from_mongo(product) for product in products]
def get_all_products(
    skip: int = 0, 
    limit: int = 20, 
    category: Optional[str] = None, 
    search: Optional[str] = None,
    sort_by: str = "created_at",
    sort_order: int = -1  # -1 for descending, 1 for ascending
):
    query = {}
    
    # Add category filter if provided
    if category:
        query["category"] = category
    
    # Add name search if provided
    if search:
        query["name"] = {"$regex": search, "$options": "i"}  # case-insensitive search
    
    # Create sort dictionary
    sort_dict = {sort_by: sort_order}
    
    products = list(products_collection.find(query).sort(sort_by, sort_order).skip(skip).limit(limit))
    # Convert MongoDB documents to ProductResponse instances
    return [ProductResponse.from_mongo(product) for product in products]

def get_product_count(category: Optional[str] = None, search: Optional[str] = None):
    query = {}
    
    # Add category filter if provided
    if category:
        query["category"] = category
    
    # Add name search if provided
    if search:
        query["name"] = {"$regex": search, "$options": "i"}  # case-insensitive search
        
    return products_collection.count_documents(query)

def get_product_by_id(product_id):
    try:
        oid = ObjectId(product_id)
    except (InvalidId, TypeError):
        # A malformed id is simply "not found" rather than a 500.
        return None
    return products_collection.find_one({"_id": oid})

def update_product(product_id, updates):
    updates["updated_at"] = datetime.utcnow()
    products_collection.update_one({"_id": ObjectId(product_id)}, {"$set": updates})

def delete_product(product_id):
    products_collection.delete_one({"_id": ObjectId(product_id)})

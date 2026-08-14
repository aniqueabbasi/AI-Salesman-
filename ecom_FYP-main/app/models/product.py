
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from bson import ObjectId

def objectid_to_str(obj):
    if isinstance(obj, ObjectId):
        return str(obj)
    return obj

class ProductRequest(BaseModel):
    product_id: str

class ProductCreate(BaseModel):
    name: str
    description: str
    price: float
    stock: int
    category: str
    # Absolute URLs (uploaded via /products/upload-image) or bundled asset paths.
    images: List[str] = []



class ProductResponse(BaseModel):
    id: str
    name: str | None = None
    description: str | None = None
    price: float | None = None
    stock: int | None = None
    category: str | None = None
    # Without this the Flutter app receives products with no artwork, since the
    # response model drops any field it does not declare.
    images: List[str] = []
    # Who listed it. Null for the seeded starter catalogue.
    seller_id: str | None = None
    seller_email: str | None = None
    shop_name: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None

    class Config:
        # This config option tells Pydantic to use the objectid_to_str function
        json_encoders = {
            ObjectId: objectid_to_str
        }

    @classmethod
    def from_mongo(cls, mongo_dict):
        """
        Convert a MongoDB document (which contains _id) to a Pydantic model instance.
        """
        mongo_dict = dict(mongo_dict)  # make a copy
        # Map field names
        mongo_dict['id'] = str(mongo_dict.pop('_id'))
        # actual_price → price
        if 'price' not in mongo_dict and 'actual_price' in mongo_dict:
            mongo_dict['price'] = mongo_dict['actual_price']
        # product_name → name
        if 'name' not in mongo_dict and 'product_name' in mongo_dict:
            mongo_dict['name'] = mongo_dict['product_name']
        # Fallbacks for dates
        now = datetime.utcnow()
        mongo_dict.setdefault('created_at', now)
        mongo_dict.setdefault('updated_at', now)
        return cls(**mongo_dict)

class PaginatedProductResponse(BaseModel):
    items: List[ProductResponse]
    total: int
    skip: int
    limit: int
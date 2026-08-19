from app.db.database import users_collection
from app.core.security import hash_password, verify_password, create_access_token
from bson.objectid import ObjectId

def create_user(user_data):
    hashed_password = hash_password(user_data.password)
    role = getattr(user_data, "role", "customer")
    # role may arrive as the UserRole enum; store the plain string
    role = getattr(role, "value", role)
    user = {
        "email": user_data.email,
        "password": hashed_password,
        "is_admin": user_data.is_admin,
        "role": role,
        "shop_name": getattr(user_data, "shop_name", None),
        "full_name": getattr(user_data, "full_name", None),
        "phone": getattr(user_data, "phone", None),
    }
    result = users_collection.insert_one(user)
    return str(result.inserted_id)

def get_user_by_email(email: str):
    return users_collection.find_one({"email": email})

def update_user_profile(user_id: str, updates: dict):
    """Apply the supplied profile fields. Keys with a None value are left
    untouched so a partial update never blanks a field."""
    changes = {k: v for k, v in updates.items() if v is not None}
    if not changes:
        return
    users_collection.update_one({"_id": ObjectId(user_id)}, {"$set": changes})

def authenticate_user(email: str, password: str):
    user = users_collection.find_one({"email": email})
    if user and verify_password(password, user["password"]):
        return user
    return None

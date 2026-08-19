from enum import Enum

from pydantic import BaseModel, EmailStr


class UserRole(str, Enum):
    """Who the account belongs to.

    customer - browses and buys products
    seller   - owns a storefront and manages their own products
    """

    customer = "customer"
    seller = "seller"


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    role: UserRole = UserRole.customer
    # Kept for backwards compatibility with the existing admin panel.
    is_admin: bool = False
    # Optional shop name, only meaningful for sellers.
    shop_name: str | None = None
    # Contact details shown on the profile screen.
    full_name: str | None = None
    phone: str | None = None


class UserProfileUpdate(BaseModel):
    """Fields an account holder may change about themselves. Email and role
    are deliberately absent: one identifies the account, the other decides
    what it may do."""

    full_name: str | None = None
    phone: str | None = None
    shop_name: str | None = None


class UserResponse(BaseModel):
    id: str
    email: EmailStr
    role: UserRole = UserRole.customer
    is_admin: bool = False
    shop_name: str | None = None
    full_name: str | None = None
    phone: str | None = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str

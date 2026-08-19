from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException

from app.core.deps import get_current_user
from app.core.security import create_access_token
from app.models.user import UserCreate, UserLogin, UserProfileUpdate
from app.services.user_service import (
    authenticate_user,
    create_user,
    get_user_by_email,
    update_user_profile,
)

router = APIRouter()


def _public_user(user: dict) -> dict:
    """Strip the password hash before sending a user back to the client."""
    return {
        "id": str(user.get("_id")),
        "email": user.get("email"),
        "role": user.get("role", "customer"),
        "is_admin": user.get("is_admin", False),
        "shop_name": user.get("shop_name"),
        "full_name": user.get("full_name"),
        "phone": user.get("phone"),
    }


@router.get("/me")
def read_me(user: dict = Depends(get_current_user)):
    """The signed-in account's own profile."""
    return _public_user(user)


@router.put("/me")
def update_me(
    updates: UserProfileUpdate,
    user: dict = Depends(get_current_user),
):
    """Change the signed-in account's own contact details."""
    update_user_profile(str(user.get("_id")), updates.dict())
    refreshed = get_user_by_email(user.get("email"))
    return _public_user(refreshed or user)


@router.post("/signup")
def signup(user: UserCreate):
    if get_user_by_email(user.email):
        raise HTTPException(status_code=400, detail="An account with that email already exists")

    user_id = create_user(user)
    return {
        "message": "User created",
        "user_id": user_id,
        "role": user.role.value,
    }


@router.post("/signin")
def signin(login_data: UserLogin):
    user = authenticate_user(login_data.email, login_data.password)
    if not user:
        raise HTTPException(status_code=400, detail="Invalid credentials")

    role = user.get("role", "customer")
    # The role travels inside the token so protected routes can authorise
    # without a second lookup, and the client can route on it after login.
    token = create_access_token(
        {"sub": user["email"], "role": role}, timedelta(hours=12)
    )
    return {
        "access_token": token,
        "token_type": "bearer",
        "role": role,
        "user": _public_user(user),
    }


@router.get("/me")
def me(user: dict = Depends(get_current_user)):
    return _public_user(user)

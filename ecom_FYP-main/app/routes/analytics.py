from fastapi import APIRouter
from app.services.analytics_service import get_total_orders, get_total_revenue

router = APIRouter()

@router.get("/orders")
def total_orders():
    return {"total_orders": get_total_orders()}

@router.get("/revenue")
def total_revenue():
    return {"total_revenue": get_total_revenue()}

from fastapi import APIRouter, Depends

from app.core.deps import require_seller
from app.services.analytics_service import get_total_orders, get_total_revenue
from app.services.seller_service import get_seller_summary

router = APIRouter()


@router.get("/orders")
def total_orders():
    return {"total_orders": get_total_orders()}


@router.get("/revenue")
def total_revenue():
    return {"total_revenue": get_total_revenue()}


@router.get("/seller/summary")
def seller_summary(seller: dict = Depends(require_seller)):
    """Dashboard headline figures for the signed-in seller only."""
    summary = get_seller_summary(str(seller.get("_id")))
    summary["shop_name"] = seller.get("shop_name")
    return summary

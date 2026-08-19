from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from app.core.deps import require_seller
from app.services.report_service import (
    generate_sales_report,
    generate_inventory_report,
    generate_customer_activity_report,
    generate_order_status_report
)
from app.services.seller_service import get_seller_report

router = APIRouter()


@router.get("/seller/sales")
def seller_sales_report(seller: dict = Depends(require_seller)):
    """Weekly sales, AOV, return rate and best sellers for this seller."""
    return get_seller_report(str(seller.get("_id")))

@router.get("/sales", response_model=list)
def sales_report(start_date: datetime, end_date: datetime):
    try:
        return generate_sales_report(start_date, end_date)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/inventory", response_model=list)
def inventory_report():
    try:
        return generate_inventory_report()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/customer_activity", response_model=list)
def customer_activity_report():
    try:
        return generate_customer_activity_report()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/order_status", response_model=list)
def order_status_report(start_date: datetime, end_date: datetime):
    try:
        return generate_order_status_report(start_date, end_date)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

from fastapi import APIRouter, HTTPException
from app.models.order_tracking import OrderStatusUpdate, OrderTrackingResponse
from app.services.order_tracking_service import update_order_status, get_order_tracking

router = APIRouter()

@router.put("/{order_id}/status", response_model=dict)
def update_status(order_id: str, status_update: OrderStatusUpdate):
    updated = update_order_status(order_id, status_update.status)
    if not updated:
        raise HTTPException(status_code=404, detail="Order not found")
    return {"message": "Order status updated successfully"}

@router.get("/{order_id}/tracking", response_model=OrderTrackingResponse)
def get_tracking_info(order_id: str):
    tracking_info = get_order_tracking(order_id)
    if not tracking_info:
        raise HTTPException(status_code=404, detail="Order not found")
    return tracking_info

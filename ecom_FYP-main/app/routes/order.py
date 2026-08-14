from fastapi import APIRouter, HTTPException
from app.models.order import OrderCreate, OrderResponse, TrackingHistory,OrderRequest
from app.services.order_service import (
    create_order, get_order, get_all_orders, update_order_status
)

router = APIRouter()

@router.post("/", response_model=dict)
def create_new_order(order: OrderCreate):
    order_id = create_order(order)
    return {"order_id": order_id}

@router.get("/fetch-order", response_model=OrderResponse)
def fetch_order(request : OrderRequest):
    order = get_order(request.order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

@router.get("/", response_model=list)
def fetch_all_orders():
    return get_all_orders()

@router.put("/{order_id}/status", response_model=dict)
def update_status(order_id: str, status: str):
    updated = update_order_status(order_id, status)
    if not updated:
        raise HTTPException(status_code=404, detail="Order not found")
    return {"message": "Order status updated successfully"}

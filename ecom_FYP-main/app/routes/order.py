from fastapi import APIRouter, Depends, HTTPException
from app.core.deps import require_seller
from app.models.order import OrderCreate, OrderResponse, TrackingHistory,OrderRequest
from app.services.order_service import (
    create_order, get_order, get_all_orders, update_order_status
)
from app.services.seller_service import get_seller_orders, seller_owns_order

router = APIRouter()


@router.get("/seller", response_model=list)
def fetch_seller_orders(seller: dict = Depends(require_seller)):
    """Orders containing at least one of the signed-in seller's products."""
    return get_seller_orders(str(seller.get("_id")))


@router.put("/seller/{order_id}/status", response_model=dict)
def update_seller_order_status(
    order_id: str,
    status: str,
    seller: dict = Depends(require_seller),
):
    """Advance an order's status, but only for a seller with a line in it."""
    if not seller_owns_order(str(seller.get("_id")), order_id):
        raise HTTPException(
            status_code=404, detail="Order not found for this seller"
        )
    if not update_order_status(order_id, status):
        raise HTTPException(status_code=404, detail="Order not found")
    return {"message": "Order status updated successfully"}

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

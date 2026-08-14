from fastapi import APIRouter, HTTPException
from app.models.inventory import InventoryCreate, InventoryUpdate, InventoryResponse,InventoryRequest
from app.services.inventory_service import (
    create_inventory_entry,
    update_inventory,
    get_inventory,
    check_low_stock
)

router = APIRouter()

@router.post("/", response_model=dict)
def create_inventory(data: InventoryCreate):
    inventory_id = create_inventory_entry(data)
    return {"inventory_id": inventory_id}

@router.put("/{product_id}", response_model=dict)
def update_inventory_stock(product_id: str, data: InventoryUpdate):
    updated = update_inventory(product_id, data.quantity_in_stock)
    if not updated:
        raise HTTPException(status_code=404, detail="Product not found")
    return {"message": "Inventory updated successfully"}

@router.get("/product-inventory", response_model=InventoryResponse)
def get_inventory_details(request: InventoryRequest):
    inventory = get_inventory(request.product_id)
    if not inventory:
        raise HTTPException(status_code=404, detail="Product not found")
    return inventory

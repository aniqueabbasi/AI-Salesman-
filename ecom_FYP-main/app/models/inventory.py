from pydantic import BaseModel, Field


class InventoryRequest(BaseModel):
    product_id: str

class InventoryCreate(BaseModel):
    product_id: str
    quantity_in_stock: int = Field(..., ge=0)
    low_stock_threshold: int = Field(..., ge=0)

class InventoryUpdate(BaseModel):
    quantity_in_stock: int = Field(..., ge=0)

class InventoryResponse(BaseModel):
    #id: str
    product_id: str
    quantity_in_stock: int
    low_stock_threshold: int

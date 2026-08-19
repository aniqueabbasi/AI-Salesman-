import shutil
import uuid
from enum import Enum
from pathlib import Path

from typing_extensions import Optional
from fastapi import APIRouter, File, HTTPException, Request, UploadFile
from fastapi.param_functions import Depends, Query
from app.core.deps import require_seller
from app.models.product import PaginatedProductResponse, ProductCreate, ProductResponse,ProductRequest
from app.services.product_service import (
    create_product, get_all_products, get_product_by_id, get_product_count,
    get_products_by_seller, update_product, delete_product
)

class SortOrder(str, Enum):
    asc = "asc"
    desc = "desc"

router = APIRouter()

# Where uploaded product photos are written. Served back out at /media/<file>.
UPLOAD_DIR = Path(__file__).resolve().parents[1] / "static" / "uploads"
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_IMAGE_BYTES = 5 * 1024 * 1024  # 5 MB


@router.post("/", response_model=str)
def add_product(product: ProductCreate, seller: dict = Depends(require_seller)):
    """Create a listing owned by the signed-in seller."""
    product_id = create_product(product, seller=seller)
    return product_id


@router.get("/mine", response_model=list[ProductResponse])
def my_products(seller: dict = Depends(require_seller)):
    """Every product the signed-in seller has listed."""
    return get_products_by_seller(str(seller.get("_id")))


@router.post("/upload-image")
async def upload_image(
    request: Request,
    file: UploadFile = File(...),
    seller: dict = Depends(require_seller),
):
    """Accept a product photo and return a URL the app can render."""
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported image type {file.content_type}. Use JPEG, PNG, WEBP or GIF.",
        )

    suffix = Path(file.filename or "").suffix.lower() or ".jpg"
    filename = f"{uuid.uuid4().hex}{suffix}"
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    destination = UPLOAD_DIR / filename

    with destination.open("wb") as target:
        shutil.copyfileobj(file.file, target, length=1024 * 1024)

    if destination.stat().st_size > MAX_IMAGE_BYTES:
        destination.unlink(missing_ok=True)
        raise HTTPException(status_code=400, detail="Image must be 5 MB or smaller")

    # Absolute URL so the phone can load it straight from the API host.
    url = str(request.base_url).rstrip("/") + f"/media/{filename}"
    return {"url": url, "filename": filename}


@router.patch("/{product_id}/stock")
def set_product_stock(
    product_id: str,
    stock: int = Query(..., ge=0),
    seller: dict = Depends(require_seller),
):
    """Adjust stock on a listing this seller owns.

    Writes `products.stock` directly, which is the field the storefront reads,
    rather than the separate inventory collection.
    """
    product = get_product_by_id(product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    if str(product.get("seller_id")) != str(seller.get("_id")):
        raise HTTPException(
            status_code=403, detail="This listing belongs to another seller"
        )

    update_product(product_id, {"stock": stock})
    return {"message": "Stock updated", "product_id": product_id, "stock": stock}


@router.delete("/{product_id}")
def remove_product(product_id: str, seller: dict = Depends(require_seller)):
    """Delete a listing, but only if this seller owns it."""
    product = get_product_by_id(product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    if str(product.get("seller_id")) != str(seller.get("_id")):
        raise HTTPException(
            status_code=403, detail="You can only delete your own products"
        )

    delete_product(product_id)
    return {"message": "Product deleted", "product_id": product_id}

# @router.get("/", response_model=list[ProductResponse])
# def list_products():
#     products = get_all_products()
#     print(f"[list_products] Returning {len(products)} products")
#     return products
@router.get("/", response_model=PaginatedProductResponse)
def list_products(
    skip: int = Query(0, description="Number of products to skip"),
    limit: int = Query(20, description="Maximum number of products to return"),
    category: Optional[str] = Query(None, description="Filter by category"),
    search: Optional[str] = Query(None, description="Search products by name"),
    sort_by: str = Query("created_at", description="Field to sort by"),
    sort_order: SortOrder = Query(SortOrder.desc, description="Sort order (asc or desc)"),
):
    # Convert sort_order to MongoDB format (1 for ascending, -1 for descending)
    sort_order_value = 1 if sort_order == SortOrder.asc else -1
    
    products = get_all_products(
        skip=skip, 
        limit=limit, 
        category=category, 
        search=search,
        sort_by=sort_by,
        sort_order=sort_order_value
    )
    total = get_product_count(category=category, search=search)
    return {
        "items": products,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.get("/fetch-product", response_model=ProductResponse)
def fetch_product(request: ProductRequest):
    product = get_product_by_id(request.product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    # Convert _id to id (string) before returning
    product["id"] = str(product["_id"])  # Convert ObjectId to string
    del product["_id"]
    return product

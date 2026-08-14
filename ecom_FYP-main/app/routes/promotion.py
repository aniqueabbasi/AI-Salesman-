from fastapi import APIRouter, HTTPException
from app.models.promotion import PromotionCreate, PromotionUpdate, PromotionResponse
from app.services.promotion_service import create_promotion, get_promotion, apply_promotion

router = APIRouter()

@router.post("/", response_model=PromotionResponse)
def create_new_promotion(data: PromotionCreate):
    try:
        promotion_id = create_promotion(data)
        return get_promotion(data.promotion_code)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{promotion_code}", response_model=PromotionResponse)
def get_promotion_details(promotion_code: str):
    promotion = get_promotion(promotion_code)
    if not promotion:
        raise HTTPException(status_code=404, detail="Promotion not found")
    return promotion

@router.post("/apply", response_model=float)
def apply_promo_code(promotion_code: str, order_total: float, product_ids: list[str]):
    discount = apply_promotion(promotion_code, order_total, product_ids)
    if discount is None:
        raise HTTPException(status_code=400, detail="Promotion not applicable")
    return discount

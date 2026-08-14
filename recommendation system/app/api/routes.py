from fastapi import APIRouter, Depends, HTTPException, Query, Response
from typing import List, Optional
import httpx
import urllib.parse

from app.models.product import (
    ProductAttribute, 
    RecommendationRequest, 
    RecommendationResponse, 
    RecommendationsResponse,
    RuleFilterParams,
    AssociationRule,
    ProductSummary
)
from app.services.recommendation_service import recommendation_service
from app.services.product_recommendation_service import get_recommendations_with_products

recommendation_router = APIRouter()


@recommendation_router.post("/train", response_model=List[AssociationRule])
async def train_recommendation_model(
    min_support: float = Query(0.01, ge=0, le=1),
    min_confidence: float = Query(0.5, ge=0, le=1),
    min_lift: float = Query(1.0, ge=0)
):
    """
    Train the recommendation model by loading products from MongoDB,
    transforming them into a transactional format, and mining association rules.
    The model will be automatically saved to disk for future use.
    """
    try:
        rules = await recommendation_service.train(
            min_support=min_support,
            min_confidence=min_confidence,
            min_lift=min_lift
        )
        return rules
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error training model: {str(e)}")


@recommendation_router.get("/model/status")
async def get_model_status():
    """
    Get the current status of the recommendation model.
    """
    model_info = recommendation_service.get_model_info()
    if model_info:
        return {
            "status": "trained",
            "model_info": model_info,
            "message": "Model is ready for recommendations"
        }
    else:
        return {
            "status": "not_trained",
            "model_info": None,
            "message": "Model needs to be trained. Use POST /api/train to train the model."
        }


@recommendation_router.post("/recommend", response_model=RecommendationsResponse)
async def get_recommendations(request: RecommendationRequest):
    """
    Get product recommendations based on input attributes.
    """
    if not recommendation_service.is_model_trained():
        raise HTTPException(
            status_code=400, 
            detail="Model not trained. Please train the model first using POST /api/train"
        )
    
    # Get recommendations with products
    recommendations_with_products = await get_recommendations_with_products(
        attributes=request.attributes,
        min_confidence=request.min_confidence,
        min_lift=request.min_lift,
        max_results=request.max_results,
        include_products=request.include_products
    )
    
    # Convert to response format
    response_items = []
    for attr, products, confidence, lift, support in recommendations_with_products:
        response_items.append(
            RecommendationResponse(
                recommended_attributes=[attr],
                matching_products=products,
                confidence=confidence,
                lift=lift,
                support=support
            )
        )
    
    return RecommendationsResponse(recommendations=response_items)


@recommendation_router.get("/rules", response_model=List[AssociationRule])
async def get_rules(
    min_confidence: float = Query(0.5, ge=0, le=1),
    min_lift: float = Query(1.0, ge=0),
    antecedent_contains: Optional[str] = Query(None)
):
    """
    Get the mined association rules with optional filtering.
    """
    if not recommendation_service.is_model_trained():
        raise HTTPException(
            status_code=400, 
            detail="Model not trained. Please train the model first using POST /api/train"
        )
    
    rules = recommendation_service.filter_rules(
        min_confidence=min_confidence,
        min_lift=min_lift,
        antecedent_contains=antecedent_contains
    )
    
    return rules


@recommendation_router.get("/image-proxy")
async def image_proxy(url: str):
    """
    Proxy for images to avoid CORS issues.
    """
    if not url:
        raise HTTPException(status_code=400, detail="URL parameter is required")
    
    try:
        # Decode the URL
        decoded_url = urllib.parse.unquote(url)
        
        # Validate URL (basic check)
        if not decoded_url.startswith(('http://', 'https://')):
            raise HTTPException(status_code=400, detail="Invalid URL")
        
        # Fetch the image
        async with httpx.AsyncClient() as client:
            response = await client.get(decoded_url, follow_redirects=True, timeout=10.0)
            
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail="Failed to fetch image")
            
            # Determine content type
            content_type = response.headers.get("content-type", "image/jpeg")
            
            # Return the image
            return Response(
                content=response.content,
                media_type=content_type
            )
    except httpx.RequestError as exc:
        raise HTTPException(status_code=500, detail=f"Error fetching image: {str(exc)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}") 
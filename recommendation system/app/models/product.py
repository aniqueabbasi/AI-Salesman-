from typing import Dict, List, Optional, Any
from pydantic import BaseModel, Field


class ProductDetail(BaseModel):
    """Model for product details like fabric, pattern, color, etc."""
    key: str
    value: str


class Product(BaseModel):
    """Model for a product in MongoDB"""
    id: Optional[str] = Field(None, alias="_id")
    title: str
    brand: str
    category: str
    sub_category: str
    product_details: List[Dict[str, str]] = []
    images: List[str] = []
    
    class Config:
        populate_by_name = True
        json_encoders = {
            # Custom encoders for types that need special handling
        }


class ProductAttribute(BaseModel):
    """Model for a product attribute used in recommendations"""
    attribute_type: str  # e.g., "brand", "sub_category", "Fabric", "Pattern", "Color"
    attribute_value: str


class ProductSummary(BaseModel):
    """Summary model for a product in recommendations"""
    id: Optional[str] = None
    title: str
    brand: str
    category: str
    sub_category: str
    image_url: Optional[str] = None
    images: List[str] = []


class RecommendationRequest(BaseModel):
    """Request model for product recommendations"""
    attributes: List[ProductAttribute] = Field(..., min_items=1)
    min_confidence: float = Field(0.5, ge=0, le=1)
    min_lift: float = Field(1.0, ge=0)
    max_results: int = Field(10, ge=1)
    include_products: bool = Field(True, description="Whether to include matching products in the response")


class RecommendationResponse(BaseModel):
    """Response model for product recommendations"""
    recommended_attributes: List[ProductAttribute] = []
    matching_products: List[ProductSummary] = []
    confidence: float
    lift: float
    support: float


class RecommendationsResponse(BaseModel):
    """Response model for multiple recommendations"""
    recommendations: List[RecommendationResponse] = []


class RuleFilterParams(BaseModel):
    """Parameters for filtering association rules"""
    min_confidence: float = Field(0.5, ge=0, le=1)
    min_lift: float = Field(1.0, ge=0)
    antecedent_contains: Optional[str] = None


class AssociationRule(BaseModel):
    """Model for an association rule"""
    antecedent: List[str]
    consequent: List[str]
    support: float
    confidence: float
    lift: float 
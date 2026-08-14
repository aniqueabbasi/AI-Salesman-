import logging
from typing import Dict, List, Tuple, Optional
import hashlib
import urllib.parse
from app.models.product import ProductAttribute, ProductSummary
from app.services.recommendation_service import recommendation_service
from app.utils.database import get_collection

logger = logging.getLogger(__name__)

def generate_image_url(product: Dict) -> str:
    """Generate a placeholder image URL based on product attributes"""
    # First check if product has images array
    if product.get("images") and isinstance(product.get("images"), list) and len(product.get("images")) > 0:
        return product["images"][0]  # Return the first image URL
        
    # Try to use product details to create a more specific image
    title = product.get("title", "")
    brand = product.get("brand", "")
    category = product.get("category", "")
    sub_category = product.get("sub_category", "")
    
    # Create a search term for the image
    search_term = f"{brand} {title} {category} {sub_category}".strip()
    encoded_term = urllib.parse.quote_plus(search_term)
    
    # Generate a unique hash for the product to ensure consistent images
    product_id = str(product.get("_id", ""))
    hash_value = hashlib.md5(product_id.encode()).hexdigest()[:8]
    
    # Use placeholder image services
    image_options = [
        f"https://source.unsplash.com/300x400/?{encoded_term}",
        f"https://picsum.photos/seed/{hash_value}/300/400",
        f"https://placehold.co/300x400/eee/999?text={urllib.parse.quote_plus(title[:20])}"
    ]
    
    # Choose image based on hash to ensure consistency
    hash_num = int(hash_value, 16)
    return image_options[hash_num % len(image_options)]

async def get_recommendations_with_products(
    attributes: List[ProductAttribute],
    min_confidence: float = 0.5,
    min_lift: float = 1.0,
    max_results: int = 10,
    include_products: bool = True
) -> List[Tuple[ProductAttribute, List[ProductSummary], float, float, float]]:
    """Get recommendations with matching products"""
    # Get basic recommendations first
    basic_recommendations = recommendation_service.get_recommendations(
        attributes=attributes,
        min_confidence=min_confidence,
        min_lift=min_lift,
        max_results=max_results
    )
    
    if not include_products:
        # Return basic recommendations without products
        return [(attr, [], conf, lift, supp) for attr, conf, lift, supp in basic_recommendations]
    
    # Add matching products to each recommendation
    recommendations_with_products = []
    
    for attr, conf, lift, supp in basic_recommendations:
        # Find matching products for this attribute
        matching_products = await find_products_by_attribute(attr, limit=5)
        
        # Add to results
        recommendations_with_products.append((attr, matching_products, conf, lift, supp))
    
    return recommendations_with_products

async def find_products_by_attribute(attribute: ProductAttribute, limit: int = 5) -> List[ProductSummary]:
    """Find products in the database that match a specific attribute"""
    products_collection = get_collection("products")
    query = {}
    
    # Build query based on attribute type
    if attribute.attribute_type == "brand":
        query["brand"] = attribute.attribute_value
    elif attribute.attribute_type == "category":
        query["category"] = attribute.attribute_value
    elif attribute.attribute_type == "sub_category" or attribute.attribute_type == "sub":
        # Handle the case where attribute_type is "sub" but the value contains "category_"
        if attribute.attribute_value.startswith("category_"):
            query["sub_category"] = attribute.attribute_value[9:]  # Remove "category_" prefix
        else:
            query["sub_category"] = attribute.attribute_value
    else:
        # For other attributes like Color, Pattern, etc., search in product_details
        query["product_details"] = {
            "$elemMatch": {
                "key": attribute.attribute_type,
                "value": attribute.attribute_value
            }
        }
    
    # Find matching products
    products = await products_collection.find(query).limit(limit).to_list(length=limit)
    
    # Convert to ProductSummary objects with generated image URLs
    return [
        ProductSummary(
            id=str(product.get("_id", "")),
            title=product.get("title", ""),
            brand=product.get("brand", ""),
            category=product.get("category", ""),
            sub_category=product.get("sub_category", ""),
            image_url=product.get("image_url") or generate_image_url(product),
            images=product.get("images", [])
        )
        for product in products
    ] 
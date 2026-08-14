# Product Models Documentation

This document explains the data models used in the recommendation system, focusing on how products and their attributes are structured for use with association rule mining.

## Overview

The `product.py` file defines several Pydantic models that are used throughout the application to:

1. Represent products and their attributes
2. Structure requests and responses for the recommendation API
3. Format association rules for easy consumption

## Models Explained

### `ProductDetail`

```python
class ProductDetail(BaseModel):
    key: str
    value: str
```

- **Purpose**: Represents a key-value pair for product details like fabric, pattern, color, etc.
- **Fields**:
  - `key`: The name of the attribute (e.g., "Fabric", "Pattern", "Color")
  - `value`: The specific value for that attribute (e.g., "Cotton", "Striped", "Blue")
- **Usage**: Used within the `Product` model to store detailed product attributes

### `Product`

```python
class Product(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    title: str
    brand: str
    category: str
    sub_category: str
    product_details: List[Dict[str, str]] = []
    images: List[str] = []
```

- **Purpose**: Represents a complete product in the database
- **Fields**:
  - `id`: MongoDB document ID (optional, aliased as "_id")
  - `title`: Product name/title
  - `brand`: Brand name
  - `category`: Main product category
  - `sub_category`: More specific product category
  - `product_details`: List of additional product attributes as key-value pairs
  - `images`: List of image URLs for the product
- **Usage**: Used when loading products from the database and for data processing

### `ProductAttribute`

```python
class ProductAttribute(BaseModel):
    attribute_type: str
    attribute_value: str
```

- **Purpose**: Represents a single attribute of a product used in recommendations
- **Fields**:
  - `attribute_type`: The type of attribute (e.g., "brand", "category", "Fabric")
  - `attribute_value`: The specific value of that attribute
- **Usage**: Used to represent both input attributes (what a user is looking for) and recommended attributes (what the system suggests)

### `ProductSummary`

```python
class ProductSummary(BaseModel):
    id: Optional[str] = None
    title: str
    brand: str
    category: str
    sub_category: str
    image_url: Optional[str] = None
    images: List[str] = []
```

- **Purpose**: A simplified version of the Product model used in recommendation responses
- **Fields**: Similar to `Product` but with only essential fields needed for display
- **Usage**: Used when returning matching products in recommendation responses to avoid sending unnecessary data

### `RecommendationRequest`

```python
class RecommendationRequest(BaseModel):
    attributes: List[ProductAttribute] = Field(..., min_items=1)
    min_confidence: float = Field(0.5, ge=0, le=1)
    min_lift: float = Field(1.0, ge=0)
    max_results: int = Field(10, ge=1)
    include_products: bool = Field(True)
```

- **Purpose**: Defines the structure of a recommendation API request
- **Fields**:
  - `attributes`: List of attributes to base recommendations on (at least one required)
  - `min_confidence`: Minimum confidence threshold for rules (0-1)
  - `min_lift`: Minimum lift threshold for rules (≥0)
  - `max_results`: Maximum number of recommendations to return
  - `include_products`: Whether to include matching product details
- **Usage**: Used to validate and parse incoming API requests for recommendations

### `RecommendationResponse` and `RecommendationsResponse`

```python
class RecommendationResponse(BaseModel):
    recommended_attributes: List[ProductAttribute] = []
    matching_products: List[ProductSummary] = []
    confidence: float
    lift: float
    support: float

class RecommendationsResponse(BaseModel):
    recommendations: List[RecommendationResponse] = []
```

- **Purpose**: Define the structure of recommendation API responses
- **Fields**:
  - `recommended_attributes`: Attributes recommended by the system
  - `matching_products`: Actual products matching the recommended attributes
  - `confidence`, `lift`, `support`: Association rule metrics (explained below)
- **Usage**: Used to format and validate API responses

### `RuleFilterParams` and `AssociationRule`

```python
class RuleFilterParams(BaseModel):
    min_confidence: float = Field(0.5, ge=0, le=1)
    min_lift: float = Field(1.0, ge=0)
    antecedent_contains: Optional[str] = None

class AssociationRule(BaseModel):
    antecedent: List[str]
    consequent: List[str]
    support: float
    confidence: float
    lift: float
```

- **Purpose**: Define parameters for filtering rules and the structure of association rules
- **Fields**:
  - `min_confidence`, `min_lift`: Thresholds for filtering rules
  - `antecedent_contains`: Optional text to filter rules by antecedent content
  - `antecedent`, `consequent`: The "if" and "then" parts of the rule
  - `support`, `confidence`, `lift`: Association rule metrics
- **Usage**: Used for filtering and representing association rules

## Association Rule Mining Concepts

Association rule mining is a technique used to discover relationships between variables in large datasets. In our recommendation system, we use it to find patterns in product attributes that can suggest related products.

### Key Metrics Explained

| Term | Description |
|------|-------------|
| **Antecedent** | The "if" part of the rule — the attributes the user is interested in. For example, if a user is looking at "brand: Nike", that's the antecedent. |
| **Consequent** | The "then" part of the rule — the attributes likely to be of interest. For example, if people who like "brand: Nike" also like "category: Sports Shoes", then "category: Sports Shoes" is the consequent. |
| **Support** | How often the antecedent and consequent appear together in the dataset. A support of 0.05 means that 5% of all transactions contain both the antecedent and consequent items. Higher support means the rule is more common. |
| **Confidence** | The likelihood that the consequent is chosen when the antecedent is chosen. A confidence of 0.8 means that 80% of transactions containing the antecedent also contain the consequent. Higher confidence means the rule is more reliable. |
| **Lift** | How much more likely the consequent is chosen with the antecedent vs. alone. A lift of 1 means no relationship, less than 1 means negative relationship, greater than 1 means positive relationship. For example, a lift of 2 means the consequent is twice as likely to be chosen when the antecedent is present. |

### How These Metrics Affect Recommendations

- **High Support**: Rules with high support are common patterns but might be obvious (e.g., people who buy phones also buy phone cases).
- **High Confidence**: Rules with high confidence are more reliable but might not reveal interesting relationships.
- **High Lift**: Rules with high lift show strong relationships that might not be obvious, making them valuable for recommendations.

The recommendation system balances these metrics to provide suggestions that are both reliable (high confidence) and interesting (high lift), while filtering out rules that are too rare (low support).

## How to Use These Models

These models provide a structured way to:

1. **Define product data**: Use `Product` and `ProductDetail` to structure product information
2. **Request recommendations**: Use `RecommendationRequest` to specify what you're looking for
3. **Process recommendations**: Use `RecommendationResponse` to understand what's being recommended and why

By understanding these models, you can better interact with the recommendation API and interpret its results. 
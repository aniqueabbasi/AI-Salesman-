# API Routes Documentation

This document explains the API endpoints available in the recommendation system, focusing on how to use them and understand their responses.

## Overview

The `routes.py` file defines several FastAPI endpoints that allow you to:

1. Train the recommendation model
2. Get product recommendations based on attributes
3. Retrieve and filter association rules
4. Proxy image requests to avoid CORS issues

## API Endpoints Explained

### 1. Train Recommendation Model

```
POST /train
```

**Purpose**: Trains the recommendation model by loading products from MongoDB, transforming them into a transactional format, and mining association rules.

**Parameters**:
- `min_support` (float, default=0.01): Minimum support threshold for rules (0-1)
- `min_confidence` (float, default=0.5): Minimum confidence threshold for rules (0-1)
- `min_lift` (float, default=1.0): Minimum lift threshold for rules (≥0)

**How it works**:
1. The endpoint calls the `train()` method of the recommendation service
2. The service loads products from MongoDB
3. It transforms product attributes into a transaction-like format
4. It mines association rules using the Apriori algorithm
5. It returns the discovered rules that meet the specified thresholds

**Response**: List of association rules that meet the specified thresholds

**Example Request**:
```http
POST /train?min_support=0.01&min_confidence=0.5&min_lift=1.0
```

**Example Response**:
```json
[
  {
    "antecedent": ["brand_Nike"],
    "consequent": ["category_Sports Shoes"],
    "support": 0.05,
    "confidence": 0.75,
    "lift": 2.5
  },
  {
    "antecedent": ["color_Blue"],
    "consequent": ["pattern_Solid"],
    "support": 0.03,
    "confidence": 0.65,
    "lift": 1.8
  }
]
```

**Error Handling**:
- If an error occurs during training, returns a 500 error with details

### 2. Get Recommendations

```
POST /recommend
```

**Purpose**: Provides product recommendations based on input attributes.

**Request Body**:
```json
{
  "attributes": [
    {
      "attribute_type": "brand",
      "attribute_value": "Nike"
    }
  ],
  "min_confidence": 0.5,
  "min_lift": 1.0,
  "max_results": 10,
  "include_products": true
}
```

**How it works**:
1. Validates that the model has been trained
2. Calls `get_recommendations_with_products()` to find recommendations based on input attributes
3. Formats the response with recommended attributes, matching products, and rule metrics

**Response**: A list of recommendations, each containing:
- Recommended attributes
- Matching products (if `include_products` is true)
- Confidence, lift, and support values for the recommendation

**Example Response**:
```json
{
  "recommendations": [
    {
      "recommended_attributes": [
        {
          "attribute_type": "category",
          "attribute_value": "Sports Shoes"
        }
      ],
      "matching_products": [
        {
          "id": "123",
          "title": "Nike Air Max",
          "brand": "Nike",
          "category": "Sports Shoes",
          "sub_category": "Running Shoes",
          "image_url": "https://example.com/image.jpg"
        }
      ],
      "confidence": 0.75,
      "lift": 2.5,
      "support": 0.05
    }
  ]
}
```

**Error Handling**:
- If the model hasn't been trained, returns a 400 error

### 3. Get Association Rules

```
GET /rules
```

**Purpose**: Retrieves the mined association rules with optional filtering.

**Parameters**:
- `min_confidence` (float, default=0.5): Minimum confidence threshold for rules (0-1)
- `min_lift` (float, default=1.0): Minimum lift threshold for rules (≥0)
- `antecedent_contains` (string, optional): Filter rules to those with antecedents containing this string

**How it works**:
1. Validates that the model has been trained
2. Calls `filter_rules()` to retrieve rules matching the specified criteria
3. Returns the filtered rules

**Response**: List of association rules that meet the specified criteria

**Example Request**:
```http
GET /rules?min_confidence=0.6&min_lift=1.5&antecedent_contains=brand
```

**Example Response**:
```json
[
  {
    "antecedent": ["brand_Nike"],
    "consequent": ["category_Sports Shoes"],
    "support": 0.05,
    "confidence": 0.75,
    "lift": 2.5
  },
  {
    "antecedent": ["brand_Adidas"],
    "consequent": ["category_Sports Apparel"],
    "support": 0.04,
    "confidence": 0.7,
    "lift": 1.9
  }
]
```

**Error Handling**:
- If the model hasn't been trained, returns a 400 error

### 4. Image Proxy

```
GET /image-proxy
```

**Purpose**: Proxies image requests to avoid CORS issues when displaying images from external sources.

**Parameters**:
- `url` (string, required): The URL of the image to proxy

**How it works**:
1. Decodes and validates the provided URL
2. Fetches the image using an HTTP client
3. Returns the image with appropriate content type

**Response**: The image content with appropriate content type headers

**Example Request**:
```http
GET /image-proxy?url=https%3A%2F%2Fexample.com%2Fimage.jpg
```

**Response**: The image binary data

**Error Handling**:
- If URL is missing or invalid, returns a 400 error
- If image fetching fails, returns the status code from the failed request or a 500 error

## Understanding Association Rule Mining in the API

When using these API endpoints, it's important to understand the key metrics that determine the quality of recommendations:

### Key Metrics

| Term | Description | API Impact |
|------|-------------|------------|
| **Support** | How often items appear together in the dataset | Lower values include rarer combinations but may introduce noise |
| **Confidence** | Probability of seeing the consequent when the antecedent is present | Higher values give more reliable recommendations |
| **Lift** | How much more likely the consequent is with the antecedent vs. alone | Higher values indicate stronger relationships |

### How Parameters Affect Results

1. **min_support**:
   - **Low value** (e.g., 0.01): More rules, including rare patterns, but potentially more noise
   - **High value** (e.g., 0.1): Fewer rules, only common patterns, but might miss interesting niche relationships

2. **min_confidence**:
   - **Low value** (e.g., 0.3): More rules, but less reliable
   - **High value** (e.g., 0.8): Fewer rules, but more reliable

3. **min_lift**:
   - **Value = 1**: No filtering based on relationship strength
   - **Value > 1**: Only rules where items appear together more often than by chance
   - **Higher values** (e.g., 3+): Only very strong relationships

### Practical Tips

1. **Start with default values** (support=0.01, confidence=0.5, lift=1.0) and adjust based on results
2. **Lower support** if you want more diverse recommendations
3. **Increase confidence** if you want more reliable recommendations
4. **Increase lift** if you want to focus on stronger relationships
5. **Use antecedent_contains** to focus on specific types of rules (e.g., brand-based or category-based)

## Error Handling

All endpoints include proper error handling:

1. **400 Bad Request**: When parameters are invalid or the model hasn't been trained
2. **500 Internal Server Error**: When an unexpected error occurs during processing

Always check for these error responses in your client application and handle them appropriately. 
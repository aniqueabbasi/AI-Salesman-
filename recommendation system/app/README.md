# Product Recommendation System Documentation

This document provides an overview of the product recommendation system, explaining how it works, its architecture, and how the different components interact.

## System Overview

The product recommendation system uses association rule mining to discover relationships between product attributes and generate personalized recommendations. The system is built with FastAPI and uses MongoDB for data storage.

### What is Association Rule Mining?

Association rule mining is a technique used to discover relationships between variables in large datasets. In the context of product recommendations, it helps identify patterns like "customers who like products with attribute X also tend to like products with attribute Y."

For example, the system might discover that "customers who like brand Nike also tend to like category Sports Shoes" or "customers who like color Blue also tend to like pattern Solid."

## Architecture

The system follows a modular architecture with the following components:

1. **API Layer** (`app/api/`): Handles HTTP requests and responses
2. **Models** (`app/models/`): Defines data structures used throughout the application
3. **Services** (`app/services/`): Implements the core business logic
4. **Utilities** (`app/utils/`): Provides support functions for database access, data loading, and logging

### Main Application (`main.py`)

The `main.py` file is the entry point of the application. It:

1. Creates a FastAPI application
2. Configures CORS to allow cross-origin requests
3. Registers API routes
4. Sets up database connection on startup
5. Provides a health check endpoint

## How the System Works

### 1. Data Processing

The system processes product data in several steps:

1. **Data Loading**: Products are loaded from a JSON file into MongoDB
2. **Feature Extraction**: Product attributes (brand, category, etc.) are extracted
3. **Transaction Creation**: Attributes are formatted as "transactions" for the Apriori algorithm
4. **One-hot Encoding**: Transactions are converted to a one-hot encoded matrix

### 2. Association Rule Mining

The system uses the Apriori algorithm to mine association rules:

1. **Find Frequent Itemsets**: Identify sets of attributes that frequently appear together
2. **Generate Rules**: Create rules in the form "if antecedent then consequent"
3. **Calculate Metrics**: Compute support, confidence, and lift for each rule
4. **Filter Rules**: Apply thresholds to keep only meaningful rules

### 3. Recommendation Generation

When a user requests recommendations:

1. **Match Input**: Find rules where antecedents match the user's input attributes
2. **Extract Recommendations**: Use consequents as recommended attributes
3. **Find Matching Products**: Query the database for products matching the recommended attributes
4. **Return Results**: Format and return recommendations with matching products

## Key Metrics Explained

Association rule mining uses several metrics to evaluate the quality of rules:

### Support

**Definition**: How often items appear together in the dataset.

**Example**: If "brand_Nike" and "category_Sports Shoes" appear together in 5% of all products, the support is 0.05.

**Importance**: Higher support means the rule is based on more data and is more common.

### Confidence

**Definition**: The probability of seeing the consequent when the antecedent is present.

**Example**: If 80% of products with "brand_Nike" also have "category_Sports Shoes", the confidence is 0.8.

**Importance**: Higher confidence means the rule is more reliable.

### Lift

**Definition**: How much more likely the consequent is with the antecedent vs. alone.

**Example**: If products are twice as likely to be in "category_Sports Shoes" when they have "brand_Nike" compared to the overall likelihood of being in "category_Sports Shoes", the lift is 2.

**Importance**: Lift > 1 indicates a positive correlation, which is good for recommendations.

## API Usage

The system provides three main API endpoints:

### 1. Train Model

```
POST /api/train
```

Trains the recommendation model with the specified parameters.

**Parameters**:
- `min_support`: Minimum support threshold (0-1)
- `min_confidence`: Minimum confidence threshold (0-1)
- `min_lift`: Minimum lift threshold (≥0)

### 2. Get Recommendations

```
POST /api/recommend
```

Gets product recommendations based on input attributes.

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

### 3. Get Rules

```
GET /api/rules
```

Gets the mined association rules with optional filtering.

**Parameters**:
- `min_confidence`: Minimum confidence threshold (0-1)
- `min_lift`: Minimum lift threshold (≥0)
- `antecedent_contains`: Filter rules to those with antecedents containing this string

## Tuning the System

The recommendation system can be tuned by adjusting the following parameters:

### Support Threshold

- **Lower values** (e.g., 0.01): More rules, including rare patterns
- **Higher values** (e.g., 0.1): Fewer rules, only common patterns

### Confidence Threshold

- **Lower values** (e.g., 0.3): More rules, but less reliable
- **Higher values** (e.g., 0.8): Fewer rules, but more reliable

### Lift Threshold

- **Value = 1**: No filtering based on relationship strength
- **Higher values** (e.g., 2+): Only strong relationships

## Folder Structure

For detailed documentation on each component, please refer to the README files in the respective folders:

- [API Documentation](./api/README.md): Details on API endpoints
- [Models Documentation](./models/README.md): Information about data structures
- [Services Documentation](./services/README.md): Explanation of business logic
- [Utilities Documentation](./utils/README.md): Details on support functions

## Getting Started

To use the recommendation system:

1. **Start the API**: Run the application using `uvicorn app.main:app --reload`
2. **Train the model**: Call the `/api/train` endpoint with appropriate parameters
3. **Get recommendations**: Call the `/api/recommend` endpoint with input attributes
4. **Explore rules**: Use the `/api/rules` endpoint to understand the underlying patterns

## Conclusion

The product recommendation system provides a flexible way to discover relationships between product attributes and generate personalized recommendations. By understanding the underlying association rule mining concepts and tuning the parameters, you can optimize the system for your specific needs. 
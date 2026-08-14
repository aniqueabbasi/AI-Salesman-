# Recommendation Services Documentation

This document explains the recommendation services used in the system, focusing on how association rule mining is applied to generate product recommendations.

## Overview

The services folder contains two key files:

1. `recommendation_service.py`: Core service that handles association rule mining
2. `product_recommendation_service.py`: Service that enhances recommendations with actual product data

These services work together to:
1. Process product data into a format suitable for association rule mining
2. Generate association rules using the Apriori algorithm
3. Find relevant recommendations based on input attributes
4. Match recommendations with actual products from the database

## 1. Recommendation Service

The `RecommendationService` class in `recommendation_service.py` is the core of the recommendation system. It handles the entire process of mining association rules from product data.

### Key Functions

#### `load_products_from_db()`
- **Purpose**: Loads products from MongoDB and caches them by attributes for faster lookups
- **Input**: None
- **Output**: List of product dictionaries
- **Process**:
  1. Connects to the MongoDB products collection
  2. Retrieves all products
  3. Caches products by brand, category, sub-category, and product details for faster access

#### `extract_product_features(products)`
- **Purpose**: Transforms products into "transactions" for association rule mining
- **Input**: List of product dictionaries
- **Output**: List of transactions (each transaction is a list of feature strings)
- **Process**:
  1. For each product, extracts brand, category, sub-category, and product details
  2. Formats each attribute as `"attribute_type_attribute_value"` (e.g., `"brand_Nike"`)
  3. Creates a transaction (list of attributes) for each product

#### `create_one_hot_encoded_df(transactions)`
- **Purpose**: Converts transactions to a one-hot encoded DataFrame for the Apriori algorithm
- **Input**: List of transactions
- **Output**: Pandas DataFrame with one-hot encoded features
- **Process**:
  1. Identifies all unique features across all transactions
  2. Creates a matrix where each row is a transaction and each column is a feature
  3. Sets cell values to 1 if the feature is present in the transaction, 0 otherwise

#### `mine_association_rules(one_hot_df, min_support, min_confidence, min_lift)`
- **Purpose**: Applies the Apriori algorithm to find association rules
- **Input**: 
  - One-hot encoded DataFrame
  - Minimum support threshold (default: 0.01)
  - Minimum confidence threshold (default: 0.5)
  - Minimum lift threshold (default: 1.0)
- **Output**: DataFrame containing association rules
- **Process**:
  1. Uses the `apriori` function to find frequent itemsets (groups of items that appear together)
  2. Uses the `association_rules` function to generate rules from these itemsets
  3. Filters rules based on minimum lift
  4. Returns the resulting rules

#### `train(min_support, min_confidence, min_lift)`
- **Purpose**: Orchestrates the entire training process
- **Input**: Minimum support, confidence, and lift thresholds
- **Output**: List of formatted association rules
- **Process**:
  1. Loads products from the database
  2. Extracts features to create transactions
  3. Creates one-hot encoded DataFrame
  4. Mines association rules
  5. Formats rules for storage and returns them

#### `get_recommendations(attributes, min_confidence, min_lift, max_results)`
- **Purpose**: Finds recommendations based on input attributes
- **Input**: 
  - List of product attributes
  - Minimum confidence threshold
  - Minimum lift threshold
  - Maximum number of results
- **Output**: List of tuples containing recommended attributes and their metrics
- **Process**:
  1. Converts input attributes to feature format
  2. Finds rules where antecedents contain input features
  3. Extracts consequents as recommendations
  4. Sorts by confidence and lift
  5. Returns top results

## 2. Product Recommendation Service

The `product_recommendation_service.py` file enhances recommendations with actual product data, making them more useful for display to users.

### Key Functions

#### `generate_image_url(product)`
- **Purpose**: Generates a placeholder image URL based on product attributes
- **Input**: Product dictionary
- **Output**: Image URL string
- **Process**:
  1. First checks if the product has an images array and returns the first image if available
  2. Otherwise, creates a search term based on product attributes
  3. Generates a unique hash for the product
  4. Returns a URL from one of several placeholder image services

#### `get_recommendations_with_products(attributes, min_confidence, min_lift, max_results, include_products)`
- **Purpose**: Enhances basic recommendations with matching product data
- **Input**: 
  - List of product attributes
  - Minimum confidence threshold
  - Minimum lift threshold
  - Maximum number of results
  - Whether to include product details
- **Output**: List of tuples containing recommended attributes, matching products, and metrics
- **Process**:
  1. Gets basic recommendations from the recommendation service
  2. For each recommendation, finds matching products
  3. Combines recommendations with products and returns the enhanced results

#### `find_products_by_attribute(attribute, limit)`
- **Purpose**: Finds products in the database that match a specific attribute
- **Input**: 
  - Product attribute
  - Maximum number of products to return
- **Output**: List of ProductSummary objects
- **Process**:
  1. Builds a MongoDB query based on the attribute type
  2. Retrieves matching products from the database
  3. Converts products to ProductSummary objects with image URLs
  4. Returns the list of product summaries

## Association Rule Mining Concepts

Association rule mining is a technique used to discover relationships between variables in large datasets. In our recommendation system, it helps us find patterns like "people who like brand X also like category Y."

### Key Terms and Metrics

| Term | Description | Example | Why It Matters |
|------|-------------|---------|---------------|
| **Antecedent** | The "if" part of the rule | "If customer buys brand_Nike" | Represents what we know about the customer's preferences |
| **Consequent** | The "then" part of the rule | "Then they might also like category_Sports Shoes" | Represents what we're recommending |
| **Support** | How often items appear together in the dataset | Support of 0.05 means 5% of all products have both attributes | Higher values mean more common combinations |
| **Confidence** | Probability of seeing the consequent when the antecedent is present | Confidence of 0.8 means 80% of products with the antecedent also have the consequent | Higher values mean more reliable recommendations |
| **Lift** | How much more likely the consequent is with the antecedent vs. alone | Lift of 2 means the consequent is twice as likely when the antecedent is present | Values > 1 indicate positive correlation |
| **Antecedent Support** | How frequently the antecedent appears in the dataset | If 10% of products are Nike, antecedent support is 0.1 | Helps understand how common the input attributes are |
| **Consequent Support** | How frequently the consequent appears in the dataset | If 20% of products are Sports Shoes, consequent support is 0.2 | Helps understand how common the recommended attributes are |
| **Leverage** | Difference between observed and expected co-occurrence | Positive values indicate items appear together more than expected | Alternative measure of association strength |
| **Conviction** | Measure of implication strength | Higher values indicate stronger implication | Useful when confidence is high but lift is low |
| **Zhang's Metric** | Statistical score for measuring association strength | Ranges from -1 to 1, with higher values indicating stronger association | Useful for unbalanced datasets |

### How These Metrics Affect Recommendations

#### Support
- **High support (e.g., 0.1)**: Recommendations will be common and popular but might be obvious
- **Low support (e.g., 0.01)**: Recommendations will include niche combinations but might be less reliable
- **Impact on results**: Lower support values give more diverse recommendations but might include noise

#### Confidence
- **High confidence (e.g., 0.8)**: Recommendations will be very reliable but might be limited
- **Low confidence (e.g., 0.3)**: More recommendations but less reliable
- **Impact on results**: Higher confidence values give more trustworthy recommendations but fewer options

#### Lift
- **Lift = 1**: No correlation between antecedent and consequent
- **Lift > 1**: Positive correlation (good for recommendations)
- **Lift < 1**: Negative correlation (items appear together less often than expected)
- **Impact on results**: Higher lift values indicate stronger relationships and more interesting recommendations

### Balancing the Metrics

The recommendation system allows you to adjust these metrics to balance between:
- **Quantity vs. Quality**: Lower thresholds give more recommendations but lower quality
- **Common vs. Niche**: Higher support focuses on common patterns, lower support includes niche patterns
- **Reliability vs. Discovery**: Higher confidence gives more reliable recommendations, lower confidence might discover unexpected relationships

## How to Use These Services

These services are designed to work together to provide product recommendations:

1. **Train the model first**: Call the `/train` API endpoint with appropriate thresholds
2. **Get recommendations**: Call the `/recommend` endpoint with input attributes
3. **Explore rules**: Use the `/rules` endpoint to understand the underlying patterns

By understanding these services and the concepts behind them, you can better tune the recommendation system to meet your specific needs. 
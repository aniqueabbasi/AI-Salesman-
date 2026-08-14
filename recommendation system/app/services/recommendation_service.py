import logging
import pandas as pd
from typing import Dict, List, Set, Tuple, Any, Optional
from mlxtend.frequent_patterns import apriori, association_rules
from app.models.product import ProductAttribute, AssociationRule, ProductSummary
from app.utils.database import get_collection
from app.utils.model_persistence import ModelPersistence

logger = logging.getLogger(__name__)

class RecommendationService:
    """Service for product recommendations using association rule mining"""
    
    def __init__(self):
        self.rules_df = None
        self.transaction_data = None
        self.one_hot_encoded_df = None
        self.feature_names = []
        self.products_cache = {}  # Cache for product data
        self.model_persistence = ModelPersistence()
        
        # Try to load existing model on initialization
        self._load_existing_model()
        
    def _load_existing_model(self):
        """Load existing trained model if available"""
        try:
            result = self.model_persistence.load_model()
            if result:
                self.rules_df, self.one_hot_encoded_df, self.feature_names, self.products_cache, training_params = result
                logger.info(f"Loaded existing model with {len(self.rules_df) if self.rules_df is not None else 0} rules")
                logger.info(f"Training parameters: {training_params}")
            else:
                logger.info("No existing model found. Model will need to be trained.")
        except Exception as e:
            logger.error(f"Error loading existing model: {str(e)}")
            logger.info("Model will need to be trained.")
    
    def is_model_trained(self) -> bool:
        """Check if the model is trained and ready for use"""
        return (
            self.rules_df is not None and 
            not (hasattr(self.rules_df, 'empty') and self.rules_df.empty) and
            len(self.feature_names) > 0
        )
    
    def get_model_info(self) -> Optional[dict]:
        """Get information about the current model"""
        if not self.is_model_trained():
            return None
        
        return {
            'rules_count': len(self.rules_df) if self.rules_df is not None else 0,
            'features_count': len(self.feature_names),
            'products_cache_size': len(self.products_cache),
            'model_loaded_from_disk': self.model_persistence.model_exists()
        }
    
    async def load_products_from_db(self) -> List[Dict]:
        """Load products from MongoDB"""
        products_collection = get_collection("products")
        products = await products_collection.find({}).to_list(length=None)
        logger.info(f"Loaded {len(products)} products from database")
        
        # Cache products by attributes for faster lookup
        self.products_cache = {}
        for product in products:
            # Cache by brand
            if "brand" in product and product["brand"]:
                key = f"brand_{product['brand']}"
                if key not in self.products_cache:
                    self.products_cache[key] = []
                self.products_cache[key].append(product)
            
            # Cache by category
            if "category" in product and product["category"]:
                key = f"category_{product['category']}"
                if key not in self.products_cache:
                    self.products_cache[key] = []
                self.products_cache[key].append(product)
            
            # Cache by sub_category
            if "sub_category" in product and product["sub_category"]:
                key = f"sub_category_{product['sub_category']}"
                if key not in self.products_cache:
                    self.products_cache[key] = []
                self.products_cache[key].append(product)
            
            # Cache by product details
            if "product_details" in product and product["product_details"]:
                for detail in product["product_details"]:
                    if isinstance(detail, dict) and "key" in detail and "value" in detail:
                        key = f"{detail['key']}_{detail['value']}"
                        if key not in self.products_cache:
                            self.products_cache[key] = []
                        self.products_cache[key].append(product)
        
        return products
    
    def extract_product_features(self, products: List[Dict]) -> List[List[str]]:
        """Extract features from products to create transactions"""
        transactions = []
        
        for product in products:
            transaction = []
            
            # Add brand
            if "brand" in product and product["brand"]:
                transaction.append(f"brand_{product['brand']}")
            
            # Add category
            if "category" in product and product["category"]:
                transaction.append(f"category_{product['category']}")
            
            # Add sub_category
            if "sub_category" in product and product["sub_category"]:
                transaction.append(f"sub_category_{product['sub_category']}")
            
            # Add product details
            if "product_details" in product and product["product_details"]:
                for detail in product["product_details"]:
                    if isinstance(detail, dict) and "key" in detail and "value" in detail:
                        key = detail["key"]
                        value = detail["value"]
                        if key and value:
                            transaction.append(f"{key}_{value}")
            
            if transaction:
                transactions.append(transaction)
        
        logger.info(f"Created {len(transactions)} transactions from products")
        return transactions
    
    def create_one_hot_encoded_df(self, transactions: List[List[str]]) -> pd.DataFrame:
        """Create one-hot encoded DataFrame from transactions"""
        # Get all unique features
        all_features = set()
        for transaction in transactions:
            all_features.update(transaction)
        
        self.feature_names = sorted(list(all_features))
        
        # Create one-hot encoded DataFrame
        one_hot_encoded = []
        for transaction in transactions:
            transaction_set = set(transaction)
            one_hot_row = [1 if feature in transaction_set else 0 for feature in self.feature_names]
            one_hot_encoded.append(one_hot_row)
        
        one_hot_df = pd.DataFrame(one_hot_encoded, columns=self.feature_names)
        logger.info(f"Created one-hot encoded DataFrame with {len(one_hot_df)} rows and {len(self.feature_names)} features")
        return one_hot_df
    
    def mine_association_rules(
        self, 
        one_hot_df: pd.DataFrame, 
        min_support: float = 0.01, 
        min_confidence: float = 0.5,
        min_lift: float = 1.0
    ) -> pd.DataFrame:
        """Mine association rules using Apriori algorithm"""
        # Find frequent itemsets
        frequent_itemsets = apriori(
            one_hot_df, 
            min_support=min_support, 
            use_colnames=True
        )
        
        if frequent_itemsets.empty:
            logger.warning(f"No frequent itemsets found with min_support={min_support}")
            return pd.DataFrame()
        
        logger.info(f"Found {len(frequent_itemsets)} frequent itemsets")
        
        # Log the structure of the frequent itemsets
        if not frequent_itemsets.empty:
            sample_itemset = frequent_itemsets.iloc[0]
            logger.debug(f"Sample itemset structure: {sample_itemset}")
            logger.debug(f"Sample itemset types: {[(k, type(v)) for k, v in sample_itemset.items()]}")
        
        # Generate association rules
        rules = association_rules(
            frequent_itemsets, 
            metric="confidence", 
            min_threshold=min_confidence
        )
        
        # Log the structure of the rules
        if not rules.empty:
            sample_rule = rules.iloc[0]
            logger.debug(f"Sample rule structure: {sample_rule}")
            logger.debug(f"Sample rule types: {[(k, type(v)) for k, v in sample_rule.items()]}")
            logger.debug(f"Antecedents type: {type(sample_rule['antecedents'])}")
            logger.debug(f"Consequents type: {type(sample_rule['consequents'])}")
        
        # Filter by lift
        rules = rules[rules['lift'] >= min_lift]
        
        if rules.empty:
            logger.warning(f"No rules found with min_confidence={min_confidence} and min_lift={min_lift}")
            return pd.DataFrame()
        
        logger.info(f"Generated {len(rules)} association rules")
        return rules
    
    def format_rules_for_storage(self, rules_df: pd.DataFrame) -> List[AssociationRule]:
        """Format rules DataFrame to a list of AssociationRule objects"""
        formatted_rules = []
        
        for _, row in rules_df.iterrows():
            try:
                # Handle different types of antecedents/consequents
                antecedent_indices = list(row['antecedents'])
                consequent_indices = list(row['consequents'])
                
                antecedent = []
                for idx in antecedent_indices:
                    if isinstance(idx, int) and 0 <= idx < len(self.feature_names):
                        antecedent.append(self.feature_names[idx])
                    else:
                        antecedent.append(str(idx))
                
                consequent = []
                for idx in consequent_indices:
                    if isinstance(idx, int) and 0 <= idx < len(self.feature_names):
                        consequent.append(self.feature_names[idx])
                    else:
                        consequent.append(str(idx))
                
                rule = AssociationRule(
                    antecedent=antecedent,
                    consequent=consequent,
                    support=float(row['support']),
                    confidence=float(row['confidence']),
                    lift=float(row['lift'])
                )
                
                formatted_rules.append(rule)
            except Exception as e:
                logger.error(f"Error formatting rule: {e}")
                # Log more details about the problematic row
                logger.error(f"Problematic row: {row}")
                continue
        
        return formatted_rules
    
    async def train(self, min_support: float = 0.01, min_confidence: float = 0.5, min_lift: float = 1.0) -> List[AssociationRule]:
        """Train recommendation model and generate rules"""
        try:
            # Load products
            products = await self.load_products_from_db()
            
            if not products:
                logger.error("No products found in database")
                return []
            
            # Extract features and create transactions
            transactions = self.extract_product_features(products)
            
            if not transactions:
                logger.error("No transactions created from products")
                return []
            
            # Create one-hot encoded DataFrame
            self.one_hot_encoded_df = self.create_one_hot_encoded_df(transactions)
            
            # Mine association rules
            self.rules_df = self.mine_association_rules(
                self.one_hot_encoded_df,
                min_support=min_support,
                min_confidence=min_confidence,
                min_lift=min_lift
            )
            
            # Format rules for storage
            formatted_rules = self.format_rules_for_storage(self.rules_df)
            
            # Save model
            self.model_persistence.save_model(
                self.rules_df,
                self.one_hot_encoded_df,
                self.feature_names,
                self.products_cache,
                {
                    'min_support': min_support,
                    'min_confidence': min_confidence,
                    'min_lift': min_lift
                }
            )
            
            return formatted_rules
        except Exception as e:
            logger.error(f"Error training recommendation model: {str(e)}")
            # Reset state on error
            self.rules_df = None
            self.one_hot_encoded_df = None
            self.feature_names = []
            raise
    
    def filter_rules(
        self, 
        min_confidence: float = 0.5, 
        min_lift: float = 1.0,
        antecedent_contains: Optional[str] = None
    ) -> List[AssociationRule]:
        """Filter rules based on confidence, lift, and antecedent"""
        if self.rules_df is None or self.rules_df.empty:
            return []
        
        filtered_df = self.rules_df[
            (self.rules_df['confidence'] >= min_confidence) & 
            (self.rules_df['lift'] >= min_lift)
        ]
        
        if antecedent_contains:
            # Filter by antecedent containing the specified string
            def check_antecedent(antecedents):
                try:
                    for idx in antecedents:
                        if isinstance(idx, int) and 0 <= idx < len(self.feature_names):
                            if antecedent_contains in self.feature_names[idx]:
                                return True
                        elif isinstance(idx, str) and antecedent_contains in idx:
                            return True
                    return False
                except Exception:
                    return False
            
            filtered_df = filtered_df[filtered_df['antecedents'].apply(check_antecedent)]
        
        # Format filtered rules
        return self.format_rules_for_storage(filtered_df)
    
    def get_recommendations(
        self, 
        attributes: List[ProductAttribute],
        min_confidence: float = 0.5,
        min_lift: float = 1.0,
        max_results: int = 10
    ) -> List[Tuple[ProductAttribute, float, float, float]]:
        """Get recommendations based on input attributes"""
        if self.rules_df is None or self.rules_df.empty:
            return []
        
        # Convert input attributes to feature format
        input_features = [f"{attr.attribute_type}_{attr.attribute_value}" for attr in attributes]
        
        # Find matching rules where antecedents contain input features
        matching_rules = []
        
        for _, row in self.rules_df.iterrows():
            try:
                # Get antecedent features
                antecedent_features = []
                for idx in row['antecedents']:
                    if isinstance(idx, int) and 0 <= idx < len(self.feature_names):
                        antecedent_features.append(self.feature_names[idx])
                    else:
                        antecedent_features.append(str(idx))
                
                # Check if any input feature is in antecedents
                if any(feature in antecedent_features for feature in input_features):
                    # Get consequent features
                    consequent_features = []
                    for idx in row['consequents']:
                        if isinstance(idx, int) and 0 <= idx < len(self.feature_names):
                            consequent_features.append(self.feature_names[idx])
                        else:
                            consequent_features.append(str(idx))
                    
                    # Add consequent features as recommendations
                    for feature in consequent_features:
                        # Skip if feature is already in input
                        if feature in input_features:
                            continue
                        
                        # Parse feature to get attribute type and value
                        parts = feature.split('_', 1)
                        if len(parts) == 2:
                            attr_type, attr_value = parts
                            
                            recommendation = (
                                ProductAttribute(attribute_type=attr_type, attribute_value=attr_value),
                                float(row['confidence']),
                                float(row['lift']),
                                float(row['support'])
                            )
                            
                            matching_rules.append(recommendation)
            except Exception as e:
                logger.error(f"Error processing rule for recommendations: {e}")
                continue
        
        # Sort by confidence and lift
        matching_rules.sort(key=lambda x: (x[1], x[2]), reverse=True)
        
        # Filter by confidence and lift
        filtered_rules = [
            rule for rule in matching_rules 
            if rule[1] >= min_confidence and rule[2] >= min_lift
        ]
        
        # Return top results
        return filtered_rules[:max_results]
    
    def get_matching_products(self, attribute: ProductAttribute, limit: int = 5) -> List[ProductSummary]:
        """Get products matching a specific attribute"""
        feature_key = f"{attribute.attribute_type}_{attribute.attribute_value}"
        
        # Check if we have products cached for this feature
        if feature_key in self.products_cache:
            products = self.products_cache[feature_key][:limit]
            return [
                ProductSummary(
                    id=str(product.get("_id", "")),
                    title=product.get("title", ""),
                    brand=product.get("brand", ""),
                    category=product.get("category", ""),
                    sub_category=product.get("sub_category", ""),
                    image_url=product.get("image_url", "")
                )
                for product in products
            ]
        
        return []
    
    async def find_products_by_attribute(self, attribute: ProductAttribute, limit: int = 5) -> List[ProductSummary]:
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
        
        # Convert to ProductSummary objects
        return [
            ProductSummary(
                id=str(product.get("_id", "")),
                title=product.get("title", ""),
                brand=product.get("brand", ""),
                category=product.get("category", ""),
                sub_category=product.get("sub_category", ""),
                image_url=product.get("image_url", "")
            )
            for product in products
        ]
    
    async def get_recommendations_with_products(
        self, 
        attributes: List[ProductAttribute],
        min_confidence: float = 0.5,
        min_lift: float = 1.0,
        max_results: int = 10,
        include_products: bool = True
    ) -> List[Tuple[ProductAttribute, List[ProductSummary], float, float, float]]:
        """Get recommendations with matching products"""
        # Get basic recommendations first
        basic_recommendations = self.get_recommendations(
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
            matching_products = await self.find_products_by_attribute(attr, limit=5)
            
            # Add to results
            recommendations_with_products.append((attr, matching_products, conf, lift, supp))
        
        return recommendations_with_products


# Singleton instance
recommendation_service = RecommendationService() 
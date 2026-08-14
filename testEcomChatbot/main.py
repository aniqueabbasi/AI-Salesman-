from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi import Request
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import os
import logging
from datetime import datetime
from dotenv import load_dotenv
from pymongo import MongoClient
from bson import ObjectId
import openai
import json5  # for lenient JSON parsing
import groq
import json
import certifi
import re
import sys

# Configure logging with UTF-8 encoding
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)  # This will use system default encoding
    ]
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Constants for pagination
ITEMS_PER_PAGE = 5

# Get AI provider from environment
AI_PROVIDER = os.getenv("AI_PROVIDER", "openai").lower()
logger.info(f"Using AI provider: {AI_PROVIDER}")

app = FastAPI(title="E-commerce Chatbot API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure templates
templates = Jinja2Templates(directory="templates")

# Custom JSON encoder to handle MongoDB ObjectId
class MongoJSONEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, ObjectId):
            return str(o)
        if isinstance(o, datetime):
            return o.isoformat()
        return super().default(o)

# MongoDB connection with SSL certificate verification
try:
    client = MongoClient(
        os.getenv("MONGODB_URI"),
        tlsCAFile=certifi.where()
    )
    # Test the connection
    client.admin.command('ping')
    logger.info("Successfully connected to MongoDB")
except Exception as e:
    logger.error(f"Failed to connect to MongoDB: {str(e)}")
    raise

db = client[os.getenv("DATABASE_NAME", "ecommerce")]
products_collection = db[os.getenv("COLLECTION_NAME", "products")]

# Configure AI clients
openai.api_key = os.getenv("OPENAI_API_KEY")
groq_client = groq.Groq(api_key="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")

class ChatRequest(BaseModel):
    message: str
    page: int = 1  # Default to first page

def clean_brand_name(brand: str) -> str:
    """Clean and normalize brand names for comparison."""
    return re.sub(r'[^\w\s]', '', brand.upper().strip())

def calculate_discount_percentage(actual_price: float, selling_price: float) -> float:
    """Calculate discount percentage."""
    if actual_price == 0:
        return 0
    return ((actual_price - selling_price) / actual_price) * 100


def extract_first_json_object(text: str) -> str | None:
    """Return the first syntactically balanced JSON object found in *text*.
    This method walks the string, counting braces while respecting quoted
    strings and escaped characters. It is far more reliable than a regex for
    nested or pretty-printed JSON produced by LLMs.
    """
    start = text.find('{')
    if start == -1:
        return None

    brace_count = 0
    in_string = False
    escape = False

    for idx in range(start, len(text)):
        char = text[idx]
        if in_string:
            if escape:
                escape = False
            elif char == '\\':
                escape = True
            elif char == '"':
                in_string = False
        else:
            if char == '"':
                in_string = True
            elif char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0:
                    return text[start:idx + 1]
    return None

def process_with_ai(message: str, page: int = 1) -> Dict[str, Any]:
    """Process user message with the configured AI provider."""
    logger.info(f"Processing message with {AI_PROVIDER}: {message}")
    
    # Check for greetings
    greetings = {"hi", "hello", "hey", "good morning", "good afternoon", "good evening", "hi there", "hello there"}
    if message.lower().strip() in greetings:
        return {
            "is_product_query": False,
            "query_params": {},
            "response_text": "Hello! I'm your fashion shopping assistant. I can help you find products, compare brands, and check discounts. Feel free to ask me about specific items, brands, or deals!",
            "should_compare": False,
            "pagination_context": {
                "has_more": False,
                "current_page": page,
                "show_more_prompt": ""
            },
            "comparison_context": {
                "is_comparing_brands": False,
                "brands": [],
                "comparison_type": None
            },
            "debug_info": "Greeting message detected"
        }

    # Define default response structure
    default_response = {
        "is_product_query": False,
        "query_params": {},
        "response_text": "I'm here to help you find products! You can ask me about specific items, brands, or discounts.",
        "should_compare": False,
        "pagination_context": {
            "has_more": False,
            "current_page": page,
            "show_more_prompt": "Would you like to see more?"
        },
        "comparison_context": {
            "is_comparing_brands": False,
            "brands": [],
            "comparison_type": None
        },
        "debug_info": "Default response"
    }

    system_prompt = """You are a helpful e-commerce fashion shopping assistant. Your main task is to understand user queries about products, brands, and discounts, handling them in a conversational way.

IMPORTANT RULES:
1. DO NOT return product queries for greetings or general conversation
2. Only set is_product_query=true when the user specifically asks about products
3. For general conversation, questions about capabilities, or greetings, set is_product_query=false
4. Always provide helpful guidance about what the user can ask about

QUERY TYPES TO HANDLE:

1. Product Search Queries:
   - Filter by category, sub-category, gender, price range
   - Handle specific attributes like color, size, fabric
   - Example: "Show me men's t-shirts under ₹500"
   - Example: "Find multicolor cotton track pants for men"

2. Product Comparison Queries:
   - Compare specific products by ID
   - Compare products from different brands
   - Compare prices, ratings, fabrics, and features
   - Example: "Compare York track pants and Discount Outlet blue t-shirt"
   - Example: "What's the difference between TKPFCZ9EA7H5FYZH and TSHFWSZJDWBTC7PP?"

3. Brand Analysis Queries:
   - Find brands within price ranges
   - Compare brand offerings
   - Analyze brand ratings and reviews
   - Example: "Which brands offer track pants under ₹1000?"

4. Rating and Review Queries:
   - Find top-rated products in categories
   - Compare product reviews
   - Example: "What are the top-rated products in bottomwear?"

DATABASE SCHEMA:
{
    "category": "Clothing and Accessories" or "Footwear",
    "sub_category": "Topwear", "Bottomwear", etc.,
    "brand": "Brand name",
    "selling_price": numeric value,
    "actual_price": numeric value,
    "discount": "Percentage off",
    "title": "Product title",
    "description": "Product description",
    "product_details": [
        {"Color": "color value"},
        {"Fabric": "fabric type"},
        {"Pattern": "pattern type"},
        {"Fit": "fit type"},
        {"Style": "style description"}
    ],
    "rating": numeric value,
    "reviews": [
        {
            "text": "review text",
            "rating": numeric value
        }
    ]
}

QUERY CONSTRUCTION RULES:
1. For price filters: Use $lte, $gte operators
2. For text searches: Use case-insensitive regex with $regex
3. For multiple conditions: Combine with $and operator
4. For brand comparisons: Use $in operator with brand names
5. For ratings: Use $gte for minimum rating threshold

RESPONSE FORMAT:
{
    "is_product_query": boolean,
    "query_params": {
        // MongoDB query object
        // Example for "men's t-shirts under ₹500":
        "$and": [
            {"sub_category": {"$regex": "Topwear", "$options": "i"}},
            {"title": {"$regex": "t-shirt", "$options": "i"}},
            {"selling_price": {"$lte": 500}},
            {"product_details.Gender": {"$regex": "men", "$options": "i"}}
        ]
    },
    "response_text": "Your natural response to the user",
    "should_compare": boolean,
    "pagination_context": {
        "has_more": boolean,
        "current_page": number,
        "show_more_prompt": "Natural language prompt for more results"
    },
    "comparison_context": {
        "is_comparing_brands": boolean,
        "brands": [list of brand names],
        "comparison_type": "price|rating|features|all"
    },
    "debug_info": "Explanation of query interpretation"
}"""

    try:
        # Get AI response
        if AI_PROVIDER == "groq":
            response = groq_client.chat.completions.create(
                model="meta-llama/llama-4-scout-17b-16e-instruct",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"{message} (page: {page})"}
                ],
                temperature=0.7,
            )
            result = response.choices[0].message.content
        else:  # default to OpenAI
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"{message} (page: {page})"}
                ],
                temperature=0.7
            )
            result = response.choices[0].message.content
        
        logger.debug(f"Raw AI response: {result}")
        
        try:
            # Clean up the response to ensure valid JSON
            result = result.strip()
            # Remove ```json or ``` fences (case insensitive)
            result = re.sub(r'```[a-zA-Z]*\s*|```', '', result, flags=re.IGNORECASE)

            # Extract the first syntactically balanced JSON object
            json_str = extract_first_json_object(result)
            if not json_str:
                logger.error("No balanced JSON object found in AI response. Raw output was: %s", result[:2000])
                return default_response

            result = json_str
            try:
                parsed_result = json.loads(result)
            except json.JSONDecodeError:
                # Sometimes the model outputs trailing commas/comments; try json5 as fallback
                try:
                    import json5
                    parsed_result = json5.loads(result)
                except Exception as je:
                    logger.error("json5 fallback failed: %s", str(je))
                    raise
            
            # Merge parsed result with defaults
            for key, default_value in default_response.items():
                if key not in parsed_result:
                    parsed_result[key] = default_value
                elif isinstance(default_value, dict):
                    parsed_result[key] = {**default_value, **parsed_result.get(key, {})}
            
            logger.info(f"Query interpretation: {parsed_result['debug_info']}")
            return parsed_result
                
        except json.JSONDecodeError as je:
            logger.error(f"Error parsing AI response JSON: {str(je)}")
            return default_response
        except Exception as e:
            logger.error(f"Error processing AI response: {str(e)}")
            return default_response
            
    except Exception as e:
        logger.error(f"Error in AI processing: {str(e)}")
        return default_response

def query_products(query_params: Dict[str, Any], page: int = 1, sort_params: Dict[str, Any] = None) -> List[Dict]:
    """Query MongoDB products collection with pagination and sorting."""
    try:
        skip = (page - 1) * ITEMS_PER_PAGE
        logger.debug(f"Original query params: {json.dumps(query_params)}")
        
        # Normalize the query parameters
        normalized_query = {}
        
        # Handle text searches with case-insensitive regex
        text_fields = ['title', 'brand', 'description', 'sub_category']
        for field in text_fields:
            if field in query_params:
                if isinstance(query_params[field], dict) and '$regex' in query_params[field]:
                    # Already a regex query, just ensure case insensitivity
                    query_params[field]['$options'] = 'i'
                    normalized_query[field] = query_params[field]
                else:
                    # Convert to regex query
                    normalized_query[field] = {
                        '$regex': query_params[field],
                        '$options': 'i'
                    }
        
        # Handle numeric comparisons (price, rating)
        numeric_fields = ['selling_price', 'actual_price', 'rating']
        for field in numeric_fields:
            if field in query_params:
                if isinstance(query_params[field], dict):
                    # Already a comparison query
                    normalized_query[field] = query_params[field]
                else:
                    # Convert to exact match
                    normalized_query[field] = float(query_params[field])
        
        # Handle product details as nested fields
        if 'product_details' in query_params:
            details = query_params['product_details']
            for key, value in details.items():
                field_path = f"product_details.{key}"
                normalized_query[field_path] = {
                    '$regex': value,
                    '$options': 'i'
                }
        
        # Handle $and, $or operators
        for op in ['$and', '$or']:
            if op in query_params:
                normalized_query[op] = query_params[op]
        
        logger.debug(f"Normalized query: {json.dumps(normalized_query)}")
        
        # Apply default sorting by rating for top-rated queries
        if sort_params is None:
            sort_params = {}
        
        cursor = products_collection.find(normalized_query)
        
        # Apply sorting if specified
        if sort_params:
            cursor = cursor.sort([(k, v) for k, v in sort_params.items()])
        
        # Apply pagination
        cursor = cursor.skip(skip).limit(ITEMS_PER_PAGE)
        results = list(cursor)
        
        # Add computed fields
        for product in results:
            # Calculate discount percentage
            product['discount_percentage'] = calculate_discount_percentage(
                float(product.get('actual_price', 0)),
                float(product.get('selling_price', 0))
            )
            
            # Extract product details into a more accessible format
            if 'product_details' in product:
                details = {}
                for detail in product['product_details']:
                    if isinstance(detail, dict):
                        details.update(detail)
                product['formatted_details'] = details
            
            # Calculate average rating if reviews exist
            if 'reviews' in product and product['reviews']:
                ratings = [review.get('rating', 0) for review in product['reviews']]
                product['avg_rating'] = sum(ratings) / len(ratings) if ratings else 0
                product['review_count'] = len(ratings)
        
        total_count = products_collection.count_documents(normalized_query)
        logger.info(f"Query returned {len(results)} products (total: {total_count})")
        
        return results
    except Exception as e:
        logger.error(f"Error querying MongoDB: {str(e)}")
        raise

def compare_products(products: List[Dict], comparison_type: str = "all") -> str:
    """Generate a detailed comparison between products."""
    if not products or len(products) < 2:
        return "Not enough products to compare."
    
    comparison_text = []
    
    # Header with product names
    comparison_text.append("Product Comparison:")
    for product in products:
        comparison_text.append(f"\n{product['brand']} - {product['title']}")
    
    if comparison_type in ["price", "all"]:
        comparison_text.append("\nPrice Comparison:")
        for product in products:
            price_info = (
                f"- {product['brand']}: ₹{product['selling_price']} "
                f"(Original: ₹{product['actual_price']}, "
                f"Discount: {product['discount_percentage']:.1f}%)"
            )
            comparison_text.append(price_info)
    
    if comparison_type in ["rating", "all"]:
        comparison_text.append("\nRating Comparison:")
        for product in products:
            rating_info = (
                f"- {product['brand']}: "
                f"{product.get('avg_rating', 0):.1f}/5 "
                f"({product.get('review_count', 0)} reviews)"
            )
            comparison_text.append(rating_info)
    
    if comparison_type in ["features", "all"]:
        comparison_text.append("\nFeature Comparison:")
        # Collect all possible feature keys
        all_features = set()
        for product in products:
            if 'formatted_details' in product:
                all_features.update(product['formatted_details'].keys())
        
        # Compare each feature
        for feature in sorted(all_features):
            comparison_text.append(f"\n{feature}:")
            for product in products:
                value = product.get('formatted_details', {}).get(feature, 'Not specified')
                comparison_text.append(f"- {product['brand']}: {value}")
    
    return "\n".join(comparison_text)

@app.get("/")
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    try:
        logger.info(f"Received chat request: {request.message} (page: {request.page})")
        
        # Process the message with AI
        ai_response = process_with_ai(request.message, request.page)
        logger.debug(f"AI Response: {json.dumps(ai_response)}")
        
        # Initialize response data
        response_data = {
            "message": ai_response["response_text"],
            "products": [],
            "is_comparison": ai_response["should_compare"],
            "has_more": False,
            "show_more_prompt": ai_response["pagination_context"]["show_more_prompt"]
        }
        
        if ai_response["is_product_query"] and ai_response["query_params"]:
            try:
                # Handle sorting for top-rated queries
                sort_params = None
                if "top-rated" in request.message.lower():
                    sort_params = {"avg_rating": -1}
                
                products = query_products(
                    ai_response["query_params"], 
                    request.page,
                    sort_params
                )
                total_count = products_collection.count_documents(ai_response["query_params"])
                
                # Handle product comparisons
                if ai_response["should_compare"]:
                    if ai_response["comparison_context"]["is_comparing_brands"]:
                        brands = ai_response["comparison_context"]["brands"]
                        comparison_type = ai_response["comparison_context"]["comparison_type"]
                        
                        # Filter products by the specified brands
                        brand_products = [p for p in products if p["brand"] in brands]
                        
                        # Generate comparison text
                        comparison_text = compare_products(brand_products, comparison_type)
                        response_data["message"] = comparison_text
                    
                    # Add product details for side-by-side comparison in UI
                    response_data["products"] = products
                    response_data["comparison_type"] = ai_response["comparison_context"]["comparison_type"]
                else:
                    response_data["products"] = products
                
                response_data["has_more"] = total_count > (request.page * ITEMS_PER_PAGE)
                
                logger.info(f"Found {len(products)} products on page {request.page} (total: {total_count})")
                
                if not products:
                    if request.page > 1:
                        response_data["message"] = "That's all the products I could find! Would you like to try a different search?"
                    else:
                        response_data["message"] = (
                            "I couldn't find any products matching those criteria. "
                            "Try describing what you're looking for differently, or ask about other brands or styles."
                        )
                
            except Exception as db_error:
                logger.error(f"Database query error: {str(db_error)}")
                response_data["message"] = "I encountered an error while searching for products. Please try again."
        
        # Log and serialize response with custom encoder
        logger.info("Response JSON:\n%s", json.dumps(response_data, cls=MongoJSONEncoder, indent=2, ensure_ascii=False))
        return JSONResponse(
            content=json.loads(json.dumps(response_data, cls=MongoJSONEncoder)),
            status_code=200
        )
    
    except Exception as e:
        logger.error(f"Chat endpoint error: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"message": "An error occurred while processing your request. Please try again."}
        )

# Verify database connection and data
def verify_database():
    try:
        # Test the connection
        client.admin.command('ping')
        
        # Check if we have data
        total_products = products_collection.count_documents({})
        logger.info(f"Successfully connected to MongoDB. Total products in database: {total_products}")
        
        if total_products == 0:
            logger.warning("Database is empty! Please populate the database with product data.")
            
        # Log sample product to verify data structure
        sample_product = products_collection.find_one({})
        if sample_product:
            logger.info("Sample product structure:")
            logger.info(json.dumps(sample_product, default=str, indent=2))
            
    except Exception as e:
        logger.error(f"Database verification failed: {str(e)}")
        raise

# Call verification on startup
verify_database()

if __name__ == "__main__":
    logger.info("Starting server...")
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 
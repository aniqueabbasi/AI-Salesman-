import json
import logging
import asyncio
from pathlib import Path
from typing import List, Dict, Any
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# MongoDB connection details
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
DB_NAME = os.getenv("DB_NAME", "recommendation_system")
COLLECTION_NAME = "products"

async def load_json_data(file_path: str) -> List[Dict[str, Any]]:
    """Load data from a JSON file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        logger.info(f"Loaded {len(data)} records from {file_path}")
        return data
    except Exception as e:
        logger.error(f"Error loading data from {file_path}: {e}")
        return []

async def transform_data(data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Transform data to match our schema"""
    transformed_data = []
    
    for item in data:
        # Extract product details
        product_details = []
        
        # Check if product_details exists and is a dictionary
        if "product_details" in item and isinstance(item["product_details"], dict):
            for key, value in item["product_details"].items():
                if value:  # Only add non-empty values
                    product_details.append({"key": key, "value": value})
        
        # Create transformed product
        transformed_product = {
            "title": item.get("product_name", ""),
            "brand": item.get("brand", ""),
            "category": item.get("category", ""),
            "sub_category": item.get("sub_category", ""),
            "product_details": product_details,
            "images": item.get("images", [])  # Include images array from dataset
        }
        
        transformed_data.append(transformed_product)
    
    logger.info(f"Transformed {len(transformed_data)} products")
    return transformed_data

async def insert_data_to_mongodb(data: List[Dict[str, Any]]) -> None:
    """Insert data into MongoDB"""
    try:
        # Connect to MongoDB
        client = AsyncIOMotorClient(MONGO_URI)
        db = client[DB_NAME]
        collection = db[COLLECTION_NAME]
        
        # Drop existing collection
        await collection.drop()
        logger.info(f"Dropped existing collection: {COLLECTION_NAME}")
        
        # Insert data
        if data:
            result = await collection.insert_many(data)
            logger.info(f"Inserted {len(result.inserted_ids)} products into MongoDB")
        else:
            logger.warning("No data to insert")
    except Exception as e:
        logger.error(f"Error inserting data to MongoDB: {e}")
    finally:
        client.close()

async def load_sample_data(file_path: str) -> None:
    """Load sample data into MongoDB"""
    # Load data from JSON file
    data = await load_json_data(file_path)
    
    # Transform data
    transformed_data = await transform_data(data)
    
    # Insert data into MongoDB
    await insert_data_to_mongodb(transformed_data)

if __name__ == "__main__":
    # Get file path from command line arguments or use default
    import sys
    file_path = sys.argv[1] if len(sys.argv) > 1 else "flipkart_fashion_products_dataset (3).json"
    
    # Run the data loader
    asyncio.run(load_sample_data(file_path)) 
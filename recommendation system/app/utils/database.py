import os
import logging
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

logger = logging.getLogger(__name__)

# MongoDB connection details
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
DB_NAME = os.getenv("DB_NAME", "recommendation_system")

# Global database client and database instances
client = None
db = None

async def init_db():
    """Initialize database connection"""
    global client, db
    try:
        client = AsyncIOMotorClient(MONGO_URI)
        db = client[DB_NAME]
        logger.info(f"Connected to MongoDB at {MONGO_URI}")
        
        # Ping the database to verify connection
        await db.command("ping")
        logger.info("Database connection verified")
        
        return db
    except Exception as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        raise

def get_db():
    """Get database instance"""
    if db is None:
        raise Exception("Database not initialized. Call init_db() first.")
    return db

def get_collection(collection_name):
    """Get collection by name"""
    return get_db()[collection_name] 
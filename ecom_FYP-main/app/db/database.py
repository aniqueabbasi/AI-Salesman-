from pymongo import MongoClient
from pymongo.server_api import ServerApi
from app.core.config import settings
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize MongoDB client with error handling
try:
    # Log the connection attempt
    logger.info("Attempting to connect to MongoDB...")
    
    # Create the MongoDB client
    import certifi

# Use certifi CA bundle to trust Atlas certificates
    client = MongoClient(
        settings.MONGO_URI,
        tls=True,
        tlsCAFile=certifi.where(),

        server_api=ServerApi('1'),
        serverSelectionTimeoutMS=5000
    )
    
    # Verify the connection
    client.admin.command('ping')
    logger.info("Successfully connected to MongoDB!")
    
    # Set up database and collections
    db = client['ecommerce']  # Database name
    users_collection = db['users']
    products_collection = db['products']
    orders_collection = db['orders']
    notifications_collection = db['notifications']
    user_activity_collection = db['user_activity']
    inventory_collection = db['inventory']
    promotions_collection = db['promotions']
except Exception as e:
    logger.error(f"Failed to connect to MongoDB: {str(e)}")
    logger.warning("Using a mock database for development. Data will not be persisted.")

    from app.db.mock_db import MockDB, seed

    # Initialize mock database and collections
    db = MockDB()
    seed(db)
    users_collection = db['users']
    products_collection = db['products']
    orders_collection = db['orders']
    notifications_collection = db['notifications']
    user_activity_collection = db['user_activity']
    inventory_collection = db['inventory']
    promotions_collection = db['promotions']

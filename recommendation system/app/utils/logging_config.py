import logging
import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def configure_logging():
    """Configure logging for the application"""
    log_level_name = os.getenv("LOG_LEVEL", "INFO").upper()
    log_level = getattr(logging, log_level_name, logging.INFO)
    
    # Configure root logger
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    # Set specific loggers to DEBUG level for more detailed information
    logging.getLogger("app.services.recommendation_service").setLevel(logging.DEBUG)
    
    # Reduce logging from other libraries
    logging.getLogger("uvicorn").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.error").setLevel(logging.ERROR)
    
    logging.info(f"Logging configured with level: {log_level_name}") 
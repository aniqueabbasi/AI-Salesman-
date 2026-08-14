from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from contextlib import asynccontextmanager

from app.api.routes import recommendation_router
from app.utils.database import init_db
from app.utils.logging_config import configure_logging
from app.services.recommendation_service import recommendation_service

# Configure logging
configure_logging()
logger = logging.getLogger(__name__)


# Define lifespan handler
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup code
    await init_db()

    if recommendation_service.is_model_trained():
        model_info = recommendation_service.get_model_info()
        logger.info(f"✅ Model loaded successfully on startup")
        logger.info(f"   - Rules: {model_info['rules_count']}")
        logger.info(f"   - Features: {model_info['features_count']}")
        logger.info(f"   - Products cached: {model_info['products_cache_size']}")
    else:
        logger.info("⚠️  No trained model found. Model will need to be trained using POST /api/train")

    logger.info("Application startup complete")

    yield  # <-- This allows the app to run

    # Shutdown code (optional)
    logger.info("Application shutdown initiated...")


# Create FastAPI app with lifespan
app = FastAPI(
    title="Product Recommendation API",
    description="API for product recommendations using association rule mining",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(recommendation_router, prefix="/api", tags=["recommendations"])


# Root endpoint
@app.get("/")
async def root():
    model_status = "trained" if recommendation_service.is_model_trained() else "not_trained"
    return {
        "message": "Product Recommendation API is running",
        "model_status": model_status,
        "endpoints": {
            "train_model": "POST /api/train",
            "get_recommendations": "POST /api/recommend",
            "get_rules": "GET /api/rules",
            "model_status": "GET /api/model/status"
        }
    }

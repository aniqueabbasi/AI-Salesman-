from pathlib import Path

import uvicorn
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from app.routes import auth, product, order, notification, analytics, activity, push, order_tracking, inventory, report, promotion, chat
from app.core.middleware import setup_cors_middleware
from app.core.error_handlers import setup_error_handlers

app = FastAPI()

# Serve seller-uploaded product photos at /media/<filename>.
UPLOAD_DIR = Path(__file__).resolve().parent / "static" / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/media", StaticFiles(directory=str(UPLOAD_DIR)), name="media")

# Setup CORS middleware
setup_cors_middleware(app)

# Setup error handlers
setup_error_handlers(app)

@app.get("/")
async def root():
    return JSONResponse({
        "message": "Welcome to the E-Commerce API",
        "documentation": "/docs",
        "endpoints": {
            "auth": "/auth",
            "products": "/products",
            "orders": "/orders",
            "notifications": "/notifications",
            "analytics": "/analytics",
            "activity": "/activity",
            "push": "/push",
            "order_tracking": "/orders/tracking",
            "inventory": "/inventory",
            "reports": "/reports",
            "promotions": "/promotions",
            "support": "/support"
        }
    })

app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(product.router, prefix="/products", tags=["Products"])
app.include_router(order.router, prefix="/orders", tags=["Orders"])
app.include_router(notification.router, prefix="/notifications", tags=["Notifications"])
app.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
app.include_router(activity.router, prefix="/activity", tags=["User Activity"])
app.include_router(push.router, prefix="/push", tags=["Push Notifications"])
app.include_router(order_tracking.router, prefix="/orders/tracking", tags=["Order Tracking"])
app.include_router(inventory.router, prefix="/inventory", tags=["Inventory"])
app.include_router(report.router, prefix="/reports", tags=["Reports"])
app.include_router(promotion.router, prefix="/promotions", tags=["Promotions"])
app.include_router(chat.router, prefix="/support", tags=["Chat"])

if __name__ == "__main__":
    # Bind to all network interfaces for access from other devices in the network
    uvicorn.run(app, host="0.0.0.0", port=8000)

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
import logging

from app.core.config import settings
from app.core.database import engine, Base, get_db, init_db, check_db_connection
# Import models in dependency order (User before Content due to relationships)
from app.models.user_model import User
from app.models.content_model import Content
from app.models.question_model import Question, QuestionComment, QuestionLike, QuestionSave
from app.models.notification_model import Notification
from app.models.wellness_model import Milestone, UserMilestone
from app.schemas.user_schema import UserCreate, UserResponse
from app.routes import auth_routes, content_routes, question_routes, notification_routes, admin_routes, wellness_routes

# Configure logging
logging.basicConfig(level=logging.INFO if settings.debug else logging.WARNING)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Psychology App API",
    description="Backend API for the Psychology Content App",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_routes.router, prefix="/api/auth", tags=["authentication"])
app.include_router(content_routes.router, prefix="/api/content", tags=["content"])
app.include_router(question_routes.router, prefix="/api/qa", tags=["qa"])
app.include_router(notification_routes.router, prefix="/api/notifications", tags=["notifications"])
app.include_router(admin_routes.router, prefix="/api", tags=["admin"])
app.include_router(wellness_routes.router, prefix="/api/wellness", tags=["wellness"])

@app.on_event("startup")
async def startup_event():
    """Initialize database and check connections on startup"""
    logger.info("Starting Psychology App API...")
    
    # Check database connection
    if check_db_connection():
        logger.info("✅ Database connection successful")
    else:
        logger.error("❌ Database connection failed")
        raise RuntimeError("Database connection failed")
    
    # Initialize database tables
    try:
        init_db()
        logger.info("✅ Database tables initialized")
    except Exception as e:
        logger.error(f"❌ Failed to initialize database: {e}")
        raise RuntimeError(f"Database initialization failed: {e}")
    
    logger.info(f"🚀 Psychology App API started in {settings.environment} mode")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down Psychology App API...")

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to Psychology App API",
        "version": "1.0.0",
        "environment": settings.environment,
        "debug": settings.debug
    }

@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    """Health check endpoint"""
    try:
        # Test database connection
        from sqlalchemy import text
        db.execute(text("SELECT 1"))
        
        return {
            "status": "healthy",
            "database": "connected",
            "environment": settings.environment,
            "timestamp": "2024-01-01T00:00:00Z"  # Will be actual timestamp in production
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Service unhealthy - database connection failed"
        )

@app.get("/api/info")
async def api_info():
    """API information endpoint"""
    return {
        "name": "Psychology App API",
        "version": "1.0.0",
        "environment": settings.environment,
        "features": {
            "authentication": True,
            "user_management": True,
            "content_management": True,
            "admin_panel": True
        },
        "database_type": "PostgreSQL" if "postgresql" in settings.database_url else "SQLite"
    }

if __name__ == "__main__":
    import uvicorn
    import os
    
    # Get port from environment variable (Render sets this)
    port = int(os.environ.get("PORT", 8000))
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=settings.debug,
        log_level="info" if settings.debug else "warning"
    )
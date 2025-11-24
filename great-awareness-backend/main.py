from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
import logging

from app.core.config import settings
from app.core.database import engine, Base, get_db, init_db, check_db_connection
from app.models.user_model import User
from app.schemas.user_schema import UserCreate, UserResponse
from app.routes import auth_routes

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
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
        log_level="info" if settings.debug else "warning"
    )
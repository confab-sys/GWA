from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool
from app.core.config import settings
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create declarative base
Base = declarative_base()

# Database engine configuration
def get_engine():
    """Create database engine with PostgreSQL optimization"""
    database_url = settings.sqlalchemy_database_uri
    
    if "postgresql" in database_url:
        # PostgreSQL specific configuration
        engine = create_engine(
            database_url,
            pool_size=10,
            max_overflow=20,
            pool_pre_ping=True,
            pool_recycle=3600,
            echo=settings.debug  # SQL logging in debug mode
        )
    else:
        # Fallback for other databases (SQLite, etc.)
        connect_args = {}
        if "sqlite" in database_url:
            connect_args = {"check_same_thread": False}
        
        engine = create_engine(
            database_url,
            connect_args=connect_args,
            echo=settings.debug
        )
    
    logger.info(f"Database engine created for: {database_url.split('@')[-1] if '@' in database_url else database_url}")
    return engine

# Create engine
engine = get_engine()

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db() -> Session:
    """Database session dependency"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initialize database tables"""
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Error creating database tables: {e}")
        raise

def check_db_connection():
    """Test database connection"""
    try:
        db = SessionLocal()
        from sqlalchemy import text
        db.execute(text("SELECT 1"))
        db.close()
        logger.info("Database connection successful")
        return True
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return False

# Metadata for migrations
metadata = MetaData()
from typing import List, Optional
from pydantic_settings import BaseSettings
from pydantic import validator
import json

class Settings(BaseSettings):
    # Environment
    environment: str = "development"
    debug: bool = True
    
    # Security
    secret_key: str = "your-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    
    # Database
    database_url: str = "sqlite:///./psychology_app.db"  # SQLite for development
    database_url_render: Optional[str] = None  # PostgreSQL for production
    
    # CORS
    cors_origins: List[str] = ["http://localhost:3000", "http://localhost:8080"]
    
    # File Upload Settings
    max_file_size: int = 5 * 1024 * 1024  # 5MB
    allowed_file_types: List[str] = ["image/jpeg", "image/png", "image/jpg"]
    
    # User Settings
    default_user_role: str = "user"
    allowed_user_roles: List[str] = ["user", "admin", "content_creator"]
    user_status_active: str = "active"
    user_status_inactive: str = "inactive"
    user_status_suspended: str = "suspended"
    
    @validator("cors_origins", pre=True)
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            return json.loads(v)
        return v
    
    @validator("allowed_file_types", pre=True)
    def parse_allowed_file_types(cls, v):
        if isinstance(v, str):
            return json.loads(v)
        return v
    
    @property
    def database_uri(self) -> str:
        """Get the appropriate database URL based on environment"""
        if self.environment == "production" and self.database_url_render:
            return self.database_url_render
        return self.database_url
    
    @property
    def sqlalchemy_database_uri(self) -> str:
        """Get SQLAlchemy compatible database URL"""
        return self.database_uri
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False

# Create settings instance
settings = Settings()
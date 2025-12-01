from typing import List, Optional
from pydantic import BaseSettings, validator
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
    database_url_render: Optional[str] = "postgresql://neondb_owner:npg_liZTRxQeq23k@ep-odd-leaf-adse08ig-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"  # PostgreSQL for production - set via RENDER env var
    
    # CORS
    cors_origins: List[str] = [
        "http://localhost:3000", 
        "http://localhost:8080", 
        "http://localhost:8081", 
        "http://127.0.0.1:3000",
        "http://localhost:5353",
        "http://localhost:5000",
        "https://gwa-enus.onrender.com",
        "https://great-awareness-frontend.vercel.app",
        "https://great-awareness-frontend-9urb9gcqx-confab-sys-projects.vercel.app"
    ]
    
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
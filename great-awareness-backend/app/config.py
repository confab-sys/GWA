# Legacy config file - import from core.config instead
from app.core.config import settings

# Re-export for backward compatibility
SECRET_KEY = settings.secret_key
DATABASE_URL = settings.sqlalchemy_database_uri
ACCESS_TOKEN_EXPIRE_MINUTES = settings.access_token_expire_minutes
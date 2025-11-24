# Legacy database file - import from core.database instead
from app.core.database import engine, SessionLocal, Base, get_db, init_db, check_db_connection

# Re-export for backward compatibility
__all__ = ['engine', 'SessionLocal', 'Base', 'get_db', 'init_db', 'check_db_connection']
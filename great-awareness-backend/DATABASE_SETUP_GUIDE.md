# PostgreSQL (Render) Database Setup Guide

This guide explains the complete database setup for the great-awareness-backend, including the architecture, configuration, and how to use it in both development and production environments.

## 📋 Overview

The backend now supports **PostgreSQL** for production (Render) and **SQLite** for local development, with automatic environment-based switching. The setup includes:

- **SQLAlchemy ORM** for database operations
- **Alembic** for database migrations
- **Pydantic Settings** for environment-based configuration
- **Enhanced User Model** with all requested fields
- **Role-Based Access Control** support

## 🏗️ Architecture

### Project Structure
```
great-awareness-backend/
├── app/
│   ├── core/
│   │   ├── config.py          # Environment configuration
│   │   └── database.py        # Database connection & session management
│   ├── models/
│   │   └── user_model.py      # Enhanced User model
│   ├── schemas/
│   │   └── user_schema.py     # Pydantic validation schemas
│   ├── config.py              # Legacy compatibility
│   └── database.py            # Legacy compatibility
├── alembic/
│   ├── versions/              # Migration files
│   ├── env.py                 # Migration environment config
│   └── alembic.ini            # Alembic configuration
├── main.py                    # FastAPI application entry point
├── requirements.txt           # Dependencies
├── .env                       # Environment variables (local)
└── .env.example              # Environment template
```

### Database Architecture

#### User Model Schema
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    role VARCHAR(20) NOT NULL DEFAULT 'user',
    profile_image VARCHAR(500),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME
);

-- Indexes for performance
CREATE INDEX ix_users_email ON users(email);
CREATE INDEX ix_users_username ON users(username);
CREATE INDEX ix_users_status ON users(status);
CREATE INDEX ix_users_role ON users(role);
CREATE INDEX ix_users_id ON users(id);
```

## 🔧 Configuration

### Environment-Based Settings (`app/core/config.py`)

The configuration uses **Pydantic Settings** with automatic environment detection:

```python
class Settings(BaseSettings):
    environment: str = "development"  # development/production
    debug: bool = True
    
    # Database URLs
    database_url: str = "sqlite:///./psychology_app.db"  # Development
    database_url_render: Optional[str] = None  # Production
    
    @property
    def database_uri(self) -> str:
        """Get the appropriate database URL based on environment"""
        if self.environment == "production" and self.database_url_render:
            return self.database_url_render
        return self.database_url
```

### Environment Variables

#### Development (.env)
```bash
# Environment Configuration
ENVIRONMENT=development
DEBUG=True

# Database URLs
DATABASE_URL=sqlite:///./psychology_app.db
DATABASE_URL_RENDER=postgresql://username:password@localhost:5432/psychology_app_db

# Security
SECRET_KEY=your-development-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
CORS_ORIGINS=["http://localhost:3000", "http://localhost:8080"]
```

#### Production (Render)
```bash
# Environment Configuration
ENVIRONMENT=production
DEBUG=False

# Database URLs
DATABASE_URL=sqlite:///./psychology_app.db  # Fallback
DATABASE_URL_RENDER=postgresql://your-render-user:your-render-password@your-render-host:5432/your-render-database

# Security (use strong secrets in production)
SECRET_KEY=your-super-secure-production-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS (update with your production frontend URL)
CORS_ORIGINS=["https://your-production-frontend.com"]
```

## 🗄️ Database Connection (`app/core/database.py`)

### Engine Creation
The database engine is automatically configured based on the database type:

```python
def get_engine():
    """Create database engine with PostgreSQL optimization"""
    database_url = settings.sqlalchemy_database_uri
    
    if "postgresql" in database_url:
        # PostgreSQL specific configuration for production
        engine = create_engine(
            database_url,
            pool_size=10,              # Connection pool size
            max_overflow=20,           # Maximum overflow connections
            pool_pre_ping=True,        # Verify connections before use
            pool_recycle=3600,         # Recycle connections after 1 hour
            echo=settings.debug        # SQL logging in debug mode
        )
    else:
        # SQLite for development
        engine = create_engine(
            database_url,
            connect_args={"check_same_thread": False},
            echo=settings.debug
        )
    
    return engine
```

### Session Management
Dependency injection pattern for database sessions:

```python
def get_db() -> Session:
    """Database session dependency"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

## 👤 Enhanced User Model (`app/models/user_model.py`)

### All Requested Fields
- ✅ `id` - Primary key with auto-increment
- ✅ `email` - Unique, indexed, 255 characters
- ✅ `username` - Unique, indexed, 50 characters
- ✅ `password_hash` - Password storage
- ✅ `created_at` - Timestamp with server default
- ✅ `updated_at` - Timestamp with auto-update
- ✅ `status` - User status (active/inactive/suspended)
- ✅ `last_login` - Last login timestamp
- ✅ `profile_image` - Profile image URL (500 characters)
- ✅ `role` - User role (user/admin/content_creator)
- ✅ `is_verified` - Email verification status

### Helper Properties
```python
@property
def is_active(self):
    """Check if user is active"""
    return self.status == "active"

@property
def is_admin(self):
    """Check if user is admin"""
    return self.role == "admin"

@property
def is_content_creator(self):
    """Check if user can create content"""
    return self.role in ["admin", "content_creator"]
```

## 🔄 Migrations

### Creating Migrations
```bash
# Generate a new migration (detects model changes)
alembic revision --autogenerate -m "Description of changes"

# Apply migrations
alembic upgrade head

# Check current migration status
alembic current

# Downgrade to previous migration
alembic downgrade -1
```

### Migration Workflow
1. **Modify models** in `app/models/`
2. **Generate migration** with `alembic revision --autogenerate`
3. **Review migration** file in `alembic/versions/`
4. **Apply migration** with `alembic upgrade head`

## 🚀 Development vs Production

### Local Development
- **Database**: SQLite (`psychology_app.db`)
- **Configuration**: Uses `.env` file
- **Debug**: Enabled for detailed logging
- **CORS**: Allows localhost origins

### Production (Render)
- **Database**: PostgreSQL (configured via `DATABASE_URL_RENDER`)
- **Configuration**: Environment variables set in Render dashboard
- **Debug**: Disabled for security
- **CORS**: Restricted to production frontend

## 📊 Database Operations

### Basic Usage Example
```python
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user_model import User

# Dependency injection in FastAPI
@app.post("/users/")
def create_user(user_data: UserCreate, db: Session = Depends(get_db)):
    # Create new user
    new_user = User(
        email=user_data.email,
        username=user_data.username,
        password_hash=hash_password(user_data.password),
        role="user",
        status="active"
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user
```

### Query Examples
```python
# Get user by email
user = db.query(User).filter(User.email == email).first()

# Get active users
active_users = db.query(User).filter(User.status == "active").all()

# Get admin users
admins = db.query(User).filter(User.role == "admin").all()

# Update user last login
user.last_login = datetime.utcnow()
db.commit()
```

## 🔐 Security Features

### Password Security
- Passwords are hashed using bcrypt (via `passlib`)
- Never store plain text passwords
- Use `password_hash` field only

### Role-Based Access Control
```python
# Check if user is admin
if current_user.is_admin:
    # Allow admin operations

# Check if user can create content
if current_user.is_content_creator:
    # Allow content creation
```

### Environment Security
- **Development**: Use weak secrets (change in production)
- **Production**: Use strong, unique secrets
- **Database URLs**: Keep secure, never commit to version control

## 🔄 Switching Between Environments

### Local Development Setup
```bash
# 1. Set environment to development
ENVIRONMENT=development

# 2. Use SQLite (default)
DATABASE_URL=sqlite:///./psychology_app.db

# 3. Run migrations
alembic upgrade head
```

### Production (Render) Setup
```bash
# 1. Set environment to production
ENVIRONMENT=production

# 2. Configure PostgreSQL URL
DATABASE_URL_RENDER=postgresql://user:pass@host:5432/db

# 3. Run migrations
alembic upgrade head
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Database Connection Failed
```bash
# Check if PostgreSQL is running
# Verify connection string format
# Check credentials in .env file
```

#### 2. Migration Errors
```bash
# Check if models are imported in alembic/env.py
# Verify database connection
# Check for conflicting table names
```

#### 3. Pydantic Settings Errors
```bash
# Ensure pydantic-settings version compatibility
# Check environment variable names
# Verify .env file format
```

#### 4. SQLite vs PostgreSQL Issues
```bash
# Some SQL features differ between databases
# Test migrations on both databases
# Use SQLAlchemy abstractions when possible
```

## 📚 Next Steps

1. **Set up your Render PostgreSQL database**
2. **Configure environment variables in Render dashboard**
3. **Deploy your application**
4. **Run migrations on production**
5. **Start building your business logic**

## 🔗 Related Files

- [`app/core/config.py`](app/core/config.py) - Environment configuration
- [`app/core/database.py`](app/core/database.py) - Database connection
- [`app/models/user_model.py`](app/models/user_model.py) - User model
- [`alembic/env.py`](alembic/env.py) - Migration configuration
- [`.env.example`](.env.example) - Environment template
- [`requirements.txt`](requirements.txt) - Dependencies

---

**Note**: This setup provides a solid foundation for your PostgreSQL backend. The database will automatically switch between SQLite (development) and PostgreSQL (production) based on your environment configuration.
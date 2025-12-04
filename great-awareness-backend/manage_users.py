#!/usr/bin/env python3
"""
Database management script to clear users and create admin user
"""

import sys
import os
from datetime import datetime

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from app.core.database import SessionLocal, engine, init_db
# Import models in correct order (User first, then models that reference User)
from app.models.user_model import User
from app.models.content_model import Content
from app.models.comment_model import Comment
from app.models.question_model import Question, QuestionComment, QuestionLike, QuestionSave
from app.models.notification_model import Notification
from passlib.context import CryptContext

# Password hashing (match backend auth_routes.py)
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

def get_password_hash(password: str) -> str:
    """Hash password using bcrypt"""
    return pwd_context.hash(password)

def clear_all_users(db: Session):
    """Clear all users from the database"""
    print("Clearing all users from database...")
    try:
        # Delete all users
        deleted_count = db.query(User).delete()
        db.commit()
        print(f"Successfully deleted {deleted_count} users")
        return True
    except Exception as e:
        db.rollback()
        print(f"Error clearing users: {e}")
        return False

def create_admin_user(db: Session):
    """Create the new admin user"""
    print("Creating new admin user...")
    
    # User details
    email = "fw@gmail.com"
    username = "fwadmin"
    first_name = "fweje"
    last_name = "fwiji"
    phone_number = "0711223344"
    county = "nairobi"
    password = "Neptunium238"  # Original password
    role = "admin"
    
    try:
        # Check if user already exists
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            print(f"User with email {email} already exists")
            return False
        
        # Create new user
        new_user = User(
            email=email,
            username=username,
            password_hash=get_password_hash(password),
            first_name=first_name,
            last_name=last_name,
            phone_number=phone_number,
            county=county,
            role=role,
            status="active",
            is_verified=True,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        
        db.add(new_user)
        db.commit()
        print(f"Successfully created admin user:")
        print(f"  Email: {email}")
        print(f"  Username: {username}")
        print(f"  Name: {first_name} {last_name}")
        print(f"  Phone: {phone_number}")
        print(f"  County: {county}")
        print(f"  Role: {role}")
        print(f"  Password: {password}")
        
        return True
        
    except Exception as e:
        db.rollback()
        print(f"Error creating admin user: {e}")
        return False

def list_all_users(db: Session):
    """List all users in the database"""
    print("\nCurrent users in database:")
    users = db.query(User).all()
    if not users:
        print("No users found")
    else:
        for user in users:
            print(f"  - {user.email} ({user.role}) - {user.first_name} {user.last_name}")

def main():
    """Main function"""
    print("Database Management Script")
    print("=" * 40)
    
    # Initialize database (create tables if they don't exist)
    print("Initializing database...")
    init_db()
    
    # Create database session
    db = SessionLocal()
    
    try:
        # Show current users
        list_all_users(db)
        
        # Clear all users
        if clear_all_users(db):
            print("\nUsers cleared successfully")
        else:
            print("\nFailed to clear users")
            return
        
        # Create admin user
        if create_admin_user(db):
            print("\nAdmin user created successfully")
        else:
            print("\nFailed to create admin user")
        
        # Show final state
        list_all_users(db)
        
    except Exception as e:
        print(f"Error during database operations: {e}")
    finally:
        db.close()
        print("\nDatabase operations completed!")

if __name__ == "__main__":
    main()
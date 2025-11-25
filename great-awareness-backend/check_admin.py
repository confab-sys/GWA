#!/usr/bin/env python3
"""Check if admin user exists"""

import sys
import os

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.models.user_model import User
from app.models.content_model import Content  # Import Content model

def check_admin_user():
    """Check if admin user exists"""
    print("Checking admin user...")
    db = SessionLocal()
    try:
        user = db.query(User).filter_by(email='fw@gmail.com').first()
        if user:
            print(f"Admin user exists: {user.email}")
            print(f"Role: {user.role}")
            print(f"Username: {user.username}")
            print(f"Name: {user.first_name} {user.last_name}")
            print(f"Phone: {user.phone_number}")
            print(f"County: {user.county}")
            return True
        else:
            print("Admin user not found")
            return False
    except Exception as e:
        print(f"Error checking admin user: {e}")
        return False
    finally:
        db.close()

if __name__ == "__main__":
    check_admin_user()
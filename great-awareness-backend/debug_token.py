#!/usr/bin/env python3
"""Debug JWT token and user ID"""

import sys
import os
import jwt

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.config import settings
from app.core.database import SessionLocal
from app.models.user_model import User

def debug_token(token):
    """Debug JWT token"""
    print("Debugging JWT token...")
    
    try:
        # Decode JWT token
        payload = jwt.decode(
            token, 
            settings.secret_key, 
            algorithms=[settings.algorithm]
        )
        
        print(f"Token payload: {payload}")
        user_id = payload.get("sub")
        print(f"User ID from token: {user_id}")
        
        # Check if user exists in database
        db = SessionLocal()
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if user:
                print(f"User found: {user.email} (ID: {user.id})")
                print(f"User role: {user.role}")
                print(f"User status: {user.status}")
            else:
                print(f"❌ User NOT found with ID: {user_id}")
                
                # List all users
                all_users = db.query(User).all()
                print(f"Available users:")
                for u in all_users:
                    print(f"  - ID: {u.id}, Email: {u.email}, Role: {u.role}")
                    
        finally:
            db.close()
            
    except Exception as e:
        print(f"Error decoding token: {e}")

if __name__ == "__main__":
    # Get a fresh token
    import requests
    
    login_data = {
        "email": "fw@gmail.com",
        "password": "Neptunium238"
    }
    
    try:
        response = requests.post(
            "http://localhost:8000/api/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            token = data.get("access_token")
            print(f"Got token: {token[:30]}...")
            debug_token(token)
        else:
            print(f"Login failed: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"Error getting token: {e}")
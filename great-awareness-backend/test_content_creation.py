#!/usr/bin/env python3
"""Test content creation with admin user"""

import sys
import os
import requests
import json

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.models.user_model import User
from app.models.content_model import Content

def get_admin_token():
    """Get admin user token for testing"""
    print("Getting admin token...")
    
    # Login to get token
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
            print(f"Got token: {token[:20]}...")
            return token
        else:
            print(f"Login failed: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"Error getting token: {e}")
        return None

def test_content_creation(token):
    """Test creating content with admin token"""
    print("Testing content creation...")
    
    content_data = {
        "title": "Test Post from Admin",
        "body": "This is a test post created by the admin user to verify the content creation functionality works correctly.",
        "topic": "Addictions",
        "post_type": "text",
        "is_text_only": True,
        "status": "published"
    }
    
    try:
        response = requests.post(
            "http://localhost:8000/api/content",
            json=content_data,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
        )
        
        print(f"Response status: {response.status_code}")
        print(f"Response text: {response.text}")
        
        if response.status_code == 201:
            data = response.json()
            print(f"✅ Content created successfully!")
            print(f"Content ID: {data.get('id')}")
            print(f"Title: {data.get('title')}")
            print(f"Status: {data.get('status')}")
            return True
        else:
            print(f"❌ Content creation failed")
            return False
            
    except Exception as e:
        print(f"Error creating content: {e}")
        return False

def check_existing_content():
    """Check if any content exists in database"""
    print("Checking existing content...")
    db = SessionLocal()
    try:
        content_count = db.query(Content).count()
        print(f"Current content count: {content_count}")
        
        if content_count > 0:
            latest_content = db.query(Content).order_by(Content.created_at.desc()).first()
            print(f"Latest content: {latest_content.title} by {latest_content.author_name}")
        
        return content_count
    except Exception as e:
        print(f"Error checking content: {e}")
        return 0
    finally:
        db.close()

if __name__ == "__main__":
    print("=== Testing Content Creation ===")
    
    # Check existing content
    initial_count = check_existing_content()
    
    # Get admin token
    token = get_admin_token()
    if not token:
        print("Failed to get admin token")
        sys.exit(1)
    
    # Test content creation
    success = test_content_creation(token)
    
    # Check content again
    final_count = check_existing_content()
    
    if success:
        print(f"\n✅ SUCCESS: Content creation works!")
        print(f"Content count before: {initial_count}")
        print(f"Content count after: {final_count}")
    else:
        print(f"\n❌ FAILED: Content creation doesn't work")
        sys.exit(1)
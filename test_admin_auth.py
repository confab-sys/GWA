#!/usr/bin/env python3
"""
Script to test admin authentication and endpoints.
This script will test the login process and admin endpoint access.
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'great-awareness-backend'))

import requests
import json
from app.core.config import settings

def test_admin_authentication():
    """Test admin authentication flow and endpoints"""
    
    # Base URL for the API
    base_url = "http://localhost:8000/api"
    
    print("🧪 Testing Admin Authentication and Endpoints")
    print(f"API Base URL: {base_url}")
    
    # Test users from our cleaned database
    test_users = [
        {
            "email": "g@gmail.com",
            "password": "test123",  # You'll need to set the correct password
            "username": "ggreatawareness82854",
            "role": "admin"
        },
        {
            "email": "felixdev56@gmail.com", 
            "password": "test123",  # You'll need to set the correct password
            "username": "felixdev5600841",
            "role": "user"
        }
    ]
    
    for user in test_users:
        print(f"\n🔑 Testing login for {user['username']} ({user['role']})")
        
        try:
            # Test login endpoint
            login_data = {
                "email": user["email"],
                "password": user["password"]
            }
            
            response = requests.post(
                f"{base_url}/auth/login",
                json=login_data,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                login_result = response.json()
                token = login_result.get("access_token")
                print(f"✅ Login successful for {user['username']}")
                print(f"   Token: {token[:20]}..." if token else "No token received")
                
                if token:
                    # Test admin endpoints
                    headers = {"Authorization": f"Bearer {token}"}
                    
                    print(f"\n🔒 Testing admin endpoints for {user['username']}...")
                    
                    # Test /admin/users endpoint
                    print("   Testing /admin/users...")
                    users_response = requests.get(
                        f"{base_url}/admin/users",
                        headers=headers
                    )
                    
                    if users_response.status_code == 200:
                        users_data = users_response.json()
                        print(f"   ✅ /admin/users: Found {len(users_data)} users")
                        for u in users_data:
                            print(f"      - {u['username']} ({u['email']}) - Role: {u['role']}")
                    elif users_response.status_code == 403:
                        print(f"   ❌ /admin/users: Access denied (403) - User is not admin")
                    else:
                        print(f"   ❌ /admin/users: Error {users_response.status_code}")
                        print(f"      Response: {users_response.text}")
                    
                    # Test /admin/analytics endpoint
                    print("   Testing /admin/analytics...")
                    analytics_response = requests.get(
                        f"{base_url}/admin/analytics",
                        headers=headers
                    )
                    
                    if analytics_response.status_code == 200:
                        analytics_data = analytics_response.json()
                        print(f"   ✅ /admin/analytics: Success")
                        print(f"      Total users: {analytics_data.get('total_users')}")
                        print(f"      Active users: {analytics_data.get('active_users')}")
                        print(f"      Total questions: {analytics_data.get('total_questions')}")
                    elif analytics_response.status_code == 403:
                        print(f"   ❌ /admin/analytics: Access denied (403) - User is not admin")
                    else:
                        print(f"   ❌ /admin/analytics: Error {analytics_response.status_code}")
                        print(f"      Response: {analytics_response.text}")
                    
                    # Test /admin/questions/top endpoint
                    print("   Testing /admin/questions/top...")
                    questions_response = requests.get(
                        f"{base_url}/admin/questions/top",
                        headers=headers
                    )
                    
                    if questions_response.status_code == 200:
                        questions_data = questions_response.json()
                        print(f"   ✅ /admin/questions/top: Found {len(questions_data)} top questions")
                    elif questions_response.status_code == 403:
                        print(f"   ❌ /admin/questions/top: Access denied (403) - User is not admin")
                    else:
                        print(f"   ❌ /admin/questions/top: Error {questions_response.status_code}")
                        print(f"      Response: {questions_response.text}")
                    
                else:
                    print(f"   ❌ No token received from login")
                    
            elif response.status_code == 401:
                print(f"   ❌ Login failed: Invalid credentials")
            else:
                print(f"   ❌ Login failed: Status {response.status_code}")
                print(f"      Response: {response.text}")
                
        except requests.exceptions.ConnectionError:
            print(f"   ❌ Cannot connect to API server. Make sure it's running on port 8000")
            print(f"   Try running: python main.py")
            return False
        except Exception as e:
            print(f"   ❌ Error testing {user['username']}: {e}")
            continue
    
    print("\n🎯 Testing Summary:")
    print("- Admin user (ggreatawareness82854) should be able to access all admin endpoints")
    print("- Regular user (felixdev5600841) should get 403 Forbidden on admin endpoints")
    print("- If login fails, check the password for each user")
    
    return True

if __name__ == "__main__":
    success = test_admin_authentication()
    sys.exit(0 if success else 1)
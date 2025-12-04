#!/usr/bin/env python3
"""
Script to help test admin authentication with correct passwords.
This script will guide you through testing the authentication flow.
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'great-awareness-backend'))

import requests
import json
from app.core.config import settings

def test_admin_auth_with_passwords():
    """Test admin authentication - will ask for passwords interactively"""
    
    # Base URL for the API
    base_url = "http://localhost:8000/api"
    
    print("🧪 Testing Admin Authentication and Endpoints")
    print(f"API Base URL: {base_url}")
    print("\n📝 Current users in your Neon database:")
    print("   1. ggreatawareness82854 (g@gmail.com) - ADMIN")
    print("   2. felixdev5600841 (felixdev56@gmail.com) - USER") 
    print("   3. walterkungu5441154 (walterkungu54@gmail.com) - USER")
    print("\n⚠️  Note: You'll need to know the correct passwords for these users")
    
    # Test with admin user first
    print("\n" + "="*50)
    print("🔑 Testing ADMIN User Authentication")
    print("="*50)
    
    admin_email = "g@gmail.com"
    admin_password = input(f"Enter password for admin user ({admin_email}): ")
    
    try:
        # Test admin login
        login_data = {
            "email": admin_email,
            "password": admin_password
        }
        
        response = requests.post(
            f"{base_url}/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            login_result = response.json()
            token = login_result.get("access_token")
            print(f"✅ Admin login successful!")
            print(f"   Token type: {login_result.get('token_type')}")
            print(f"   Expires in: {login_result.get('expires_in')} seconds")
            
            if token:
                # Test admin endpoints
                headers = {"Authorization": f"Bearer {token}"}
                
                print(f"\n🔒 Testing Admin Endpoints...")
                
                # Test /admin/users endpoint
                print("\n1. Testing /admin/users endpoint:")
                users_response = requests.get(
                    f"{base_url}/admin/users",
                    headers=headers
                )
                
                if users_response.status_code == 200:
                    users_data = users_response.json()
                    print(f"   ✅ SUCCESS: Found {len(users_data)} users")
                    for user in users_data:
                        print(f"      - {user['username']} ({user['email']}) - Role: {user['role']}")
                else:
                    print(f"   ❌ FAILED: Status {users_response.status_code}")
                    print(f"      Response: {users_response.text}")
                
                # Test /admin/analytics endpoint
                print("\n2. Testing /admin/analytics endpoint:")
                analytics_response = requests.get(
                    f"{base_url}/admin/analytics",
                    headers=headers
                )
                
                if analytics_response.status_code == 200:
                    analytics_data = analytics_response.json()
                    print(f"   ✅ SUCCESS: Analytics retrieved")
                    print(f"      Total users: {analytics_data.get('total_users')}")
                    print(f"      Active users: {analytics_data.get('active_users')}")
                    print(f"      Total questions: {analytics_data.get('total_questions')}")
                    print(f"      Recent questions: {analytics_data.get('recent_questions')}")
                else:
                    print(f"   ❌ FAILED: Status {analytics_response.status_code}")
                    print(f"      Response: {analytics_response.text}")
                
                # Test /admin/questions/top endpoint
                print("\n3. Testing /admin/questions/top endpoint:")
                questions_response = requests.get(
                    f"{base_url}/admin/questions/top",
                    headers=headers
                )
                
                if questions_response.status_code == 200:
                    questions_data = questions_response.json()
                    print(f"   ✅ SUCCESS: Found {len(questions_data)} top questions")
                    for i, q in enumerate(questions_data, 1):
                        print(f"      {i}. {q['question']} (Category: {q['category']}, Count: {q['count']})")
                else:
                    print(f"   ❌ FAILED: Status {questions_response.status_code}")
                    print(f"      Response: {questions_response.text}")
                    
        else:
            print(f"❌ Admin login failed: Status {response.status_code}")
            print(f"   Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print(f"❌ Cannot connect to API server. Make sure it's running on port 8000")
        print(f"   Try running: python main.py")
        return False
    except Exception as e:
        print(f"❌ Error testing admin authentication: {e}")
    
    # Test with regular user to show access denied
    print("\n" + "="*50)
    print("🔑 Testing REGULAR User Authentication (Should be DENIED)")
    print("="*50)
    
    user_email = "felixdev56@gmail.com"
    user_password = input(f"Enter password for regular user ({user_email}): ")
    
    try:
        # Test regular user login
        login_data = {
            "email": user_email,
            "password": user_password
        }
        
        response = requests.post(
            f"{base_url}/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            login_result = response.json()
            token = login_result.get("access_token")
            print(f"✅ Regular user login successful!")
            
            if token:
                headers = {"Authorization": f"Bearer {token}"}
                
                # Test admin endpoint (should fail)
                print(f"\n🔒 Testing Admin Endpoint Access (Should be DENIED)...")
                users_response = requests.get(
                    f"{base_url}/admin/users",
                    headers=headers
                )
                
                if users_response.status_code == 403:
                    print(f"   ✅ CORRECT: Access denied (403) - User is not admin")
                    print(f"   Message: {users_response.json().get('detail')}")
                else:
                    print(f"   ❌ UNEXPECTED: Status {users_response.status_code}")
                    print(f"      Response: {users_response.text}")
                    
        else:
            print(f"❌ Regular user login failed: Status {response.status_code}")
            print(f"   Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error testing regular user: {e}")
    
    print("\n" + "="*50)
    print("🎯 Summary:")
    print("- Admin user should be able to access all admin endpoints")
    print("- Regular users should get 403 Forbidden on admin endpoints")
    print("- If login fails, the passwords may be different than expected")
    print("="*50)
    
    return True

if __name__ == "__main__":
    success = test_admin_auth_with_passwords()
    sys.exit(0 if success else 1)
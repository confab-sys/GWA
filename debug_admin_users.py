#!/usr/bin/env python3
"""
Quick test script to debug the /admin/users endpoint 500 error.
Gets a fresh token and tests the endpoint.
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'great-awareness-backend'))

import requests
import json

def test_admin_users_endpoint():
    """Test the /admin/users endpoint to see the exact error"""
    
    base_url = "http://localhost:8000/api"
    
    print("🧪 Testing /admin/users endpoint with fresh token...")
    
    # First, get a fresh token with the password we know works
    login_data = {
        "email": "g@gmail.com",
        "password": "Neptunium238"
    }
    
    try:
        # Login to get fresh token
        print("🔑 Getting fresh token...")
        login_response = requests.post(
            f"{base_url}/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        
        if login_response.status_code == 200:
            login_result = login_response.json()
            token = login_result.get("access_token")
            print(f"✅ Got fresh token: {token[:30]}...")
            
            # Now test the admin/users endpoint
            print("\n🔒 Testing /admin/users endpoint...")
            headers = {"Authorization": f"Bearer {token}"}
            
            users_response = requests.get(
                f"{base_url}/admin/users",
                headers=headers
            )
            
            print(f"Status Code: {users_response.status_code}")
            print(f"Response Headers: {dict(users_response.headers)}")
            
            if users_response.status_code == 200:
                users_data = users_response.json()
                print(f"✅ SUCCESS: Found {len(users_data)} users")
                for user in users_data:
                    print(f"   - {user['username']} ({user['email']}) - Role: {user['role']}")
            elif users_response.status_code == 500:
                print(f"❌ 500 ERROR: {users_response.text}")
                # Try to parse the error
                try:
                    error_data = users_response.json()
                    print(f"Error detail: {error_data.get('detail', 'No detail')}")
                except:
                    print(f"Raw error response: {users_response.text}")
            else:
                print(f"Response: {users_response.text}")
                
        else:
            print(f"❌ Login failed: {login_response.status_code}")
            print(f"Response: {login_response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to API server. Make sure it's running on port 8000")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = test_admin_users_endpoint()
    sys.exit(0 if success else 1)
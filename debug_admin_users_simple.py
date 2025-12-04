#!/usr/bin/env python3
"""
Detailed debug script for admin users endpoint - simplified version
"""

import requests
import json

def test_admin_users_detailed():
    """Test admin users endpoint with detailed debugging"""
    
    base_url = "http://localhost:8000/api"
    
    try:
        # Test the authentication
        print("🔑 Testing authentication...")
        login_data = {
            "email": "g@gmail.com",
            "password": "Neptunium238"
        }
        
        login_response = requests.post(
            f"{base_url}/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        
        if login_response.status_code != 200:
            print(f"❌ Login failed: {login_response.status_code}")
            print(f"Response: {login_response.text}")
            return False
            
        login_result = login_response.json()
        token = login_result.get("access_token")
        print(f"✅ Login successful, token: {token[:20]}...")
        
        # Test the admin/users endpoint with detailed error handling
        print("\n🔒 Testing /admin/users endpoint...")
        headers = {"Authorization": f"Bearer {token}"}
        
        # Add timeout and detailed error handling
        try:
            users_response = requests.get(
                f"{base_url}/admin/users",
                headers=headers,
                timeout=30
            )
            
            print(f"📡 Response status: {users_response.status_code}")
            print(f"📡 Response headers: {dict(users_response.headers)}")
            
            if users_response.status_code == 500:
                print(f"❌ 500 Error details:")
                print(f"Raw response: {users_response.text}")
                
                # Try to get more info by checking if it's a JSON error
                try:
                    error_json = users_response.json()
                    print(f"Error JSON: {json.dumps(error_json, indent=2)}")
                except:
                    print("Response is not JSON format")
                    
            elif users_response.status_code == 200:
                users_data = users_response.json()
                print(f"✅ Success! Found {len(users_data)} users")
                # Print first user as example
                if users_data:
                    print(f"First user: {users_data[0]}")
            else:
                print(f"❌ Unexpected status code: {users_response.status_code}")
                print(f"Response: {users_response.text}")
                
        except requests.exceptions.Timeout:
            print("❌ Request timed out after 30 seconds")
        except requests.exceptions.RequestException as e:
            print(f"❌ Request failed: {e}")
            
        return True
        
    except Exception as e:
        print(f"❌ Error in detailed debug: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    test_admin_users_detailed()
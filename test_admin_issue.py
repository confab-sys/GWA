#!/usr/bin/env python3
"""
Test to identify the exact issue with admin/users endpoint
"""

import requests
import json

def test_admin_users_issue():
    """Test to identify the specific issue"""
    
    base_url = "http://localhost:8000/api"
    
    try:
        # Login to get token
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
            return False
            
        login_result = login_response.json()
        token = login_result.get("access_token")
        print(f"✅ Login successful")
        
        # Test different scenarios
        headers = {"Authorization": f"Bearer {token}"}
        
        # Test 1: Basic users endpoint
        print("\n📋 Test 1: Basic /admin/users")
        users_response = requests.get(f"{base_url}/admin/users", headers=headers)
        print(f"Status: {users_response.status_code}")
        
        if users_response.status_code == 500:
            print("🎯 Confirmed: 500 error on /admin/users")
            
            # Test 2: Try without response model to isolate the issue
            print("\n📋 Test 2: Testing if it's a serialization issue")
            
            # Let's try to get a single user first
            test_response = requests.get(f"{base_url}/admin/users?limit=1", headers=headers)
            print(f"Single user test - Status: {test_response.status_code}")
            
            # Test 3: Try analytics endpoint to see if it's a general issue
            print("\n📋 Test 3: Testing /admin/analytics")
            analytics_response = requests.get(f"{base_url}/admin/analytics", headers=headers)
            print(f"Analytics - Status: {analytics_response.status_code}")
            
            if analytics_response.status_code == 200:
                print("✅ Analytics works, so issue is specific to users endpoint")
                
                # Test 4: Test questions endpoint
                print("\n📋 Test 4: Testing /admin/questions/top")
                questions_response = requests.get(f"{base_url}/admin/questions/top", headers=headers)
                print(f"Questions - Status: {questions_response.status_code}")
                
            else:
                print("❌ Analytics also fails, issue might be more general")
                
        elif users_response.status_code == 200:
            print("✅ Users endpoint works!")
            users_data = users_response.json()
            print(f"Found {len(users_data)} users")
            if users_data:
                print(f"Sample user: {users_data[0]}")
        else:
            print(f"❌ Unexpected status: {users_response.status_code}")
            
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    test_admin_users_issue()
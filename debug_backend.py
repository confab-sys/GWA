#!/usr/bin/env python3
"""
Debug script to test backend endpoints and identify the root cause of login failures.
"""

import requests
import json

def test_backend_endpoints():
    base_url = "https://gwa-enus.onrender.com"
    
    print("🧪 Testing Backend Endpoints")
    print("=" * 50)
    
    # Test 1: Health Check
    print("\n1. Testing Health Check...")
    try:
        response = requests.get(f"{base_url}/health", timeout=10)
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.text}")
    except Exception as e:
        print(f"   ❌ Health check failed: {e}")
    
    # Test 2: Login with invalid credentials (should return 401, not 500)
    print("\n2. Testing Login Endpoint (invalid credentials)...")
    try:
        login_data = {"email": "test@example.com", "password": "wrongpassword"}
        headers = {"Content-Type": "application/json"}
        response = requests.post(
            f"{base_url}/api/auth/login", 
            data=json.dumps(login_data), 
            headers=headers,
            timeout=10
        )
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.text}")
        
        if response.status_code == 500:
            print("   ❌ INTERNAL SERVER ERROR - This confirms the backend issue!")
        elif response.status_code == 401:
            print("   ✅ Login endpoint is working (401 is expected for wrong credentials)")
            
    except Exception as e:
        print(f"   ❌ Login test failed: {e}")
    
    # Test 3: Try to access /api/auth/me (should return 401 without token)
    print("\n3. Testing User Info Endpoint...")
    try:
        response = requests.get(f"{base_url}/api/auth/me", timeout=10)
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.text}")
    except Exception as e:
        print(f"   ❌ User info test failed: {e}")
    
    print("\n" + "=" * 50)
    print("🔍 Analysis Complete!")
    print("\nNext Steps:")
    print("1. Redeploy your backend to apply CORS fixes")
    print("2. Check Render logs for database errors")
    print("3. Verify database migrations are complete")
    print("4. Check environment variables on Render")

if __name__ == "__main__":
    test_backend_endpoints()
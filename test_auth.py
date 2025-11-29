#!/usr/bin/env python3
"""
Test script to verify authentication endpoints with Render database
"""

import requests
import json
import random
import string
import time

# Configuration
BASE_URL = "https://gwa-enus.onrender.com"
REGISTER_ENDPOINT = f"{BASE_URL}/api/auth/register"
LOGIN_ENDPOINT = f"{BASE_URL}/api/auth/login"
HEALTH_ENDPOINT = f"{BASE_URL}/health"

# Test data
def generate_test_user():
    """Generate unique test user data"""
    timestamp = str(int(time.time()))
    random_suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=4))
    
    return {
        "username": f"testuser_{timestamp}_{random_suffix}",
        "email": f"testuser_{timestamp}_{random_suffix}@example.com",
        "password": "Test1234",  # Meets password requirements
        "first_name": "Test",
        "last_name": "User",
        "phone_number": "1234567890",
        "county": "Nairobi City County"
    }

def test_health_check():
    """Test if the backend is healthy"""
    print("🩺 Testing health endpoint...")
    try:
        response = requests.get(HEALTH_ENDPOINT)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Health check passed: {data}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_registration(user_data):
    """Test user registration"""
    print(f"\n📝 Testing registration for {user_data['email']}...")
    
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post(REGISTER_ENDPOINT, headers=headers, data=json.dumps(user_data))
        
        print(f"Registration status code: {response.status_code}")
        print(f"Registration response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Registration successful! User ID: {data.get('id')}")
            return True, data
        elif response.status_code == 400:
            data = response.json()
            print(f"❌ Registration failed: {data.get('detail', 'Unknown error')}")
            return False, None
        else:
            print(f"❌ Registration failed with status {response.status_code}")
            return False, None
            
    except Exception as e:
        print(f"❌ Registration error: {e}")
        return False, None

def test_login(email, password):
    """Test user login"""
    print(f"\n🔐 Testing login for {email}...")
    
    login_data = {
        "email": email,
        "password": password
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post(LOGIN_ENDPOINT, headers=headers, data=json.dumps(login_data))
        
        print(f"Login status code: {response.status_code}")
        print(f"Login response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            token = data.get('access_token')
            print(f"✅ Login successful! Token: {token[:50]}...")
            return True, data
        elif response.status_code == 401:
            print("❌ Login failed: Invalid credentials")
            return False, None
        else:
            print(f"❌ Login failed with status {response.status_code}")
            return False, None
            
    except Exception as e:
        print(f"❌ Login error: {e}")
        return False, None

def main():
    """Main test function"""
    print("🚀 Starting authentication tests for Render backend")
    print(f"Backend URL: {BASE_URL}")
    print("=" * 50)
    
    # Test 1: Health check
    if not test_health_check():
        print("❌ Backend is not healthy, aborting tests")
        return
    
    # Test 2: Generate test user
    test_user = generate_test_user()
    print(f"\n👤 Generated test user:")
    print(f"   Username: {test_user['username']}")
    print(f"   Email: {test_user['email']}")
    print(f"   Password: {test_user['password']}")
    
    # Test 3: Registration
    reg_success, reg_data = test_registration(test_user)
    
    if reg_success:
        # Test 4: Login with newly created user
        login_success, login_data = test_login(test_user['email'], test_user['password'])
        
        if login_success:
            print("\n🎉 ALL TESTS PASSED! Authentication system is working correctly.")
            print("✅ Backend is healthy")
            print("✅ Registration works")
            print("✅ Login works")
            print("✅ Database is connected and storing users")
        else:
            print("\n❌ Login test failed - user created but cannot login")
    else:
        print("\n❌ Registration test failed")
    
    # Test 5: Try login with known working user (from previous tests)
    print(f"\n🔍 Testing with previously created user...")
    known_email = "testuser6@example.com"
    known_password = "Test1234"
    login_success_known, _ = test_login(known_email, known_password)
    
    if login_success_known:
        print("✅ Known user can still login - database persistence working")
    else:
        print("❌ Known user cannot login - possible database issue")
    
    print("\n" + "=" * 50)
    print("🏁 Test completed")

if __name__ == "__main__":
    main()
import requests
import json

# Base URL for the local server
BASE_URL = "http://localhost:8000"

def test_auth_endpoints():
    """Test all authentication endpoints"""
    
    print("🧪 Testing Authentication Endpoints...")
    print("=" * 50)
    
    # Test data
    test_user = {
        "email": "test@example.com",
        "username": "testuser",
        "password": "testpassword123",
        "first_name": "Test",
        "last_name": "User",
        "phone_number": "+1234567890",
        "county": "Test County"
    }
    
    login_data = {
        "email": "test@example.com",
        "password": "testpassword123"
    }
    
    try:
        # Test 1: User Registration
        print("\n1️⃣ Testing User Registration...")
        register_response = requests.post(f"{BASE_URL}/auth/register", json=test_user)
        print(f"Status Code: {register_response.status_code}")
        
        if register_response.status_code == 200:
            print("✅ Registration successful!")
            registered_user = register_response.json()
            print(f"User ID: {registered_user.get('id')}")
            print(f"Email: {registered_user.get('email')}")
        else:
            print(f"❌ Registration failed: {register_response.text}")
            return False
        
        # Test 2: User Login
        print("\n2️⃣ Testing User Login...")
        login_response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        print(f"Status Code: {login_response.status_code}")
        
        if login_response.status_code == 200:
            print("✅ Login successful!")
            login_result = login_response.json()
            access_token = login_result.get('access_token')
            print(f"Access Token: {access_token[:20]}...")
            print(f"Token Type: {login_result.get('token_type')}")
            print(f"Expires In: {login_result.get('expires_in')} seconds")
        else:
            print(f"❌ Login failed: {login_response.text}")
            return False
        
        # Test 3: Token Verification
        print("\n3️⃣ Testing Token Verification...")
        verify_response = requests.get(f"{BASE_URL}/auth/verify?token={access_token}")
        print(f"Status Code: {verify_response.status_code}")
        
        if verify_response.status_code == 200:
            print("✅ Token verification successful!")
            verify_result = verify_response.json()
            print(f"Email from token: {verify_result.get('email')}")
        else:
            print(f"❌ Token verification failed: {verify_response.text}")
            return False
        
        # Test 4: Get Current User Info
        print("\n4️⃣ Testing Get Current User...")
        headers = {"Authorization": f"Bearer {access_token}"}
        me_response = requests.get(f"{BASE_URL}/auth/me", headers=headers)
        print(f"Status Code: {me_response.status_code}")
        
        if me_response.status_code == 200:
            print("✅ Get current user successful!")
            current_user = me_response.json()
            print(f"User Email: {current_user.get('email')}")
            print(f"Username: {current_user.get('username')}")
            print(f"Full Name: {current_user.get('first_name')} {current_user.get('last_name')}")
        else:
            print(f"❌ Get current user failed: {me_response.text}")
            return False
        
        print("\n" + "=" * 50)
        print("🎉 All authentication tests passed!")
        return True
        
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to the server. Make sure it's running on http://localhost:8000")
        return False
    except Exception as e:
        print(f"❌ Test failed with error: {str(e)}")
        return False

if __name__ == "__main__":
    test_auth_endpoints()
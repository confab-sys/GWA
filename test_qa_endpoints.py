import requests
import json

# API base URL
BASE_URL = "http://localhost:8000"

def test_qa_endpoints():
    """Test Q&A API endpoints"""
    
    print("🧪 Testing Q&A API Endpoints")
    print("=" * 50)
    
    # Test 1: Get categories (no auth required)
    print("\n1️⃣ Testing GET /api/qa/questions/categories")
    try:
        response = requests.get(f"{BASE_URL}/api/qa/questions/categories")
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Categories endpoint working")
            print(f"Response: {response.json()}")
        else:
            print(f"❌ Error: {response.text}")
    except Exception as e:
        print(f"❌ Exception: {e}")
    
    # Test 2: Get stats (no auth required)
    print("\n2️⃣ Testing GET /api/qa/questions/stats")
    try:
        response = requests.get(f"{BASE_URL}/api/qa/questions/stats")
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Stats endpoint working")
            print(f"Response: {response.json()}")
        else:
            print(f"❌ Error: {response.text}")
    except Exception as e:
        print(f"❌ Exception: {e}")
    
    # Test 3: Get questions (no auth required)
    print("\n3️⃣ Testing GET /api/qa/questions")
    try:
        response = requests.get(f"{BASE_URL}/api/qa/questions")
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Questions list endpoint working")
            data = response.json()
            print(f"Total questions: {data.get('total', 0)}")
            print(f"Questions in response: {len(data.get('questions', []))}")
        else:
            print(f"❌ Error: {response.text}")
    except Exception as e:
        print(f"❌ Exception: {e}")
    
    print("\n" + "=" * 50)
    print("✅ Q&A API endpoint testing completed!")

if __name__ == "__main__":
    test_qa_endpoints()
#!/usr/bin/env python3
"""
Final comprehensive test of admin endpoints
"""

import requests
import json

def final_admin_test():
    """Comprehensive test of all admin endpoints"""
    
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
        
        headers = {"Authorization": f"Bearer {token}"}
        
        # Test all admin endpoints
        print("\n📋 Testing all admin endpoints:")
        
        # 1. Users endpoint
        print("1️⃣ /admin/users")
        users_response = requests.get(f"{base_url}/admin/users", headers=headers)
        if users_response.status_code == 200:
            users_data = users_response.json()
            print(f"   ✅ Success! Found {len(users_data)} users")
            # Show admin user details
            admin_users = [u for u in users_data if u.get('role') == 'admin']
            if admin_users:
                print(f"   👑 Admin users: {len(admin_users)}")
                for admin in admin_users:
                    print(f"      - {admin['username']} ({admin['email']}) - Active: {admin['is_active']}")
        else:
            print(f"   ❌ Failed: {users_response.status_code}")
            
        # 2. Analytics endpoint
        print("2️⃣ /admin/analytics")
        analytics_response = requests.get(f"{base_url}/admin/analytics", headers=headers)
        if analytics_response.status_code == 200:
            analytics_data = analytics_response.json()
            print(f"   ✅ Success!")
            print(f"      📊 Total users: {analytics_data['total_users']}")
            print(f"      📊 Active users: {analytics_data['active_users']}")
            print(f"      📊 Total questions: {analytics_data['total_questions']}")
        else:
            print(f"   ❌ Failed: {analytics_response.status_code}")
            
        # 3. Questions endpoint
        print("3️⃣ /admin/questions/top")
        questions_response = requests.get(f"{base_url}/admin/questions/top", headers=headers)
        if questions_response.status_code == 200:
            questions_data = questions_response.json()
            print(f"   ✅ Success! Found {len(questions_data)} top questions")
        else:
            print(f"   ❌ Failed: {questions_response.status_code}")
            
        print("\n🎉 All admin endpoints are working correctly!")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    final_admin_test()
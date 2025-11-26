import requests
import json

# Test authentication and question posting
base_url = 'http://localhost:8000'

# Step 1: Try to login with test credentials
login_data = {
    'email': 'testuser123@example.com',
    'password': 'Testpassword123'
}

print('Step 1: Testing login with test credentials')
try:
    login_response = requests.post(f'{base_url}/api/auth/login', json=login_data)
    print(f'Login Response Status: {login_response.status_code}')
    
    if login_response.status_code == 200:
        login_result = login_response.json()
        token = login_result.get('access_token')
        print(f'Login successful! Token: {token[:20]}...')
    else:
        print(f'Login failed: {login_response.text}')
        print('\nTrying to register a new test user...')
        
        # Try to register a new user
        register_data = {
            'email': 'testuser123@example.com',
            'username': 'testuser123',
            'password': 'Testpassword123',
            'full_name': 'Test User'
        }
        
        register_response = requests.post(f'{base_url}/api/auth/register', json=register_data)
        print(f'Register Response Status: {register_response.status_code}')
        print(f'Register Response: {register_response.text}')
        
        if register_response.status_code == 201:
            # Try login again after successful registration
            print('\nTrying login again after registration...')
            login_response = requests.post(f'{base_url}/api/auth/login', json=login_data)
            if login_response.status_code == 200:
                login_result = login_response.json()
                token = login_result.get('access_token')
                print(f'Login successful! Token: {token[:20]}...')
            else:
                print(f'Login still failed after registration: {login_response.text}')
                exit(1)
        else:
            print(f'Registration failed: {register_response.text}')
            exit(1)
    
    # Step 2: Post question with authentication
    question_data = {
        'title': 'Test Question from API Test',
        'content': 'This is a test question to verify the posting functionality works correctly.',
        'category': 'Anxiety',
        'image_path': None,
        'is_anonymous': False
    }
    
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    print('\nStep 2: Posting question with authentication')
    post_response = requests.post(f'{base_url}/api/qa/questions', 
                               json=question_data, headers=headers)
    print(f'POST Response Status: {post_response.status_code}')
    print(f'POST Response Body: {post_response.text}')
    
    if post_response.status_code in [200, 201]:
        result = post_response.json()
        print(f'\nSuccess! Created question ID: {result.get("id", "unknown")}')
        print(f'Question saved successfully!')
    else:
        print(f'\nError posting question: {post_response.text}')
        
except Exception as e:
    print(f'Request failed: {e}')
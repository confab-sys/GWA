import requests
import json

# Test getting questions from the API
base_url = 'http://localhost:8000'

# Use the token from the previous test
login_data = {
    'email': 'testuser123@example.com',
    'password': 'Testpassword123'
}

print('Step 1: Getting authentication token')
try:
    login_response = requests.post(f'{base_url}/api/auth/login', json=login_data)
    if login_response.status_code == 200:
        login_result = login_response.json()
        token = login_result.get('access_token')
        print(f'Login successful! Token: {token[:20]}...')
    else:
        print(f'Login failed: {login_response.text}')
        exit(1)
except Exception as e:
    print(f'Login error: {e}')
    exit(1)

print('\nStep 2: Getting questions from API')
try:
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    # Test getting questions
    questions_response = requests.get(f'{base_url}/api/qa/questions', headers=headers)
    print(f'Questions Response Status: {questions_response.status_code}')
    
    if questions_response.status_code == 200:
        questions_data = questions_response.json()
        print(f'Questions Response Structure: {json.dumps(questions_data, indent=2)}')
        
        # Check if there are items
        items = questions_data.get('items', [])
        print(f'\nNumber of questions returned: {len(items)}')
        
        if items:
            print(f'First question structure: {json.dumps(items[0], indent=2)}')
    else:
        print(f'Failed to get questions: {questions_response.text}')
        
except Exception as e:
    print(f'Error getting questions: {e}')
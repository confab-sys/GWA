import requests
import json

# Test POST question endpoint
url = 'http://localhost:8000/api/qa/questions'
data = {
    'title': 'Test Question from API Test',
    'content': 'This is a test question to verify the posting functionality works correctly.',
    'category': 'Anxiety',
    'image_path': None,
    'is_anonymous': False
}

print('Testing POST /api/qa/questions with data:')
print(json.dumps(data, indent=2))

try:
    response = requests.post(url, json=data)
    print(f'\nPOST Response Status: {response.status_code}')
    print(f'POST Response Headers: {dict(response.headers)}')
    print(f'POST Response Body: {response.text}')
    
    if response.status_code in [200, 201]:
        result = response.json()
        print(f'\nSuccess! Created question ID: {result.get("id", "unknown")}')
    else:
        print(f'\nError response: {response.text}')
        
except Exception as e:
    print(f'\nRequest failed: {e}')
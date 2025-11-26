import requests
import json

# Test the comment endpoint with detailed error handling
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJuZXd0ZXN0dXNlckBleGFtcGxlLmNvbSIsImV4cCI6MTc2NDE0NzcwM30.-2dogCxCYc72E023uJ_au3cOcRtR2zL7HFjW50-gVZ0"

try:
    response = requests.post(
        'http://127.0.0.1:8000/api/content/9/comments',
        headers={'Authorization': f'Bearer {token}'},
        json={'text': 'This is a test comment from the API!', 'content_id': 9}
    )
    print(f'Status Code: {response.status_code}')
    print(f'Response: {response.text}')
    print(f'Headers: {response.headers}')
except Exception as e:
    print(f'Error: {e}')
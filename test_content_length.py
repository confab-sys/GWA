import requests
import json

# Test to check if any questions have very long content that might need truncation
base_url = 'http://localhost:8000'

print('=== Checking Question Content Lengths ===')

# Step 1: Login to get token
login_data = {
    'email': 'testuser123@example.com',
    'password': 'Testpassword123'
}

try:
    login_response = requests.post(f'{base_url}/api/auth/login', json=login_data)
    if login_response.status_code == 200:
        login_result = login_response.json()
        token = login_result.get('access_token')
        print(f'✓ Login successful!')
    else:
        print(f'✗ Login failed: {login_response.text}')
        exit(1)
except Exception as e:
    print(f'✗ Login error: {e}')
    exit(1)

# Step 2: Get all questions and analyze content lengths
print('\nStep 2: Analyzing question content lengths')
try:
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    questions_response = requests.get(f'{base_url}/api/qa/questions', headers=headers)
    if questions_response.status_code == 200:
        questions_data = questions_response.json()
        questions = questions_data.get('questions', [])
        
        print(f'📊 Found {len(questions)} questions to analyze')
        
        for i, question in enumerate(questions):
            title = question.get('title', 'No title')
            content = question.get('content', 'No content')
            
            # Check if content is very long (might need truncation in UI)
            if len(content) > 200:
                print(f'\n⚠️  Question {i+1} has very long content:')
                print(f'   Title: {title[:50]}...')
                print(f'   Content length: {len(content)} characters')
                print(f'   Preview: {content[:100]}...')
            elif len(content) > 100:
                print(f'\nℹ️  Question {i+1} has moderate content length:')
                print(f'   Title: {title}')
                print(f'   Content length: {len(content)} characters')
            else:
                print(f'\n✅ Question {i+1} has short content:')
                print(f'   Title: {title}')
                print(f'   Content: {content}')
                
    else:
        print(f'✗ Failed to get questions: {questions_response.text}')
        
except Exception as e:
    print(f'✗ Error getting questions: {e}')

print('\n=== Recommendations for Flutter UI ===')
print('✅ Questions with short content (< 100 chars) will display perfectly')
print('✅ Questions with moderate content (100-200 chars) will display well')
print('⚠️  Questions with very long content (> 200 chars) might need:')
print('   - Text truncation with "..."')
print('   - "Read more" expandable option')
print('   - Smaller font size for content')
print('   - Limited max lines (e.g., maxLines: 3)')
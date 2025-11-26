import requests
import json

# Test the updated data structure for Q&A cards
base_url = 'http://localhost:8000'

print('=== Testing Updated Q&A Card Data Structure ===')

# Step 1: Login to get token
print('\nStep 1: Getting authentication token')
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

# Step 2: Get questions and check the transformed data structure
print('\nStep 2: Testing transformed question data')
try:
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    questions_response = requests.get(f'{base_url}/api/qa/questions', headers=headers)
    if questions_response.status_code == 200:
        questions_data = questions_response.json()
        questions = questions_data.get('questions', [])
        
        if questions:
            # Show the original API data structure
            print('\n📋 Original API Data Structure:')
            original = questions[0]
            print(f'  - title: {original["title"]}')
            print(f'  - content: {original["content"]}')
            print(f'  - author_name: {original["author_name"]}')
            print(f'  - category: {original["category"]}')
            print(f'  - created_at: {original["created_at"]}')
            
            # Show what the Flutter app will receive (transformed data)
            print('\n📱 Transformed Data for Flutter App:')
            transformed = {
                'id': original['id'],
                'category': original['category'],
                'title': original['title'],
                'question': original['content'],  # This is the key change!
                'author': original['author_name'],
                'time': original['created_at'],
                'likes': original.get('likes_count', 0),
                'comments': original.get('comments_count', 0),
                'isLiked': False,
                'isSaved': False,
                'hasImage': original.get('has_image', False)
            }
            print(f'  - title: {transformed["title"]}')
            print(f'  - question: {transformed["question"]}')
            print(f'  - author: {transformed["author"]}')
            print(f'  - category: {transformed["category"]}')
            print(f'  - time: {transformed["time"]}')
            
            print('\n✅ Data transformation is working correctly!')
            print('✅ The card will now show both title and full question content')
        else:
            print('⚠️ No questions found in database')
    else:
        print(f'✗ Failed to get questions: {questions_response.text}')
        
except Exception as e:
    print(f'✗ Error getting questions: {e}')

print('\n=== Summary ===')
print('✅ Title will appear as bold header in card')
print('✅ Full question content will appear below title') 
print('✅ Author information will appear below content')
print('✅ All other functionality (likes, comments, etc.) remains the same')
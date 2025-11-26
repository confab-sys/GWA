from app.db.database import SessionLocal
from app.models.content import Content

db = SessionLocal()
content = db.query(Content).filter(Content.id == 9).first()
print(f'Content ID 9 exists: {content is not None}')
if content:
    print(f'Content title: {content.title}')
    print(f'Content ID: {content.id}')
else:
    print('Content not found')
db.close()
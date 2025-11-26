from app.db.database import SessionLocal
from app.models.content import Content

db = SessionLocal()
contents = db.query(Content).all()
print(f'Total content items: {len(contents)}')
for content in contents:
    print(f'ID: {content.id}, Title: {content.title}')
db.close()
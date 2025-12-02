from app.core.database import SessionLocal, engine
from sqlalchemy import inspect

# Create an inspector to check the database schema
inspector = inspect(engine)

# Get all table names
tables = inspector.get_table_names()
print("Tables in the database:")
for table in tables:
    print(f"- {table}")
    
    # Get columns for each table
    columns = inspector.get_columns(table)
    print(f"  Columns:")
    for column in columns:
        print(f"    - {column['name']}: {column['type']}")
    print()

# Check specifically for notifications table
if 'notifications' in tables:
    print("✅ Notifications table exists!")
else:
    print("❌ Notifications table does not exist!")

# Check migration status
from alembic.config import Config
from alembic.runtime.migration import MigrationContext
from sqlalchemy import create_engine

# Get current migration version
with engine.connect() as connection:
    context = MigrationContext.configure(connection)
    current_rev = context.get_current_revision()
    print(f"Current migration revision: {current_rev}")
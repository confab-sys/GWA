#!/usr/bin/env python3
"""
Script to specifically test Neon database connection and check for admin users.
This script ensures we're connecting to the actual Neon database, not SQLite.
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'great-awareness-backend'))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
from app.models.user_model import User
from app.models.content_model import Content
from app.models.comment_model import Comment
from app.models.notification_model import Notification
from app.models.question_model import Question

def test_neon_database():
    """Test Neon database connection and check for admin users"""
    try:
        print("🔍 Testing Neon Database Connection...")
        print(f"Environment: {settings.environment}")
        print(f"Using database_url: {settings.database_url}")
        print(f"Using database_uri: {settings.database_uri}")
        
        # Create database connection using the database_uri property
        # This should use the Neon database URL
        engine = create_engine(settings.database_uri)
        
        # Test basic connection
        print("\n🔗 Testing database connection...")
        with engine.connect() as conn:
            result = conn.execute(text("SELECT version()"))
            version = result.scalar()
            print(f"✅ Database connected successfully!")
            print(f"📊 Database version: {version}")
            
            # Check if we're connected to Neon specifically
            result = conn.execute(text("SELECT current_database()"))
            current_db = result.scalar()
            print(f"📁 Current database: {current_db}")
            
            # Check database type
            if "neon" in str(version).lower() or "neon" in settings.database_uri.lower():
                print("✅ Confirmed: Connected to Neon database!")
            else:
                print("⚠️  Warning: May not be connected to Neon database")
        
        # Create session
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        print("\n👥 Checking users table structure...")
        # Check if users table exists and has the expected structure
        result = db.execute(text("""
            SELECT column_name, data_type, is_nullable, column_default 
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            ORDER BY ordinal_position
        """))
        columns = result.fetchall()
        
        if columns:
            print("✅ Users table found with columns:")
            for col in columns:
                print(f"   - {col.column_name}: {col.data_type} (nullable: {col.is_nullable})")
        else:
            print("❌ Users table not found!")
            return False
        
        print("\n🔍 Checking for admin users...")
        # Query for admin users
        admin_users = db.query(User).filter(User.role == "admin").all()
        
        if admin_users:
            print(f"✅ Found {len(admin_users)} admin user(s) in Neon database:")
            for user in admin_users:
                print(f"   - ID: {user.id}")
                print(f"   - Username: {user.username}")
                print(f"   - Email: {user.email}")
                print(f"   - Role: {user.role}")
                print(f"   - Status: {user.status}")
                print(f"   - Created: {user.created_at}")
                print(f"   - Last Login: {user.last_login}")
                print("   " + "-" * 40)
        else:
            print("❌ No admin users found in Neon database.")
        
        # Show all users summary
        print("\n📊 All users in Neon database:")
        all_users = db.query(User).order_by(User.id).all()
        for user in all_users:
            print(f"   - ID {user.id}: {user.username} ({user.email}) - Role: {user.role}, Status: {user.status}")
        
        # Check total counts by role
        print("\n📈 User role distribution:")
        role_counts = db.query(User.role, text("COUNT(*)")).group_by(User.role).all()
        for role, count in role_counts:
            print(f"   - {role}: {count} users")
        
        db.close()
        return True
        
    except Exception as e:
        print(f"❌ Error testing Neon database: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_neon_database()
    sys.exit(0 if success else 1)
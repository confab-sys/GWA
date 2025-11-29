#!/usr/bin/env python3
"""
Generate secure environment variables for Render deployment
"""
import secrets
import string

def generate_secret_key(length=64):
    """Generate a secure secret key"""
    return secrets.token_urlsafe(length)

def generate_strong_password(length=16):
    """Generate a strong password"""
    alphabet = string.ascii_letters + string.digits + string.punctuation
    return ''.join(secrets.choice(alphabet) for _ in range(length))

def main():
    print("🔐 Render Environment Variables Generator")
    print("=" * 50)
    
    # Generate secure keys
    secret_key = generate_secret_key()
    
    print("\n📋 Copy these environment variables to your Render dashboard:")
    print("=" * 60)
    
    print(f"""
# Core Settings
ENVIRONMENT=production
DEBUG=false

# Security (KEEP THESE SECRET!)
SECRET_KEY={secret_key}
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS - Frontend URLs (update with your actual URLs)
CORS_ORIGINS=["https://great-awareness-frontend.vercel.app", "https://great-awareness-frontend-9urb9gcqx-confab-sys-projects.vercel.app"]

# File Upload Settings
MAX_FILE_SIZE=5242880
ALLOWED_FILE_TYPES=["image/jpeg", "image/png", "image/jpg"]

# Database (Render will provide this automatically)
# DATABASE_URL_RENDER=postgresql://psychology_app_user:password@host:5432/psychology_app_db
""")
    
    print("\n⚠️  IMPORTANT NOTES:")
    print("1. DATABASE_URL_RENDER will be set automatically by Render")
    print("2. Keep SECRET_KEY secure - don't share it publicly")
    print("3. Update CORS_ORIGINS if you add custom domains")
    print("4. Set these in your Render dashboard under 'Environment' tab")
    
    print("\n📝 Setup Steps:")
    print("1. Deploy your backend to Render")
    print("2. Create PostgreSQL database on Render")
    print("3. Copy the environment variables above to Render dashboard")
    print("4. Wait for deployment to complete")
    print("5. Test your backend at: https://your-app.onrender.com/health")

if __name__ == "__main__":
    main()
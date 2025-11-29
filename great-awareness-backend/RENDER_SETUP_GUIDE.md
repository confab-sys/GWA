# Render Environment Variables Setup Guide

## 🎯 Goal: Configure your backend for production deployment

## Step 1: Deploy Your Backend to Render (if not already done)

1. **Go to Render Dashboard**: https://dashboard.render.com
2. **Create New Web Service**
3. **Connect your GitHub repository** (great-awareness-backend)
4. **Use these settings**:
   - Name: `psychology-app-backend`
   - Environment: Python 3.11.9
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

## Step 2: Add PostgreSQL Database

1. **In Render Dashboard**, click "New" → "PostgreSQL"
2. **Database Settings**:
   - Name: `psychology-app-db`
   - Database: `psychology_app_db`
   - User: `psychology_app_user`
   - Plan: Starter (free)
3. **Wait for deployment** (takes 2-5 minutes)

## Step 3: Get Your Database URL

**Method 1: From Render Dashboard**
1. Go to your PostgreSQL database page
2. Look for "Connections" section
3. Copy the **External Database URL** (starts with `postgresql://`)

**Method 2: From Web Service**
1. Go to your web service page
2. Click "Environment" tab
3. Look for `DATABASE_URL_RENDER` variable (auto-generated)

## Step 4: Set Environment Variables

**In your Render Web Service, add these Environment Variables:**

```bash
# Core Settings
ENVIRONMENT=production
DEBUG=false

# Database (replace with your actual URL)
DATABASE_URL_RENDER=postgresql://psychology_app_user:YOUR_PASSWORD@YOUR_HOST:5432/psychology_app_db

# Security (generate a strong key)
SECRET_KEY=your-super-secret-production-key-here-minimum-32-characters

# CORS - Frontend URLs
CORS_ORIGINS=["https://great-awareness-frontend.vercel.app", "https://great-awareness-frontend-9urb9gcqx-confab-sys-projects.vercel.app"]

# Optional Settings
MAX_FILE_SIZE=5242880
ALLOWED_FILE_TYPES=["image/jpeg", "image/png", "image/jpg"]
```

## Step 5: Generate Strong Secret Key

Run this command to generate a secure key:
```bash
python -c "import secrets; print(secrets.token_urlsafe(64))"
```

## Step 6: Update Your Config Files

**Update `.env.render` file:**
```bash
ENVIRONMENT=production
DEBUG=False
DATABASE_URL_RENDER=postgresql://YOUR_ACTUAL_URL_HERE
SECRET_KEY=YOUR_GENERATED_KEY_HERE
CORS_ORIGINS=["https://great-awareness-frontend.vercel.app", "https://great-awareness-frontend-9urb9gcqx-confab-sys-projects.vercel.app"]
```

## Step 7: Deploy & Test

1. **Commit and push your changes**
2. **Wait for Render deployment** (2-3 minutes)
3. **Test your backend**: https://YOUR_BACKEND_URL.onrender.com/health
4. **Test frontend connection**: Your Vercel app should now connect to the production backend

## 🔍 Verification Steps

**Check if backend is running:**
```bash
curl https://YOUR_BACKEND_URL.onrender.com/health
```

**Check database connection:**
```bash
curl https://YOUR_BACKEND_URL.onrender.com/api/info
```

**Test frontend-backend connection:**
- Open your Vercel frontend
- Try to register/login
- Check browser Network tab for API calls

## 🚨 Common Issues & Solutions

1. **Database connection failed**: Check DATABASE_URL_RENDER format
2. **CORS errors**: Ensure CORS_ORIGINS includes your exact Vercel URLs
3. **Secret key too short**: Use at least 32 characters
4. **Debug mode still on**: Set DEBUG=false

## 📋 Quick Reference

**Your current setup:**
- Frontend: https://great-awareness-frontend.vercel.app
- Backend: Deploy to Render (get URL after deployment)
- Database: PostgreSQL on Render (get URL after creation)

Need help? Check Render docs: https://render.com/docs
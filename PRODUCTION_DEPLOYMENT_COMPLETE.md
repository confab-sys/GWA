# Complete Production Deployment Guide

## 🚀 Step-by-Step Deployment Process

### Phase 1: Backend Deployment to Render

#### 1.1 Create PostgreSQL Database
1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click "New" → "PostgreSQL"
3. **Database Configuration:**
   - Name: `psychology-app-db`
   - Database: `psychology_app_db`
   - User: `psychology_app_user`
   - Plan: Starter (recommended for production)
4. Click "Create Database" and wait 2-3 minutes
5. **Copy the Internal Database URL** - you'll need this for your web service

#### 1.2 Create Web Service
1. Click "New" → "Web Service"
2. **Connect Repository:**
   - Connect your GitHub/GitLab repo containing the backend
   - Or use "Upload" if not using Git
3. **Service Configuration:**
   - Name: `psychology-app-backend`
   - Environment: Python
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
4. **Instance Settings:**
   - Plan: Starter (recommended) or Free for testing
   - Auto-deploy: Yes

#### 1.3 Configure Environment Variables
In your Render dashboard, go to your web service → "Environment" tab and add:

```bash
# Core Settings
ENVIRONMENT=production
DEBUG=False

# Security (Generate a strong secret key - minimum 32 characters)
SECRET_KEY=your-super-secret-production-key-here-change-this-32-chars-min
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Database (Render will auto-populate this)
DATABASE_URL_RENDER=postgresql://psychology_app_user:your-password@your-internal-db-url:5432/psychology_app_db

# CORS - Update with your actual frontend URLs
CORS_ORIGINS=["https://your-frontend-domain.com", "https://your-frontend-domain.onrender.com"]

# File Upload
MAX_FILE_SIZE=5242880
ALLOWED_FILE_TYPES=["image/jpeg", "image/png", "image/jpg"]
```

#### 1.4 Deploy Backend
1. Click "Deploy" in your Render dashboard
2. Monitor logs for any errors
3. Test endpoints:
   - Health: `https://your-app-name.onrender.com/health`
   - Info: `https://your-app-name.onrender.com/api/info`
   - Root: `https://your-app-name.onrender.com/`

### Phase 2: Frontend Configuration

#### 2.1 Update Frontend Configuration
1. Open `lib/utils/config.dart`
2. Update with your actual Render backend URL:

```dart
// Production (Render) backend - UPDATE THIS with your actual Render URL
const String apiBaseUrlProd = 'https://psychology-app-backend-xyz.onrender.com';

// Change to production when ready
const String currentEnvironment = 'production'; // Change from 'development'
```

#### 2.2 Build Frontend for Production
```bash
cd great-awareness-frontend
flutter build web --release
```

#### 2.3 Deploy Frontend (Options)
**Option A: Firebase Hosting (Recommended)**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase
firebase login
firebase init hosting

# Deploy
firebase deploy
```

**Option B: Netlify**
1. Go to [Netlify](https://netlify.com)
2. Drag your `build/web` folder to deploy
3. Configure custom domain if needed

**Option C: Vercel**
1. Go to [Vercel](https://vercel.com)
2. Import your frontend repository
3. Deploy automatically

### Phase 3: Database Migration

#### 3.1 Run Migrations
```bash
# SSH into your Render service (paid plans)
# Or run locally with Render database URL

export DATABASE_URL_RENDER=your-render-db-url
alembic upgrade head
```

#### 3.2 Create Admin User (Optional)
```bash
# Create admin user for content management
python manage_users.py create-admin admin@yourapp.com your-password
```

### Phase 4: Testing & Validation

#### 4.1 Test All Endpoints
```bash
# Health check
curl https://your-backend.onrender.com/health

# API info
curl https://your-backend.onrender.com/api/info

# Test authentication
curl -X POST https://your-backend.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}'
```

#### 4.2 Test Frontend Integration
- Register new user
- Login functionality
- Content loading
- Video playback
- Q&A system

### Phase 5: Production Optimization

#### 5.1 Security Hardening
- [ ] Change all default passwords
- [ ] Enable HTTPS (Render provides SSL)
- [ ] Configure proper CORS origins
- [ ] Set up rate limiting
- [ ] Enable database backups

#### 5.2 Performance Optimization
- [ ] Enable CDN for static assets
- [ ] Optimize database queries
- [ ] Set up caching (Redis optional)
- [ ] Monitor resource usage

#### 5.3 Monitoring Setup
- [ ] Set up error tracking (Sentry recommended)
- [ ] Configure uptime monitoring
- [ ] Set up database monitoring
- [ ] Create alerts for critical issues

## 🎯 Quick Reference

### Backend URLs
- **Development**: `http://localhost:8000`
- **Production**: `https://your-app-name.onrender.com`

### Database URLs
- **Development**: `sqlite:///./psychology_app.db`
- **Production**: `postgresql://user:pass@host:5432/dbname`

### Key Files Modified
- `great-awareness-backend/render.yaml` - Render configuration
- `great-awareness-backend/app/core/config.py` - Environment settings
- `great-awareness-frontend/lib/utils/config.dart` - Frontend API URLs

### Environment Variables
Remember to set these in Render dashboard:
- `SECRET_KEY` (generate strong key)
- `DATABASE_URL_RENDER` (auto-populated)
- `CORS_ORIGINS` (your frontend URLs)
- `ENVIRONMENT=production`
- `DEBUG=False`

## 🆘 Troubleshooting

### Common Issues:

1. **Database Connection Failed**
   - Check DATABASE_URL_RENDER format
   - Use Internal Database URL, not external
   - Verify database is running

2. **CORS Errors**
   - Update CORS_ORIGINS with exact frontend URLs
   - Include both www and non-www versions

3. **Build Failures**
   - Check requirements.txt is up to date
   - Verify Python version compatibility
   - Check for missing environment variables

4. **Memory Issues (Free Tier)**
   - Free tier has 512MB RAM limit
   - Consider upgrading to Starter plan

### Support Resources:
- Render Documentation: https://render.com/docs
- FastAPI Documentation: https://fastapi.tiangolo.com/
- Flutter Web Deployment: https://flutter.dev/docs/deployment/web

## 🎉 Success Indicators

✅ Backend deployed and accessible
✅ Database connected and migrated
✅ Frontend deployed and functional
✅ All API endpoints working
✅ User authentication functional
✅ Content loading properly
✅ Videos playing correctly
✅ Q&A system operational

Once everything is working, you'll have a fully functional psychology app running in production! 🚀
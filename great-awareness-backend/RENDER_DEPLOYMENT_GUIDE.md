# Render Deployment Guide for Psychology App Backend

## Prerequisites
- Render account ready
- Git repository with your backend code
- PostgreSQL database created on Render

## Step 1: Create PostgreSQL Database on Render

1. Go to https://dashboard.render.com
2. Click "New" → "PostgreSQL"
3. Name: `psychology-app-db`
4. Database: `psychology_app_db`
5. User: `psychology_app_user`
6. Plan: Starter (sufficient for initial deployment)
7. Click "Create Database"
8. Wait for database to be created (takes a few minutes)
9. Copy the "Internal Database URL" - you'll need this

## Step 2: Create Web Service on Render

1. Go to https://dashboard.render.com
2. Click "New" → "Web Service"
3. Connect your GitHub/GitLab repository or upload your code
4. Name: `psychology-app-backend`
5. Environment: Python
6. Build Command: `pip install -r requirements.txt`
7. Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
8. Instance Type: Free (or Starter for better performance)

## Step 3: Configure Environment Variables

In your Render dashboard, go to your web service settings and add these environment variables:

```env
ENVIRONMENT=production
DEBUG=False
SECRET_KEY=your-super-secret-key-here-minimum-32-characters
DATABASE_URL_RENDER=postgresql://psychology_app_user:password@your-internal-db-url:5432/psychology_app_db
CORS_ORIGINS=["https://your-frontend-domain.com", "https://your-frontend-domain.onrender.com"]
```

**Important**: Use the Internal Database URL from your PostgreSQL database, not the external one.

## Step 4: Deploy

1. Click "Deploy" in your Render dashboard
2. Wait for the deployment to complete (usually 2-5 minutes)
3. Check the logs for any errors
4. Test the health endpoint: `https://your-app-name.onrender.com/health`

## Step 5: Update Frontend Configuration

Once your backend is deployed, update your Flutter app's API service to point to the new backend URL:

```dart
// In your frontend config
const String apiBaseUrl = 'https://your-app-name.onrender.com';
```

## Step 6: Database Migration (if needed)

If you need to run database migrations:

```bash
# SSH into your Render service (if using paid plan)
# Or run migrations locally with the Render database URL
export DATABASE_URL_RENDER=your-render-db-url
alembic upgrade head
```

## Troubleshooting

### Common Issues:

1. **Database Connection Failed**
   - Check DATABASE_URL_RENDER format
   - Ensure you're using Internal Database URL
   - Verify database is running

2. **CORS Issues**
   - Update CORS_ORIGINS with your actual frontend URLs
   - Include both www and non-www versions

3. **Port Issues**
   - Render automatically sets PORT environment variable
   - Your app should listen on $PORT, not hardcoded 8000

4. **Memory Issues (Free Tier)**
   - Free tier has 512MB RAM limit
   - Consider upgrading to Starter plan if needed

### Health Check:

Test these endpoints after deployment:
- `https://your-app-name.onrender.com/health`
- `https://your-app-name.onrender.com/`
- `https://your-app-name.onrender.com/api/info`

### Logs:

Check Render logs for detailed error messages:
- Go to your web service dashboard
- Click on "Logs" tab
- Look for any error messages during startup

## Security Checklist:

- [ ] Change SECRET_KEY to a secure random value
- [ ] Use production database (not SQLite)
- [ ] Set DEBUG=False
- [ ] Configure proper CORS origins
- [ ] Use HTTPS (Render provides SSL automatically)
- [ ] Consider adding rate limiting for production

## Next Steps:

1. Set up custom domain (optional)
2. Configure email service for user verification
3. Set up monitoring and alerts
4. Consider backup strategy for database
5. Plan for scaling as your user base grows
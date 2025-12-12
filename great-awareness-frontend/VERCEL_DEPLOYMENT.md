# Great Awareness Frontend - Vercel Deployment Guide

##  Your app is already deployed!

**Live URL:** https://great-awareness-frontend-1wx7ily6z-confab-sys-projects.vercel.app

## 🚀 For future deployments

### Option 1: Vercel Dashboard (Recommended)

1. **Go to [Vercel Dashboard](https://vercel.com)**
2. **Find your project:** `great-awareness-frontend`
3. **Deployments happen automatically** when you push to your GitHub repository

### Option 2: Manual Deployment

1. **Build your Flutter web app:**
   ```powershell
   flutter build web --release
   ```

2. **Deploy using Vercel CLI:**
   ```powershell
   vercel --prod
   ```

## 📁 Project Structure

```
great-awareness-frontend/
├── lib/                    # Flutter source code
├── build/web/             # Built web files (auto-generated)
├── vercel.json             # Vercel configuration
├── package.json            # Node.js configuration for Vercel
├── build.sh                # Build script for Vercel
└── VERCEL_DEPLOYMENT.md    # This file
```

## ⚙️ Configuration Files

- **`vercel.json`**: Modern Vercel configuration (no more `builds` warning)
- **`package.json`**: Node.js project configuration
- **`build.sh`**: Flutter build script for Vercel

## 🔧 Environment Configuration

Your Flutter app is configured to use:
- **Production API**: `https://gwa-enus.onrender.com` (set in `lib/utils/config.dart`)
- **Development API**: `http://localhost:8000`

## 🛡️ Next Steps

1. **Test your live app:** Visit the URL above
2. **Update CORS settings** on your backend to allow the Vercel domain
3. **Set up a custom domain** (optional) in Vercel dashboard
4. **Configure automatic deployments** from GitHub

## 🔄 Automatic Deployments

Your app is set up for automatic deployments. Every time you push changes to your GitHub repository, Vercel will:
1. Detect the changes
2. Run `flutter build web --release`
3. Deploy the new version automatically

## 📱 Features

Your deployed Flutter web app includes:
- ✅ User authentication
- ✅ Content browsing
- ✅ Video playback
- ✅ Admin posting
- ✅ Settings and user management

## 🆘 Troubleshooting

- **Build fails**: Make sure Flutter web is enabled: `flutter config --enable-web`
- **API calls fail**: Check CORS settings on your backend
- **Deployment issues**: Check Vercel dashboard logs

**Need help?** Check the Vercel dashboard for deployment logs and build details.
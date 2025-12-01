#!/bin/bash

echo "Starting Flutter web build for Vercel..."

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "Installing Flutter..."
    # Install Flutter in Vercel environment
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:$PWD/flutter/bin"
fi

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean

# Install Flutter dependencies
echo "Installing dependencies..."
flutter pub get

# Build for web with CanvasKit renderer (using dart-define instead of --web-renderer)
echo "Building for web..."
flutter build web \
  --release \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://unpkg.com/canvaskit-wasm@0.38.0/bin/

# Check if build was successful
if [ -d "build/web" ]; then
    echo "✅ Build successful! Contents of build/web:"
    ls -la build/web/
    
    # Ensure proper base href for Vercel deployment
    echo "Setting up base href for Vercel..."
    sed -i 's|<base href="/">|<base href="/">|' build/web/index.html
    
    # Fix service worker registration for Vercel
    echo "Fixing service worker for Vercel deployment..."
    sed -i 's|navigator.serviceWorker.register|navigator.serviceWorker.register("flutter_service_worker.js?v=" + serviceWorkerVersion)|' build/web/flutter.js
    
    # Ensure proper MIME types by creating a simple .vercelignore if needed
    echo "Setting up Vercel configuration..."
    
    echo "Files ready for Vercel deployment:"
    ls build/web/ | head -10
else
    echo "❌ Build failed - build/web directory not found"
    exit 1
fi
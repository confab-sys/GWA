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

# Build for web
echo "Building for web..."
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true

# Check if build was successful
if [ -d "build/web" ]; then
    echo "✅ Build successful! Contents of build/web:"
    ls -la build/web/
    echo "Files ready for Vercel deployment:"
    ls build/web/ | head -10
else
    echo "❌ Build failed - build/web directory not found"
    exit 1
fi
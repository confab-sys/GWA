#!/bin/bash

# Flutter Web Build and Deploy Script for Vercel
echo "Building Flutter web app..."

# Build the web version
flutter build web --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "To deploy to Vercel, run: vercel --prod"
    echo "Or use the Vercel dashboard to import your GitHub repository"
else
    echo "❌ Build failed. Please check the error messages above."
    exit 1
fi
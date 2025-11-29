# Flutter Web Build and Deploy Script for Vercel (PowerShell)
Write-Host "Building Flutter web app..." -ForegroundColor Green

# Build the web version
flutter build web --release

# Check if build was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host "To deploy to Vercel, run: vercel --prod" -ForegroundColor Yellow
    Write-Host "Or use the Vercel dashboard to import your GitHub repository" -ForegroundColor Yellow
} else {
    Write-Host "❌ Build failed. Please check the error messages above." -ForegroundColor Red
    exit 1
}
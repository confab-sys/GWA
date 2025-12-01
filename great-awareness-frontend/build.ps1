# PowerShell build script for Flutter web deployment
Write-Host "Starting Flutter web build for Vercel..." -ForegroundColor Green

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter clean failed" -ForegroundColor Red
    exit 1
}

# Install Flutter dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter pub get failed" -ForegroundColor Red
    exit 1
}

# Build for web
Write-Host "Building for web..." -ForegroundColor Yellow
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter build web failed" -ForegroundColor Red
    exit 1
}

# Check if build was successful
if (Test-Path "build/web") {
    Write-Host "✅ Build successful! Contents of build/web:" -ForegroundColor Green
    Get-ChildItem "build/web" | Format-Table Name, Length -AutoSize
    
    Write-Host "Files ready for Vercel deployment:" -ForegroundColor Green
    Get-ChildItem "build/web" | Select-Object -First 10 | Format-Table Name -AutoSize
} else {
    Write-Host "❌ Build failed - build/web directory not found" -ForegroundColor Red
    exit 1
}
@echo off
echo Starting Flutter web build for Vercel...

REM Check if Flutter is available
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo Installing Flutter...
    REM Install Flutter in Vercel environment
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    set PATH=%PATH%;%CD%\flutter\bin
)

REM Clean previous builds
echo Cleaning previous builds...
flutter clean

REM Install Flutter dependencies
echo Installing dependencies...
flutter pub get

REM Build for web with CanvasKit renderer
echo Building for web...
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true --dart-define=FLUTTER_WEB_AUTO_DETECT=true --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://unpkg.com/canvaskit-wasm@0.38.0/bin/

REM Check if build was successful
if exist "build\web" (
    echo Build successful! Contents of build/web:
    dir build\web
    
    REM Ensure proper base href for Vercel deployment
    echo Setting up base href for Vercel...
    powershell -Command "(Get-Content build\web\index.html) -replace '<base href="/">', '<base href="/">' | Set-Content build\web\index.html"
    
    echo Files ready for Vercel deployment
) else (
    echo Build failed - build/web directory not found
    exit /b 1
)
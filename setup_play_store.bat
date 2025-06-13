@echo off
echo ========================================
echo HomeConnect - Play Store Setup Helper
echo ========================================
echo.

echo Current Status:
echo ✅ APK Built: build\app\outputs\flutter-apk\app-release.apk (55.4MB)
echo ✅ App Icons Updated with HomeConnect Logo
echo ✅ Package Name: com.homeconnect.society.management
echo ✅ App Name: HomeConnect
echo.

echo Next Steps for Play Store Publication:
echo.
echo 1. Create Google Play Developer Account ($25 fee)
echo    Visit: https://play.google.com/console
echo.
echo 2. Generate Production Signing Key
echo    Run: keytool -genkey -v -keystore homeconnect-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias homeconnect-release
echo.
echo 3. Create Screenshots (Required)
echo    - Phone screenshots: 1080x1920 or 1080x2340
echo    - Feature graphic: 1024x500
echo    - App icon: 512x512
echo.
echo 4. Build App Bundle for Play Store
echo    Run: flutter build appbundle --release
echo.
echo 5. Complete Store Listing
echo    - App description (ready in guide)
echo    - Privacy policy (create at privacypolicytemplate.net)
echo    - Content rating questionnaire
echo.

echo Files Ready:
echo - APK: %~dp0build\app\outputs\flutter-apk\app-release.apk
echo - Guide: %~dp0play_store_setup_guide.md
echo.

echo Would you like to:
echo [1] Open Play Store Console
echo [2] Open APK location
echo [3] View setup guide
echo [4] Exit
echo.

set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" (
    start https://play.google.com/console
) else if "%choice%"=="2" (
    explorer "%~dp0build\app\outputs\flutter-apk"
) else if "%choice%"=="3" (
    notepad "%~dp0play_store_setup_guide.md"
) else if "%choice%"=="4" (
    exit
) else (
    echo Invalid choice. Please run the script again.
)

pause 
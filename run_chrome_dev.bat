@echo off
echo Starting Chrome with disabled web security for Flutter development...
echo WARNING: Only use this for development! This disables important security features.
echo.

REM Close any existing Chrome instances
taskkill /f /im chrome.exe 2>nul

REM Start Chrome with disabled web security
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --disable-web-security --disable-features=VizDisplayCompositor --user-data-dir="C:\temp\chrome_dev_session" --allow-running-insecure-content --disable-extensions

echo Chrome started with disabled web security.
echo You can now run your Flutter app and it should connect to the backend.
echo.
echo To run Flutter app: flutter run -d chrome --web-renderer html
echo.
pause 
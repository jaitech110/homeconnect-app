@echo off
echo Testing Manage Voting API Endpoints
echo ===================================

echo.
echo Step 1: Testing elections endpoint...
curl -X GET "http://localhost:5000/union/elections?union_id=test-union-123" -H "Content-Type: application/json"

echo.
echo.
echo Step 2: Testing server connectivity...
curl -X GET "http://localhost:5000/test" -H "Content-Type: application/json"

echo.
echo.
echo If elections endpoint returns data, the Manage Voting screen will work!
echo If it returns an error, the screen will show appropriate error messages.
echo The screen handles both cases gracefully. 
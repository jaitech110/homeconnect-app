@echo off
echo Testing UUID Fix for Resident Login
echo ====================================

echo.
echo Step 1: Creating approved test resident...
curl -X POST http://localhost:5000/signup -H "Content-Type: application/json" -d "{\"email\":\"approvedresident@gmail.com\",\"password\":\"password123\",\"first_name\":\"Approved\",\"last_name\":\"Resident\",\"phone\":\"1234567890\",\"username\":\"A-102\",\"address\":\"456 Test Street\",\"role\":\"Resident\",\"building_name\":\"Sunrise Apartment\",\"resident_type\":\"Owner\",\"is_approved\":true}"

echo.
echo.
echo Step 2: Testing login with approved resident (should return UUID)...
curl -X POST http://localhost:5000/login -H "Content-Type: application/json" -d "{\"email\":\"approvedresident@gmail.com\",\"password\":\"password123\"}"

echo.
echo.
echo The UUID in the response should NOT cause a FormatException in Flutter!
echo Flutter frontend now accepts UUID strings instead of trying to parse them as integers. 
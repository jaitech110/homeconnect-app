@echo off
echo Testing Resident Login Flow
echo ==========================

echo.
echo Step 1: Creating test resident...
curl -X POST http://localhost:5000/signup -H "Content-Type: application/json" -d "{\"email\":\"testlogin@gmail.com\",\"password\":\"password123\",\"first_name\":\"Login\",\"last_name\":\"Test\",\"phone\":\"1234567890\",\"username\":\"A-101\",\"address\":\"123 Test Street\",\"role\":\"Resident\",\"building_name\":\"Sunrise Apartment\",\"resident_type\":\"Owner\",\"is_approved\":false}"

echo.
echo.
echo Step 2: Testing login...
curl -X POST http://localhost:5000/login -H "Content-Type: application/json" -d "{\"email\":\"testlogin@gmail.com\",\"password\":\"password123\"}"

echo.
echo.
echo Test completed! 
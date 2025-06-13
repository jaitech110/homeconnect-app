@echo off
echo ========================================
echo Testing COMPLETE Voting Flow - FIXED
echo ========================================
echo.

REM Step 1: Create a union incharge first
echo Step 1: Creating test union incharge...
echo =======================================
curl -X POST "http://localhost:5000/signup" -H "Content-Type: application/json" -d "{\"email\":\"uniontest@gmail.com\",\"password\":\"password123\",\"first_name\":\"Test\",\"last_name\":\"Union\",\"phone\":\"1234567890\",\"username\":\"U-101\",\"address\":\"123 Test Street\",\"role\":\"Union Incharge\",\"building_name\":\"Sunrise Apartment\",\"is_approved\":true}" > union_response.json

echo.
echo Union Response:
type union_response.json
echo.

REM Step 2: Create a resident in the same building
echo Step 2: Creating test resident...
echo =================================
curl -X POST "http://localhost:5000/signup" -H "Content-Type: application/json" -d "{\"email\":\"residenttest@gmail.com\",\"password\":\"password123\",\"first_name\":\"Test\",\"last_name\":\"Resident\",\"phone\":\"1234567891\",\"username\":\"R-101\",\"address\":\"456 Test Street\",\"role\":\"Resident\",\"building_name\":\"Sunrise Apartment\",\"resident_type\":\"Owner\",\"is_approved\":true}" > resident_response.json

echo.
echo Resident Response:
type resident_response.json
echo.

REM Step 3: Get all users to find the actual IDs
echo Step 3: Getting all users to find IDs...
echo ========================================
curl -X GET "http://localhost:5000/users" -H "Content-Type: application/json" > users_response.json

echo.
echo Users Response:
type users_response.json
echo.

echo ========================================
echo MANUAL TESTING REQUIRED
echo ========================================
echo.
echo Please check the user IDs above and manually test:
echo.
echo 1. Create election with union_incharge_id from above
echo 2. Test resident elections with resident_id from above
echo 3. Test voting with proper election_id
echo.
echo Example commands:
echo curl -X POST "http://localhost:5000/union/create_election" -H "Content-Type: application/json" -d "{\"title\":\"Pool Renovation\",\"description\":\"Should we renovate?\",\"choices\":[\"Yes\",\"No\"],\"union_incharge_id\":\"UNION_ID_HERE\"}"
echo.
echo curl -X GET "http://localhost:5000/resident/elections?resident_id=RESIDENT_ID_HERE"
echo.
echo curl -X POST "http://localhost:5000/resident/vote" -H "Content-Type: application/json" -d "{\"resident_id\":\"RESIDENT_ID_HERE\",\"election_id\":\"ELECTION_ID_HERE\",\"choice\":\"Yes\"}" 
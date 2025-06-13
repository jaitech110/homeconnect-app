@echo off
echo ========================================
echo Testing COMPLETE Voting Flow - UPDATED
echo ========================================
echo.

REM Step 1: Create a union incharge first
echo Step 1: Creating test union incharge...
echo =======================================
curl -X POST "http://localhost:5000/signup" -H "Content-Type: application/json" -d "{\"email\":\"uniontest@gmail.com\",\"password\":\"password123\",\"first_name\":\"Test\",\"last_name\":\"Union\",\"phone\":\"1234567890\",\"username\":\"U-101\",\"address\":\"123 Test Street\",\"role\":\"Union Incharge\",\"building_name\":\"Sunrise Apartment\",\"is_approved\":true}"

echo.
echo.

REM Step 2: Create a resident in the same building
echo Step 2: Creating test resident...
echo =================================
curl -X POST "http://localhost:5000/signup" -H "Content-Type: application/json" -d "{\"email\":\"residenttest@gmail.com\",\"password\":\"password123\",\"first_name\":\"Test\",\"last_name\":\"Resident\",\"phone\":\"1234567891\",\"username\":\"R-101\",\"address\":\"456 Test Street\",\"role\":\"Resident\",\"building_name\":\"Sunrise Apartment\",\"resident_type\":\"Owner\",\"is_approved\":true}"

echo.
echo.

REM Step 3: Union incharge creates an election
echo Step 3: Union incharge creates election...
echo ==========================================
curl -X POST "http://localhost:5000/union/create_election" -H "Content-Type: application/json" -d "{\"title\":\"Community Pool Renovation\",\"description\":\"Should we renovate the community pool?\",\"choices\":[\"Yes\",\"No\",\"Abstain\"],\"union_incharge_id\":\"1\"}"

echo.
echo.

REM Step 4: Get union elections to see the created election
echo Step 4: Union incharge views their elections...
echo ==============================================
curl -X GET "http://localhost:5000/union/elections?union_id=1" -H "Content-Type: application/json"

echo.
echo.

REM Step 5: Resident checks for available elections
echo Step 5: Resident fetches available elections...
echo ===============================================
curl -X GET "http://localhost:5000/resident/elections?resident_id=2" -H "Content-Type: application/json"

echo.
echo.

REM Step 6: Resident votes on the election
echo Step 6: Resident votes on election...
echo ====================================
curl -X POST "http://localhost:5000/resident/vote" -H "Content-Type: application/json" -d "{\"resident_id\":\"2\",\"election_id\":\"1\",\"choice\":\"Yes\"}"

echo.
echo.

REM Step 7: Check updated results
echo Step 7: Check updated election results...
echo ========================================
curl -X GET "http://localhost:5000/union/elections?union_id=1" -H "Content-Type: application/json"

echo.
echo.
echo ========================================
echo COMPLETE VOTING FLOW TEST COMPLETE
echo ========================================
echo.
echo ✅ EXPECTED RESULTS:
echo 1. Union incharge and resident created successfully
echo 2. Election created with success message
echo 3. Union incharge can see their election
echo 4. Resident can see the election in their building
echo 5. Vote submission returns success
echo 6. Results show updated vote count (1 vote for "Yes")
echo.
echo 🎯 If all steps work, the voting integration is COMPLETE! 
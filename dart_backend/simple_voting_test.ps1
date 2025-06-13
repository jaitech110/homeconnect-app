# Simple Voting Test Script
Write-Host "========================================" -ForegroundColor Green
Write-Host "Testing Complete Voting Flow" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Test 1: Create Election
Write-Host "`nStep 1: Creating election..." -ForegroundColor Yellow
$electionData = @{
    title = "Pool Renovation"
    description = "Should we renovate the community pool?"
    choices = @("Yes", "No", "Abstain")
    union_incharge_id = "4a477715-06e9-4faf-bf8e-a693ad5d358e"
} | ConvertTo-Json

try {
    $electionResponse = Invoke-RestMethod -Uri "http://localhost:5000/union/create_election" -Method POST -ContentType "application/json" -Body $electionData
    Write-Host "Election created successfully!" -ForegroundColor Green
    $electionResponse | ConvertTo-Json
    $electionId = $electionResponse.election_id
} catch {
    Write-Host "Error creating election: $($_.Exception.Message)" -ForegroundColor Red
    $electionId = $null
}

# Test 2: Get Union Elections
Write-Host "`nStep 2: Getting union elections..." -ForegroundColor Yellow
try {
    $unionElections = Invoke-RestMethod -Uri "http://localhost:5000/union/elections?union_id=4a477715-06e9-4faf-bf8e-a693ad5d358e" -Method GET
    Write-Host "Union elections retrieved!" -ForegroundColor Green
    $unionElections | ConvertTo-Json
} catch {
    Write-Host "Error getting union elections: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Get Resident Elections
Write-Host "`nStep 3: Getting resident elections..." -ForegroundColor Yellow
try {
    $residentElections = Invoke-RestMethod -Uri "http://localhost:5000/resident/elections?resident_id=3d967c54-3a02-4f29-b063-d9b8e94ff244" -Method GET
    Write-Host "Resident elections retrieved!" -ForegroundColor Green
    $residentElections | ConvertTo-Json
} catch {
    Write-Host "Error getting resident elections: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Submit Vote (if election was created)
if ($electionId) {
    Write-Host "`nStep 4: Submitting vote..." -ForegroundColor Yellow
    $voteData = @{
        resident_id = "3d967c54-3a02-4f29-b063-d9b8e94ff244"
        election_id = $electionId
        choice = "Yes"
    } | ConvertTo-Json

    try {
        $voteResponse = Invoke-RestMethod -Uri "http://localhost:5000/resident/vote" -Method POST -ContentType "application/json" -Body $voteData
        Write-Host "Vote submitted successfully!" -ForegroundColor Green
        $voteResponse | ConvertTo-Json
    } catch {
        Write-Host "Error submitting vote: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "`nStep 4: Skipping vote submission (no election created)" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Voting Flow Test Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green 
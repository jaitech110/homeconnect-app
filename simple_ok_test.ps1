# Simple OK Button Test
Write-Host "Testing OK Button Fix..." -ForegroundColor Green

$baseUrl = "http://localhost:5000"
$residentId = "resident123"
$unionId = "union123"

Write-Host "Creating test election..." -ForegroundColor Yellow
$electionData = @{
    title = "OK Button Test"
    description = "Test election"
    choices = @("Yes", "No")
    union_incharge_id = $unionId
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/union/elections" -Method POST -Body $electionData -ContentType "application/json"
    $electionId = $createResponse.election_id
    Write-Host "Election created: $electionId" -ForegroundColor Green
    
    # Vote
    $voteData = @{
        election_id = $electionId
        resident_id = $residentId
        choice = "Yes"
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "$baseUrl/resident/vote" -Method POST -Body $voteData -ContentType "application/json"
    Write-Host "Vote submitted" -ForegroundColor Green
    
    # Publish
    Invoke-RestMethod -Uri "$baseUrl/union/elections/$electionId/publish" -Method POST -ContentType "application/json"
    Write-Host "Results published" -ForegroundColor Green
    
    Write-Host "Test data ready! Check Flutter app now." -ForegroundColor Cyan
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
} 
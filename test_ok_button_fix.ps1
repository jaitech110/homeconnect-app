# Quick test for OK button fix
Write-Host "🧪 Testing OK Button Fix..." -ForegroundColor Green

$baseUrl = "http://localhost:5000"
$residentId = "resident123"
$unionId = "union123"

# Step 1: Create election
Write-Host "📋 Creating test election..." -ForegroundColor Yellow
$electionData = @{
    title = "OK Button Test Election"
    description = "Testing the OK button functionality"
    choices = @("Yes", "No", "Maybe")
    union_incharge_id = $unionId
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/union/elections" -Method POST -Body $electionData -ContentType "application/json"
    $electionId = $createResponse.election_id
    Write-Host "✅ Election created: $electionId" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create election: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Vote
Write-Host "📋 Submitting vote..." -ForegroundColor Yellow
$voteData = @{
    election_id = $electionId
    resident_id = $residentId
    choice = "Yes"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "$baseUrl/resident/vote" -Method POST -Body $voteData -ContentType "application/json"
    Write-Host "✅ Vote submitted" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to vote: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Publish results
Write-Host "📋 Publishing results..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$baseUrl/union/elections/$electionId/publish" -Method POST -ContentType "application/json"
    Write-Host "✅ Results published" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to publish: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Check resident elections
Write-Host "📋 Checking resident elections..." -ForegroundColor Yellow
try {
    $elections = Invoke-RestMethod -Uri "$baseUrl/resident/elections?resident_id=$residentId" -Method GET
    $publishedElections = $elections.elections | Where-Object { $_.status -eq "published" }
    
    if ($publishedElections.Count -gt 0) {
        Write-Host "✅ Published election found! OK button should be visible." -ForegroundColor Green
        Write-Host "🔍 Election: $($publishedElections[0].title)" -ForegroundColor Cyan
        Write-Host "🔍 Status: $($publishedElections[0].status)" -ForegroundColor Cyan
        Write-Host "🔍 Results Published: $($publishedElections[0].results_published)" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ No published elections found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Failed to get elections: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Setup complete! Now test in Flutter app:" -ForegroundColor Green
Write-Host "1. Open Resident Dashboard → Voting" -ForegroundColor White
Write-Host "2. Look for 'OK Button Test Election' with blue 'Results Available' badge" -ForegroundColor White
Write-Host "3. Click on the election to view results" -ForegroundColor White
Write-Host "4. Verify 'OK' button is visible and functional" -ForegroundColor White
Write-Host "5. Click 'OK' to acknowledge - election should disappear!" -ForegroundColor White 
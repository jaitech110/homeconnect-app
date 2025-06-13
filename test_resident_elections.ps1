# Test script for Resident Elections Screen OK button functionality
Write-Host "🧪 Testing Resident Elections Screen with OK Button..." -ForegroundColor Green

$baseUrl = "http://localhost:5000"

# Test data
$residentId = "550e8400-e29b-41d4-a716-446655440000"  # Sample UUID
$unionId = "550e8400-e29b-41d4-a716-446655440001"     # Sample UUID

Write-Host "📋 Step 1: Creating test election..." -ForegroundColor Yellow

# Create election
$electionData = @{
    title = "Testing OK Button Election"
    description = "This election tests the OK button functionality"
    choices = @("Yes", "No")
    union_incharge_id = $unionId
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/union/elections" -Method POST -Body $electionData -ContentType "application/json"
    $electionId = $createResponse.election_id
    Write-Host "✅ Election created with ID: $electionId" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create election: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Step 2: Resident voting..." -ForegroundColor Yellow

# Submit vote
$voteData = @{
    election_id = $electionId
    resident_id = $residentId
    choice = "Yes"
} | ConvertTo-Json

try {
    $voteResponse = Invoke-RestMethod -Uri "$baseUrl/resident/vote" -Method POST -Body $voteData -ContentType "application/json"
    Write-Host "✅ Vote submitted successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to submit vote: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Step 3: Publishing results..." -ForegroundColor Yellow

# Publish results
try {
    $publishResponse = Invoke-RestMethod -Uri "$baseUrl/union/elections/$electionId/publish" -Method POST -ContentType "application/json"
    Write-Host "✅ Results published successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to publish results: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Step 4: Checking resident elections (should show published result)..." -ForegroundColor Yellow

# Get resident elections
try {
    $electionsResponse = Invoke-RestMethod -Uri "$baseUrl/resident/elections?resident_id=$residentId" -Method GET
    Write-Host "✅ Resident elections retrieved" -ForegroundColor Green
    Write-Host "📊 Elections data:" -ForegroundColor Cyan
    $electionsResponse | ConvertTo-Json -Depth 5 | Write-Host
    
    # Check if published election is present
    $publishedElections = $electionsResponse.elections | Where-Object { $_.status -eq "published" }
    if ($publishedElections.Count -gt 0) {
        Write-Host "✅ Published election found - OK button should be visible!" -ForegroundColor Green
        Write-Host "🔍 Election status: $($publishedElections[0].status)" -ForegroundColor Cyan
        Write-Host "🔍 Results published: $($publishedElections[0].results_published)" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ No published elections found for resident" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Failed to get resident elections: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Step 5: Testing acknowledge functionality..." -ForegroundColor Yellow

# Test acknowledge
try {
    $acknowledgeData = @{
        resident_id = $residentId
    } | ConvertTo-Json
    
    $acknowledgeResponse = Invoke-RestMethod -Uri "$baseUrl/resident/elections/$electionId/acknowledge" -Method POST -Body $acknowledgeData -ContentType "application/json"
    Write-Host "✅ Acknowledge request successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to acknowledge: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Step 6: Verifying election disappears after acknowledge..." -ForegroundColor Yellow

# Check elections again after acknowledge
try {
    $finalElectionsResponse = Invoke-RestMethod -Uri "$baseUrl/resident/elections?resident_id=$residentId" -Method GET
    Write-Host "✅ Final elections check completed" -ForegroundColor Green
    
    # Check if published election is now gone
    $remainingPublishedElections = $finalElectionsResponse.elections | Where-Object { $_.status -eq "published" -and $_.id -eq $electionId }
    if ($remainingPublishedElections.Count -eq 0) {
        Write-Host "✅ SUCCESS: Election correctly removed after acknowledge!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Election still visible after acknowledge" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Failed to verify final state: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "" -ForegroundColor White
Write-Host "🎉 Test completed! The OK button should now work properly:" -ForegroundColor Green
Write-Host "   1. Published elections appear with blue highlighting" -ForegroundColor White
Write-Host "   2. Results dialog shows OK button for published elections" -ForegroundColor White
Write-Host "   3. Clicking OK acknowledges and removes the election" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "📱 Now test in the Flutter app:" -ForegroundColor Cyan
Write-Host "   - Open Resident Dashboard → Voting" -ForegroundColor White
Write-Host "   - Look for elections with 'Results Available' badge" -ForegroundColor White
Write-Host "   - Click to view results" -ForegroundColor White
Write-Host "   - Verify OK button is visible and functional" -ForegroundColor White 
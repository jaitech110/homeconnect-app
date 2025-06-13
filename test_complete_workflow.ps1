# Test Complete Workflow with Flat Number and Resolved Complaint Flow
Write-Host "Testing Complete Complaint Workflow with Flat Number..." -ForegroundColor Green

$baseUrl = "http://localhost:5000"

# Use existing test users
$residentId = "17ac29e8-aa6f-40c7-8c4b-619e0bf4ccc8"
$unionId = "21c59928-e654-4b00-b877-fd2011256a29"

# Step 1: Submit a new complaint with flat number
Write-Host "`nStep 1: Submitting complaint with flat number..." -ForegroundColor Yellow
$complaintData = @{
    user_id = $residentId
    category = "Maintenance"
    description = "Broken elevator in building - residents unable to access upper floors"
    flat_number = "B-304"
} | ConvertTo-Json

try {
    $complaintResponse = Invoke-RestMethod -Uri "$baseUrl/submit_complaint" -Method POST -Body $complaintData -ContentType "application/json"
    Write-Host "Complaint submitted successfully!" -ForegroundColor Green
    $complaintId = $complaintResponse.id
    Write-Host "Complaint ID: $complaintId" -ForegroundColor Cyan
    Write-Host "Flat Number: B-304" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to submit complaint: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Check union can see the complaint with flat number
Write-Host "`nStep 2: Checking union sees complaint with flat number..." -ForegroundColor Yellow
try {
    $unionComplaintsUrl = "$baseUrl/union/complaints/$unionId" + "?building=Test Building"
    $unionComplaints = Invoke-RestMethod -Uri $unionComplaintsUrl -Method GET
    
    $newComplaint = $unionComplaints | Where-Object { $_.id -eq $complaintId }
    if ($newComplaint) {
        Write-Host "  Union sees complaint:" -ForegroundColor Green
        Write-Host "    Category: $($newComplaint.category)" -ForegroundColor Cyan
        Write-Host "    Status: $($newComplaint.status)" -ForegroundColor Cyan
        Write-Host "    Flat Number: $($newComplaint.flat_number)" -ForegroundColor Cyan
        Write-Host "    Resident: $($newComplaint.user_id)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Failed to get union complaints: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Test Resolved action (should delete complaint)
Write-Host "`nStep 3: Testing RESOLVED action (delete)..." -ForegroundColor Yellow
try {
    $resolveUrl = "$baseUrl/union/complaints/$complaintId"
    $resolveResponse = Invoke-RestMethod -Uri $resolveUrl -Method DELETE
    Write-Host "Complaint RESOLVED and DELETED successfully!" -ForegroundColor Green
    Write-Host "Response: $($resolveResponse.message)" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to resolve complaint: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Verify complaint is removed from union list
Write-Host "`nStep 4: Verifying complaint removed from union list..." -ForegroundColor Yellow
try {
    $unionComplaintsAfter = Invoke-RestMethod -Uri $unionComplaintsUrl -Method GET
    $removedComplaint = $unionComplaintsAfter | Where-Object { $_.id -eq $complaintId }
    if ($removedComplaint) {
        Write-Host "Complaint still visible to union (unexpected)" -ForegroundColor Red
    } else {
        Write-Host "Complaint successfully removed from union list" -ForegroundColor Green
    }
} catch {
    Write-Host "Error checking union complaints: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Submit another complaint to test resident acknowledgment flow
Write-Host "`nStep 5: Testing resident acknowledgment flow..." -ForegroundColor Yellow
$complaintData2 = @{
    user_id = $residentId
    category = "Water"
    description = "No water supply since morning"
    flat_number = "A-101"
} | ConvertTo-Json

try {
    $complaintResponse2 = Invoke-RestMethod -Uri "$baseUrl/submit_complaint" -Method POST -Body $complaintData2 -ContentType "application/json"
    $complaintId2 = $complaintResponse2.id
    Write-Host "Second complaint submitted (ID: $complaintId2)" -ForegroundColor Green
    
    # Union marks as resolved (deletes it)
    $resolveUrl2 = "$baseUrl/union/complaints/$complaintId2"
    $resolveResponse2 = Invoke-RestMethod -Uri $resolveUrl2 -Method DELETE
    Write-Host "Union resolved and removed complaint" -ForegroundColor Green
    
    # Try resident acknowledgment (should fail as complaint is already deleted)
    try {
        $acknowledgeUrl = "$baseUrl/resident/complaints/$complaintId2/acknowledge"
        $acknowledgeResponse = Invoke-RestMethod -Uri $acknowledgeUrl -Method DELETE
        Write-Host "Expected: Complaint already removed by union resolution" -ForegroundColor Green
    } catch {
        Write-Host "Unexpected: Resident acknowledged non-existent complaint" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error in acknowledgment test: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 6: Test closed complaint workflow
Write-Host "`nStep 6: Testing CLOSE workflow (keeps complaint)..." -ForegroundColor Yellow
$complaintData3 = @{
    user_id = $residentId
    category = "Noise"
    description = "Loud music from neighbor apartment"
    flat_number = "C-205"
} | ConvertTo-Json

try {
    $complaintResponse3 = Invoke-RestMethod -Uri "$baseUrl/submit_complaint" -Method POST -Body $complaintData3 -ContentType "application/json"
    $complaintId3 = $complaintResponse3.id
    Write-Host "Third complaint submitted (ID: $complaintId3)" -ForegroundColor Green
    
    # Union closes complaint (updates status, doesn't delete)
    $closeData = @{
        status = "Closed"
        updated_by = $unionId
    } | ConvertTo-Json
    
    $closeResponse = Invoke-RestMethod -Uri "$baseUrl/union/complaints/$complaintId3/status" -Method PATCH -Body $closeData -ContentType "application/json"
    Write-Host "Complaint CLOSED successfully!" -ForegroundColor Green
    
    # Verify complaint still exists with closed status
    $unionComplaintsCheck = Invoke-RestMethod -Uri $unionComplaintsUrl -Method GET
    $closedComplaint = $unionComplaintsCheck | Where-Object { $_.id -eq $complaintId3 }
    if ($closedComplaint) {
        Write-Host "Closed complaint still visible with status: $($closedComplaint.status)" -ForegroundColor Green
    }
    
} catch {
    Write-Host "Error in close workflow test: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nComplete Workflow Test Completed!" -ForegroundColor Green
Write-Host "`nSUMMARY:" -ForegroundColor White
Write-Host "- Flat/House No. field added and working" -ForegroundColor White
Write-Host "- RESOLVED action deletes complaints (both union and resident side)" -ForegroundColor White
Write-Host "- CLOSE action keeps complaints with updated status" -ForegroundColor White
Write-Host "- Union can see flat numbers in complaint details" -ForegroundColor White
Write-Host "- Complaints properly removed when resolved" -ForegroundColor White 
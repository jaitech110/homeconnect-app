# Test New Resolved Complaint Workflow
Write-Host "Testing New Resolved Complaint Workflow..." -ForegroundColor Green

$baseUrl = "http://localhost:5000"

# Use existing test users
$residentId = "17ac29e8-aa6f-40c7-8c4b-619e0bf4ccc8"
$unionId = "21c59928-e654-4b00-b877-fd2011256a29"

# Step 1: Submit a new complaint with flat number
Write-Host "`nStep 1: Submitting complaint with flat number..." -ForegroundColor Yellow
$complaintData = @{
    user_id = $residentId
    category = "Maintenance"
    description = "Air conditioning not working in apartment"
    flat_number = "A-301"
} | ConvertTo-Json

try {
    $complaintResponse = Invoke-RestMethod -Uri "$baseUrl/submit_complaint" -Method POST -Body $complaintData -ContentType "application/json"
    Write-Host "Complaint submitted successfully!" -ForegroundColor Green
    $complaintId = $complaintResponse.id
    Write-Host "Complaint ID: $complaintId" -ForegroundColor Cyan
    Write-Host "Flat Number: A-301" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to submit complaint: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Check union can see the complaint
Write-Host "`nStep 2: Union sees pending complaint..." -ForegroundColor Yellow
try {
    $unionComplaintsUrl = "$baseUrl/union/complaints/$unionId" + "?building=Test Building"
    $unionComplaints = Invoke-RestMethod -Uri $unionComplaintsUrl -Method GET
    
    $newComplaint = $unionComplaints | Where-Object { $_.id -eq $complaintId }
    if ($newComplaint) {
        Write-Host "  Union sees complaint:" -ForegroundColor Green
        Write-Host "    Category: $($newComplaint.category)" -ForegroundColor Cyan
        Write-Host "    Status: $($newComplaint.status)" -ForegroundColor Cyan
        Write-Host "    Flat Number: $($newComplaint.flat_number)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Failed to get union complaints: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Union marks complaint as RESOLVED (updates status, doesn't delete)
Write-Host "`nStep 3: Union marks complaint as RESOLVED..." -ForegroundColor Yellow
try {
    $resolveData = @{
        status = "Resolved"
        updated_by = $unionId
    } | ConvertTo-Json
    
    $resolveResponse = Invoke-RestMethod -Uri "$baseUrl/union/complaints/$complaintId/status" -Method PATCH -Body $resolveData -ContentType "application/json"
    Write-Host "Complaint marked as RESOLVED!" -ForegroundColor Green
    Write-Host "Response: $($resolveResponse.message)" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to resolve complaint: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Verify complaint disappears from union list
Write-Host "`nStep 4: Verifying complaint disappeared from union list..." -ForegroundColor Yellow
try {
    $unionComplaintsAfter = Invoke-RestMethod -Uri $unionComplaintsUrl -Method GET
    $resolvedComplaint = $unionComplaintsAfter | Where-Object { $_.id -eq $complaintId }
    if ($resolvedComplaint) {
        Write-Host "ERROR: Complaint still visible to union (should be hidden)" -ForegroundColor Red
    } else {
        Write-Host "SUCCESS: Complaint hidden from union view" -ForegroundColor Green
    }
} catch {
    Write-Host "Error checking union complaints: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Verify resident can see resolved complaint
Write-Host "`nStep 5: Checking resident can see RESOLVED complaint..." -ForegroundColor Yellow
try {
    $residentComplaintsUrl = "$baseUrl/resident/complaints/$residentId"
    $residentComplaints = Invoke-RestMethod -Uri $residentComplaintsUrl -Method GET
    
    $resolvedComplaint = $residentComplaints | Where-Object { $_.id -eq $complaintId }
    if ($resolvedComplaint -and $resolvedComplaint.status -eq "Resolved") {
        Write-Host "SUCCESS: Resident sees RESOLVED complaint" -ForegroundColor Green
        Write-Host "    Status: $($resolvedComplaint.status)" -ForegroundColor Cyan
        Write-Host "    Category: $($resolvedComplaint.category)" -ForegroundColor Cyan
    } else {
        Write-Host "ERROR: Resident cannot see resolved complaint" -ForegroundColor Red
    }
} catch {
    Write-Host "Error checking resident complaints: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 6: Resident acknowledges resolved complaint (removes it)
Write-Host "`nStep 6: Resident acknowledges resolved complaint..." -ForegroundColor Yellow
try {
    $acknowledgeUrl = "$baseUrl/resident/complaints/$complaintId/acknowledge"
    $acknowledgeResponse = Invoke-RestMethod -Uri $acknowledgeUrl -Method DELETE
    Write-Host "SUCCESS: Resident acknowledged resolved complaint!" -ForegroundColor Green
    Write-Host "Response: $($acknowledgeResponse.message)" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to acknowledge complaint: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 7: Verify complaint is completely removed
Write-Host "`nStep 7: Verifying complaint is completely removed..." -ForegroundColor Yellow
try {
    $residentComplaintsFinal = Invoke-RestMethod -Uri $residentComplaintsUrl -Method GET
    $removedComplaint = $residentComplaintsFinal | Where-Object { $_.id -eq $complaintId }
    if ($removedComplaint) {
        Write-Host "ERROR: Complaint still visible to resident" -ForegroundColor Red
    } else {
        Write-Host "SUCCESS: Complaint completely removed from system" -ForegroundColor Green
    }
} catch {
    Write-Host "Error in final check: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nNew Resolved Workflow Test Completed!" -ForegroundColor Green
Write-Host "`nSUMMARY:" -ForegroundColor White
Write-Host "1. Union clicks 'Resolved' -> Complaint disappears from union view" -ForegroundColor White
Write-Host "2. Resident sees 'Resolved' status -> Can click on it" -ForegroundColor White
Write-Host "3. Resident clicks 'Okay' -> Complaint completely removed" -ForegroundColor White
Write-Host "4. Flat/House numbers properly displayed to union" -ForegroundColor White 
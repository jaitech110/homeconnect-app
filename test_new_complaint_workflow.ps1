# Test New Complaint Workflow - Close vs Resolved
Write-Host "Testing New Complaint Workflow..." -ForegroundColor Green

$baseUrl = "http://localhost:5000"

# Use existing test users from previous test
$residentId = "17ac29e8-aa6f-40c7-8c4b-619e0bf4ccc8"
$unionId = "21c59928-e654-4b00-b877-fd2011256a29"

# Step 1: Submit a new complaint
Write-Host "`nStep 1: Submitting new complaint..." -ForegroundColor Yellow
$complaintData = @{
    user_id = $residentId
    category = "Electricity"
    description = "Electricity keeps going out in the hallway. This is a safety issue that needs immediate attention."
} | ConvertTo-Json

try {
    $complaintResponse = Invoke-RestMethod -Uri "$baseUrl/submit_complaint" -Method POST -Body $complaintData -ContentType "application/json"
    Write-Host "New complaint submitted successfully!" -ForegroundColor Green
    $complaintId = $complaintResponse.id
    Write-Host "Complaint ID: $complaintId" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to submit complaint: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Check complaint appears for union
Write-Host "`nStep 2: Checking union can see the complaint..." -ForegroundColor Yellow
try {
    $unionComplaintsUrl = "$baseUrl/union/complaints/$unionId" + "?building=Test Building"
    $unionComplaints = Invoke-RestMethod -Uri $unionComplaintsUrl -Method GET
    Write-Host "Union can see $($unionComplaints.Count) complaints" -ForegroundColor Green
    
    $newComplaint = $unionComplaints | Where-Object { $_.id -eq $complaintId }
    if ($newComplaint) {
        Write-Host "  New complaint visible to union with status: $($newComplaint.status)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Failed to get union complaints: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Test Close action
Write-Host "`nStep 3: Testing CLOSE action..." -ForegroundColor Yellow
try {
    $closeData = @{
        status = "Closed"
        updated_by = $unionId
    } | ConvertTo-Json
    
    $closeResponse = Invoke-RestMethod -Uri "$baseUrl/union/complaints/$complaintId/status" -Method PATCH -Body $closeData -ContentType "application/json"
    Write-Host "Complaint CLOSED successfully!" -ForegroundColor Green
    Write-Host "Response: $($closeResponse.message)" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to close complaint: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Check resident can see closed status
Write-Host "`nStep 4: Checking resident sees CLOSED status..." -ForegroundColor Yellow
try {
    $residentComplaints = Invoke-RestMethod -Uri "$baseUrl/resident/complaints/$residentId" -Method GET
    $closedComplaint = $residentComplaints | Where-Object { $_.id -eq $complaintId }
    if ($closedComplaint) {
        Write-Host "Resident sees complaint status: $($closedComplaint.status)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Failed to get resident complaints: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Submit another complaint to test Resolved workflow
Write-Host "`nStep 5: Submitting second complaint to test RESOLVED workflow..." -ForegroundColor Yellow
$complaintData2 = @{
    user_id = $residentId
    category = "Parking"
    description = "Visitor parking is always full. Need better management of parking spaces."
} | ConvertTo-Json

try {
    $complaintResponse2 = Invoke-RestMethod -Uri "$baseUrl/submit_complaint" -Method POST -Body $complaintData2 -ContentType "application/json"
    Write-Host "Second complaint submitted successfully!" -ForegroundColor Green
    $complaintId2 = $complaintResponse2.id
    Write-Host "Second Complaint ID: $complaintId2" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to submit second complaint: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 6: Test Resolved action
Write-Host "`nStep 6: Testing RESOLVED action..." -ForegroundColor Yellow
try {
    $resolveData = @{
        status = "Resolved"
        updated_by = $unionId
    } | ConvertTo-Json
    
    $resolveResponse = Invoke-RestMethod -Uri "$baseUrl/union/complaints/$complaintId2/status" -Method PATCH -Body $resolveData -ContentType "application/json"
    Write-Host "Complaint RESOLVED successfully!" -ForegroundColor Green
    Write-Host "Response: $($resolveResponse.message)" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to resolve complaint: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 7: Final check - resident sees both statuses
Write-Host "`nStep 7: Final check - resident sees both complaint statuses..." -ForegroundColor Yellow
try {
    $finalComplaints = Invoke-RestMethod -Uri "$baseUrl/resident/complaints/$residentId" -Method GET
    Write-Host "Resident's complaint summary:" -ForegroundColor Green
    
    foreach ($complaint in $finalComplaints) {
        Write-Host "  $($complaint.category): $($complaint.status)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Failed final check: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nNew Complaint Workflow Test Completed!" -ForegroundColor Green
Write-Host "`nSUMMARY:" -ForegroundColor White
Write-Host "- CLOSE keeps complaint as closed (red badge)" -ForegroundColor White
Write-Host "- RESOLVED marks complaint as actually solved (green badge)" -ForegroundColor White
Write-Host "- Both statuses are visible to residents immediately" -ForegroundColor White 
# Simple Complaint Test with User Setup
Write-Host "Testing Complaint System with User Setup..." -ForegroundColor Green

$baseUrl = "http://localhost:5000"

# Step 1: Create a test resident
Write-Host "`nStep 1: Creating test resident..." -ForegroundColor Yellow
$residentData = @{
    email = "testuser@gmail.com"
    password = "password123"
    first_name = "John"
    last_name = "Doe"
    phone = "1234567890"
    role = "resident"
    building_name = "Test Building"
    address = "123 Test Street"
    category = "Apartment"
    resident_type = "Owner"
    is_approved = $true
} | ConvertTo-Json

try {
    $residentResponse = Invoke-RestMethod -Uri "$baseUrl/signup" -Method POST -Body $residentData -ContentType "application/json"
    $residentId = $residentResponse.user_id
    Write-Host "Test resident created with ID: $residentId" -ForegroundColor Green
} catch {
    Write-Host "Resident creation failed (may already exist): $($_.Exception.Message)" -ForegroundColor Yellow
    # Try to find existing resident by email
    try {
        $loginData = @{
            email = "testuser@gmail.com"
            password = "password123"
        } | ConvertTo-Json
        $loginResponse = Invoke-RestMethod -Uri "$baseUrl/login" -Method POST -Body $loginData -ContentType "application/json"
        $residentId = $loginResponse.user.id
        Write-Host "Using existing resident with ID: $residentId" -ForegroundColor Cyan
    } catch {
        Write-Host "Could not login existing resident: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Step 2: Create a test union incharge
Write-Host "`nStep 2: Creating test union incharge..." -ForegroundColor Yellow
$unionData = @{
    email = "uniontest@gmail.com"
    password = "password123"
    first_name = "Jane"
    last_name = "Smith"
    phone = "0987654321"
    role = "union incharge"
    building_name = "Test Building"
    address = "456 Union Street"
    category = "Apartment"
    is_approved = $true
} | ConvertTo-Json

try {
    $unionResponse = Invoke-RestMethod -Uri "$baseUrl/signup" -Method POST -Body $unionData -ContentType "application/json"
    $unionId = $unionResponse.user_id
    Write-Host "Test union incharge created with ID: $unionId" -ForegroundColor Green
} catch {
    Write-Host "Union creation failed (may already exist): $($_.Exception.Message)" -ForegroundColor Yellow
    # Try to find existing union by email
    try {
        $loginData = @{
            email = "uniontest@gmail.com"
            password = "password123"
        } | ConvertTo-Json
        $loginResponse = Invoke-RestMethod -Uri "$baseUrl/login" -Method POST -Body $loginData -ContentType "application/json"
        $unionId = $loginResponse.user.id
        Write-Host "Using existing union with ID: $unionId" -ForegroundColor Cyan
    } catch {
        Write-Host "Could not login existing union: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Step 3: Submit complaint
Write-Host "`nStep 3: Submitting complaint..." -ForegroundColor Yellow
$complaintData = @{
    user_id = $residentId
    category = "Water"
    description = "Water pressure is very low in apartment 101. This issue has been ongoing for 3 days."
} | ConvertTo-Json

try {
    $complaintResponse = Invoke-RestMethod -Uri "$baseUrl/submit_complaint" -Method POST -Body $complaintData -ContentType "application/json"
    Write-Host "Complaint submitted successfully!" -ForegroundColor Green
    Write-Host "Response: $($complaintResponse | ConvertTo-Json)" -ForegroundColor Cyan
    $complaintId = $complaintResponse.id
} catch {
    Write-Host "Failed to submit complaint: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Check if complaint appears for resident
Write-Host "`nStep 4: Checking resident complaints..." -ForegroundColor Yellow
try {
    $residentComplaints = Invoke-RestMethod -Uri "$baseUrl/resident/complaints/$residentId" -Method GET
    Write-Host "Found $($residentComplaints.Count) complaints for resident" -ForegroundColor Green
    
    if ($residentComplaints.Count -gt 0) {
        $complaint = $residentComplaints[0]
        Write-Host "  Latest complaint:" -ForegroundColor Cyan
        Write-Host "    ID: $($complaint.id)" -ForegroundColor Cyan
        Write-Host "    Category: $($complaint.category)" -ForegroundColor Cyan
        Write-Host "    Status: $($complaint.status)" -ForegroundColor Cyan
        Write-Host "    Description: $($complaint.description)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Failed to get resident complaints: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Check if complaint appears for union incharge
Write-Host "`nStep 5: Checking union complaints..." -ForegroundColor Yellow
try {
    $unionComplaintsUrl = "$baseUrl/union/complaints/$unionId" + "?building=Test Building"
    $unionComplaints = Invoke-RestMethod -Uri $unionComplaintsUrl -Method GET
    Write-Host "Found $($unionComplaints.Count) complaints for union" -ForegroundColor Green
    
    if ($unionComplaints.Count -gt 0) {
        $complaint = $unionComplaints[0]
        Write-Host "  Union sees complaint:" -ForegroundColor Cyan
        Write-Host "    ID: $($complaint.id)" -ForegroundColor Cyan
        Write-Host "    Category: $($complaint.category)" -ForegroundColor Cyan
        Write-Host "    Status: $($complaint.status)" -ForegroundColor Cyan
        Write-Host "    Resident: $($complaint.user_id)" -ForegroundColor Cyan
        Write-Host "    Resident Name: $($complaint.resident_name)" -ForegroundColor Cyan
        Write-Host "    Building: $($complaint.building_name)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Failed to get union complaints: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# Step 6: Test status update
if ($complaintId) {
    Write-Host "`nStep 6: Testing status update..." -ForegroundColor Yellow
    try {
        $statusUpdateData = @{
            status = "In Progress"
            updated_by = $unionId
        } | ConvertTo-Json
        
        $updateResponse = Invoke-RestMethod -Uri "$baseUrl/union/complaints/$complaintId/status" -Method PATCH -Body $statusUpdateData -ContentType "application/json"
        Write-Host "Status updated successfully!" -ForegroundColor Green
        Write-Host "Response: $($updateResponse | ConvertTo-Json)" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to update status: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nComplaint test completed!" -ForegroundColor Green
Write-Host "`nSUMMARY:" -ForegroundColor White
Write-Host "- Resident ID: $residentId" -ForegroundColor White
Write-Host "- Union ID: $unionId" -ForegroundColor White
Write-Host "- Complaint ID: $complaintId" -ForegroundColor White
Write-Host "- Building: Test Building" -ForegroundColor White 
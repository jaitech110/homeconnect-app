# Test Complete Complaint Management System
Write-Host "🧪 Testing Complaint Management System..." -ForegroundColor Green

$baseUrl = "http://localhost:5000"
$residentId = "resident123"
$unionId = "union123"
$buildingName = "Test Building"

# Step 1: Submit a complaint as resident
Write-Host "`n📝 Step 1: Submitting complaint as resident..." -ForegroundColor Yellow
$complaintData = @{
    user_id = $residentId
    category = "Water"
    description = "Water pressure is very low in my apartment. This has been ongoing for 3 days."
} | ConvertTo-Json

try {
    $submitResponse = Invoke-RestMethod -Uri "$baseUrl/submit_complaint" -Method POST -Body $complaintData -ContentType "application/json"
    Write-Host "✅ Complaint submitted successfully" -ForegroundColor Green
    Write-Host "Response: $($submitResponse | ConvertTo-Json)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Failed to submit complaint: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Submit another complaint
Write-Host "`n📝 Step 2: Submitting second complaint..." -ForegroundColor Yellow
$complaintData2 = @{
    user_id = $residentId
    category = "Electricity"
    description = "Power outage in common areas. Street lights are not working."
} | ConvertTo-Json

try {
    $submitResponse2 = Invoke-RestMethod -Uri "$baseUrl/submit_complaint" -Method POST -Body $complaintData2 -ContentType "application/json"
    Write-Host "✅ Second complaint submitted successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to submit second complaint: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Check resident complaints
Write-Host "`n👤 Step 3: Checking resident complaints..." -ForegroundColor Yellow
try {
    $residentComplaints = Invoke-RestMethod -Uri "$baseUrl/resident/complaints/$residentId" -Method GET
    Write-Host "✅ Found $($residentComplaints.Count) complaints for resident" -ForegroundColor Green
    
    foreach ($complaint in $residentComplaints) {
        Write-Host "  📋 ID: $($complaint.id)" -ForegroundColor Cyan
        Write-Host "  📋 Category: $($complaint.category)" -ForegroundColor Cyan
        Write-Host "  📋 Status: $($complaint.status)" -ForegroundColor Cyan
        Write-Host "  📋 Description: $($complaint.description)" -ForegroundColor Cyan
        Write-Host ""
    }
} catch {
    Write-Host "❌ Failed to get resident complaints: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Check union complaints
Write-Host "`n🏢 Step 4: Checking union complaints..." -ForegroundColor Yellow
try {
    $unionComplaints = Invoke-RestMethod -Uri "$baseUrl/union/complaints/$unionId" -Method GET
    Write-Host "✅ Found $($unionComplaints.Count) complaints for union" -ForegroundColor Green
    
    if ($unionComplaints.Count -gt 0) {
        $firstComplaint = $unionComplaints[0]
        Write-Host "  📋 First complaint ID: $($firstComplaint.id)" -ForegroundColor Cyan
        Write-Host "  📋 Category: $($firstComplaint.category)" -ForegroundColor Cyan
        Write-Host "  📋 Status: $($firstComplaint.status)" -ForegroundColor Cyan
        
        # Step 5: Update complaint status
        Write-Host "`n🔄 Step 5: Updating complaint status to 'In Progress'..." -ForegroundColor Yellow
        $statusUpdateData = @{
            status = "In Progress"
            updated_by = $unionId
        } | ConvertTo-Json
        
        try {
            $updateResponse = Invoke-RestMethod -Uri "$baseUrl/union/complaints/$($firstComplaint.id)/status" -Method PATCH -Body $statusUpdateData -ContentType "application/json"
            Write-Host "✅ Status updated successfully" -ForegroundColor Green
            Write-Host "Response: $($updateResponse | ConvertTo-Json)" -ForegroundColor Cyan
        } catch {
            Write-Host "❌ Failed to update status: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Step 6: Update to resolved
        Write-Host "`n✅ Step 6: Marking complaint as resolved..." -ForegroundColor Yellow
        $resolveData = @{
            status = "Resolved"
            updated_by = $unionId
        } | ConvertTo-Json
        
        try {
            $resolveResponse = Invoke-RestMethod -Uri "$baseUrl/union/complaints/$($firstComplaint.id)/status" -Method PATCH -Body $resolveData -ContentType "application/json"
            Write-Host "✅ Complaint marked as resolved" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to resolve complaint: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ Failed to get union complaints: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 7: Final check - verify updates
Write-Host "`n🔍 Step 7: Final verification..." -ForegroundColor Yellow
try {
    $finalCheck = Invoke-RestMethod -Uri "$baseUrl/resident/complaints/$residentId" -Method GET
    Write-Host "✅ Final status check:" -ForegroundColor Green
    
    foreach ($complaint in $finalCheck) {
        Write-Host "  📋 $($complaint.category): $($complaint.status)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Failed final check: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 Complaint system test completed!" -ForegroundColor Green
Write-Host "`n📱 Now test in Flutter app:" -ForegroundColor White
Write-Host "1. Open Resident Dashboard → Complaints" -ForegroundColor White
Write-Host "2. Submit a new complaint" -ForegroundColor White
Write-Host "3. Open Union Dashboard → Complaints & Issues" -ForegroundColor White
Write-Host "4. View and manage complaints" -ForegroundColor White 
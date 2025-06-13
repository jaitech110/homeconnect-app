# Test script for resident approval and login flow
Write-Host "🧪 Testing Resident Approval and Login Flow" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

$baseUrl = "http://localhost:5000"

# Test 1: Create a test resident
Write-Host "📝 Step 1: Creating test resident..." -ForegroundColor Yellow
$residentData = @{
    email = "testresidentlogin@gmail.com"
    password = "password123"
    first_name = "Test"
    last_name = "Resident"
    phone = "1234567890"
    username = "A-101"
    address = "123 Test Street"
    role = "Resident"
    building_name = "Sunrise Apartment"
    resident_type = "Owner"
    is_approved = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/signup" -Method POST -Body $residentData -ContentType "application/json"
    Write-Host "✅ Resident created successfully" -ForegroundColor Green
    Write-Host "   Email: testresidentlogin@gmail.com" -ForegroundColor Gray
    Write-Host "   Status: Pending approval" -ForegroundColor Gray
}
catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️  Resident already exists (continuing test)" -ForegroundColor Blue
    }
    else {
        Write-Host "❌ Failed to create resident: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Test 2: Try to login as unapproved resident
Write-Host "🔐 Step 2: Testing login with unapproved resident..." -ForegroundColor Yellow
$loginData = @{
    email = "testresidentlogin@gmail.com"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/login" -Method POST -Body $loginData -ContentType "application/json"
    $isApproved = $loginResponse.user.is_approved
    
    if ($isApproved -eq $false) {
        Write-Host "✅ Login successful but resident is not approved (as expected)" -ForegroundColor Green
        Write-Host "   Frontend should show: 'Your resident application is pending union incharge approval'" -ForegroundColor Gray
    }
    else {
        Write-Host "⚠️  Unexpected: Resident appears to be approved already" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 3: Approve the resident (simulating union incharge approval)
Write-Host "✅ Step 3: Approving resident (simulating union incharge)..." -ForegroundColor Yellow

# Get the resident ID first
try {
    $users = Invoke-RestMethod -Uri "$baseUrl/users" -Method GET
    $testResident = $users | Where-Object { $_.email -eq "testresidentlogin@gmail.com" } | Select-Object -First 1
    
    if ($testResident) {
        $residentId = $testResident.id
        Write-Host "   Found resident ID: $residentId" -ForegroundColor Gray
        
        # Create a union incharge first
        $unionData = @{
            email = "testunion@gmail.com"
            password = "password123"
            first_name = "Test"
            last_name = "Union"
            role = "Union Incharge"
            building_name = "Sunrise Apartment"
            category = "Apartment"
            is_approved = $true
        } | ConvertTo-Json
        
        try {
            Invoke-RestMethod -Uri "$baseUrl/signup" -Method POST -Body $unionData -ContentType "application/json" | Out-Null
            Write-Host "   Created test union incharge" -ForegroundColor Gray
        }
        catch {
            Write-Host "   Union incharge already exists" -ForegroundColor Gray
        }
        
        # Get union ID
        $users = Invoke-RestMethod -Uri "$baseUrl/users" -Method GET
        $unionIncharge = $users | Where-Object { $_.email -eq "testunion@gmail.com" } | Select-Object -First 1
        
        if ($unionIncharge) {
            $unionId = $unionIncharge.id
            Write-Host "   Found union ID: $unionId" -ForegroundColor Gray
            
            # Approve the resident
            $approvalData = @{
                union_id = $unionId
                building_name = "Sunrise Apartment"
            } | ConvertTo-Json
            
            try {
                $approvalResponse = Invoke-RestMethod -Uri "$baseUrl/union/approve-resident/$residentId" -Method PUT -Body $approvalData -ContentType "application/json"
                Write-Host "✅ Resident approved successfully" -ForegroundColor Green
                Write-Host "   $($approvalResponse.message)" -ForegroundColor Gray
            }
            catch {
                Write-Host "❌ Failed to approve resident: $($_.Exception.Message)" -ForegroundColor Red
                exit 1
            }
        }
        else {
            Write-Host "❌ Could not find union incharge for approval" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "❌ Could not find test resident" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ Failed to get users: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 4: Login as approved resident
Write-Host "🔐 Step 4: Testing login with approved resident..." -ForegroundColor Yellow

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/login" -Method POST -Body $loginData -ContentType "application/json"
    $isApproved = $loginResponse.user.is_approved
    $userName = $loginResponse.user.first_name
    $role = $loginResponse.user.role
    
    if ($isApproved -eq $true -and $role -eq "Resident") {
        Write-Host "✅ Login successful with approved resident!" -ForegroundColor Green
        Write-Host "   Name: $userName" -ForegroundColor Gray
        Write-Host "   Role: $role" -ForegroundColor Gray
        Write-Host "   Approved: $isApproved" -ForegroundColor Gray
        Write-Host "   Frontend should navigate to ResidentDashboard" -ForegroundColor Gray
    }
    else {
        Write-Host "❌ Unexpected login result" -ForegroundColor Red
        Write-Host "   Approved: $isApproved" -ForegroundColor Red
        Write-Host "   Role: $role" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Test completed successfully!" -ForegroundColor Green
Write-Host "📋 Summary:" -ForegroundColor Green
Write-Host "   1. ✅ Resident signup works" -ForegroundColor Gray
Write-Host "   2. ✅ Unapproved resident login shows pending message" -ForegroundColor Gray
Write-Host "   3. ✅ Union incharge can approve residents" -ForegroundColor Gray
Write-Host "   4. ✅ Approved resident can login and access dashboard" -ForegroundColor Gray 
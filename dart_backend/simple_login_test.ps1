Write-Host "🧪 Testing Resident Login Flow" -ForegroundColor Green
Write-Host ""

$baseUrl = "http://localhost:5000"

# Test 1: Create test resident
Write-Host "📝 Creating test resident..." -ForegroundColor Yellow
$residentData = @{
    email = "testlogin@gmail.com"
    password = "password123"
    first_name = "Login"
    last_name = "Test"
    phone = "1234567890"
    username = "A-101"
    address = "123 Test Street"
    role = "Resident"
    building_name = "Sunrise Apartment"
    resident_type = "Owner"
    is_approved = $false
} | ConvertTo-Json

$createResponse = Invoke-RestMethod -Uri "$baseUrl/signup" -Method POST -Body $residentData -ContentType "application/json" -ErrorAction SilentlyContinue
if ($createResponse) {
    Write-Host "✅ Resident created" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Resident may already exist" -ForegroundColor Blue
}

# Test 2: Login as unapproved resident
Write-Host ""
Write-Host "🔐 Testing login with unapproved resident..." -ForegroundColor Yellow
$loginData = @{
    email = "testlogin@gmail.com"
    password = "password123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/login" -Method POST -Body $loginData -ContentType "application/json"
$isApproved = $loginResponse.user.is_approved

if ($isApproved -eq $false) {
    Write-Host "✅ Unapproved resident login works (should show pending message)" -ForegroundColor Green
} else {
    Write-Host "⚠️  Resident is already approved" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Login Response Details:" -ForegroundColor Green
Write-Host "   Name: $($loginResponse.user.first_name) $($loginResponse.user.last_name)" -ForegroundColor Gray
Write-Host "   Email: $($loginResponse.user.email)" -ForegroundColor Gray
Write-Host "   Role: $($loginResponse.user.role)" -ForegroundColor Gray
Write-Host "   Approved: $($loginResponse.user.is_approved)" -ForegroundColor Gray

Write-Host ""
Write-Host "✅ Test completed! Frontend should:" -ForegroundColor Green
if ($isApproved -eq $false) {
    Write-Host "   - Show pending approval message" -ForegroundColor Yellow
    Write-Host "   - NOT navigate to ResidentDashboard" -ForegroundColor Yellow
} else {
    Write-Host "   - Navigate to ResidentDashboard" -ForegroundColor Green
} 
# Kheti Sahayak - Application Status Checker

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🌾 KHETI SAHAYAK - STATUS CHECK" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

# Check Frontend
Write-Host "🌐 Frontend (React):" -ForegroundColor Cyan
try {
    $frontend = Invoke-WebRequest -Uri "http://localhost:3001" -UseBasicParsing -TimeoutSec 3
    Write-Host "   ✅ RUNNING on http://localhost:3001" -ForegroundColor Green
    $frontendOk = $true
} catch {
    Write-Host "   ❌ NOT RUNNING" -ForegroundColor Red
    Write-Host "   Start with: cd frontend; npm run dev" -ForegroundColor Yellow
    $frontendOk = $false
}

Write-Host ""

# Check Backend
Write-Host "🔧 Backend (Spring Boot):" -ForegroundColor Cyan
try {
    $backend = Invoke-WebRequest -Uri "http://localhost:8080/api/health" -UseBasicParsing -TimeoutSec 3
    Write-Host "   ✅ RUNNING on http://localhost:8080" -ForegroundColor Green
    Write-Host "   Response: $($backend.StatusCode) $($backend.StatusDescription)" -ForegroundColor Gray
    $backendOk = $true
} catch {
    Write-Host "   ❌ NOT RUNNING or still starting" -ForegroundColor Red
    Write-Host "   Start with: cd kheti_sahayak_spring_boot; ./mvnw spring-boot:run" -ForegroundColor Yellow
    Write-Host "   (Requires JAVA_HOME to be set)" -ForegroundColor Yellow
    $backendOk = $false
}

Write-Host ""

# Check Swagger Docs
if ($backendOk) {
    Write-Host "📚 API Documentation:" -ForegroundColor Cyan
    try {
        $docs = Invoke-WebRequest -Uri "http://localhost:8080/api-docs" -UseBasicParsing -TimeoutSec 3
        Write-Host "   ✅ AVAILABLE at http://localhost:8080/api-docs" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Swagger UI may still be loading" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "📊 SUMMARY" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

if ($frontendOk -and $backendOk) {
    Write-Host "✅ APPLICATION FULLY OPERATIONAL!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access your application:" -ForegroundColor Cyan
    Write-Host "  • Main App:  http://localhost:3001" -ForegroundColor White
    Write-Host "  • API Docs:  http://localhost:8080/api-docs" -ForegroundColor White
    Write-Host ""
    Write-Host "Would you like to open in browser? (Y/N)" -ForegroundColor Yellow
    $answer = Read-Host
    if ($answer -eq "Y" -or $answer -eq "y") {
        Start-Process "http://localhost:3001"
        Start-Sleep -Seconds 1
        Start-Process "http://localhost:8080/api-docs"
        Write-Host "✅ Opened in browser!" -ForegroundColor Green
    }
} elseif ($frontendOk) {
    Write-Host "⚠️  FRONTEND RUNNING, BACKEND STARTING" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Frontend is ready: http://localhost:3001" -ForegroundColor Green
    Write-Host "Backend is still starting (can take 30-60 seconds)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run this script again in 30 seconds to check backend status" -ForegroundColor Cyan
} else {
    Write-Host "❌ SERVICES NOT RUNNING" -ForegroundColor Red
    Write-Host ""
    Write-Host "Start the application with:" -ForegroundColor Yellow
    Write-Host "  ./start-application.ps1" -ForegroundColor White
    Write-Host ""
}

Write-Host ""


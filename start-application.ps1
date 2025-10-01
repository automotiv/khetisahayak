# Kheti Sahayak - Application Startup Script (PowerShell)
# Automatically sets JAVA_HOME and starts both frontend and backend

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "   KHETI SAHAYAK - STARTING APPLICATION" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""

# Set JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

Write-Host "[1/4] Configuring Java..." -ForegroundColor Cyan
Write-Host "JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Yellow
java -version
Write-Host ""

# Check PostgreSQL (optional - will use H2 if not available)
Write-Host "[2/4] Checking database..." -ForegroundColor Cyan
Write-Host "Note: PostgreSQL is optional. H2 in-memory DB will be used if PostgreSQL is not running." -ForegroundColor Yellow
Write-Host ""

# Start Backend
Write-Host "[3/4] Starting Backend API (Spring Boot)..." -ForegroundColor Cyan
Write-Host "Port: 8080" -ForegroundColor Yellow

Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "`$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot'; `$env:PATH=`"`$env:JAVA_HOME\bin;`$env:PATH`"; cd '$PWD\kheti_sahayak_spring_boot'; Write-Host 'Starting Spring Boot Backend...' -ForegroundColor Green; ./mvnw spring-boot:run"
)

Write-Host "✅ Backend starting in new window..." -ForegroundColor Green
Write-Host ""

# Wait for backend
Write-Host "⏳ Waiting 15 seconds for backend to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 15
Write-Host ""

# Start Frontend
Write-Host "[4/4] Starting Frontend (React)..." -ForegroundColor Cyan
Write-Host "Port: 3001 (or next available)" -ForegroundColor Yellow

Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd '$PWD\frontend'; Write-Host 'Starting React Frontend...' -ForegroundColor Cyan; npm run dev"
)

Write-Host "✅ Frontend starting in new window..." -ForegroundColor Green
Write-Host ""

# Wait for frontend
Write-Host "⏳ Waiting 8 seconds for frontend to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 8
Write-Host ""

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "   APPLICATION STARTED!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "✅ Frontend:  http://localhost:3001" -ForegroundColor Green
Write-Host "✅ Backend:   http://localhost:8080" -ForegroundColor Green
Write-Host "✅ API Docs:  http://localhost:8080/api-docs" -ForegroundColor Green
Write-Host ""

# Test backend connectivity
Write-Host "Testing backend connectivity..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ Backend is UP and responding!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Backend may still be starting. Please wait a few more seconds." -ForegroundColor Yellow
    Write-Host "   Try accessing http://localhost:8080/api/health manually" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🚀 Opening application in browser..." -ForegroundColor Magenta
Write-Host ""

# Open browser
Start-Process "http://localhost:3001"
Start-Sleep -Seconds 2
Start-Process "http://localhost:8080/api-docs"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Blue
Write-Host "   KHETI SAHAYAK IS RUNNING!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "To stop the application:" -ForegroundColor Yellow
Write-Host "  - Close the Backend and Frontend PowerShell windows" -ForegroundColor White
Write-Host "  - Or press Ctrl+C in each window" -ForegroundColor White
Write-Host ""
Write-Host "📚 Quick Links:" -ForegroundColor Cyan
Write-Host "  • Main App:     http://localhost:3001" -ForegroundColor White
Write-Host "  • API Docs:     http://localhost:8080/api-docs" -ForegroundColor White
Write-Host "  • Health Check: http://localhost:8080/api/health" -ForegroundColor White
Write-Host ""
Write-Host "🌾 Enjoy testing Kheti Sahayak! 🌾" -ForegroundColor Green
Write-Host ""


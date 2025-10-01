@echo off
REM Kheti Sahayak - Application Startup Script
REM Automatically sets JAVA_HOME and starts both frontend and backend

echo ================================================================
echo   KHETI SAHAYAK - STARTING APPLICATION
echo ================================================================
echo.

REM Set JAVA_HOME
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot
set PATH=%JAVA_HOME%\bin;%PATH%

echo [1/4] Configuring Java...
echo JAVA_HOME: %JAVA_HOME%
java -version
echo.

REM Check if PostgreSQL is needed
echo [2/4] Checking database...
echo Note: PostgreSQL should be running for full functionality
echo If not installed, the app will use H2 in-memory database
echo.

REM Start Backend
echo [3/4] Starting Backend API (Spring Boot)...
echo Port: 8080
start "Kheti Sahayak Backend" cmd /k "cd kheti_sahayak_spring_boot && mvnw spring-boot:run"
echo Backend starting in new window...
echo.

REM Wait a bit for backend to start
echo Waiting 10 seconds for backend to initialize...
timeout /t 10 /nobreak >nul
echo.

REM Start Frontend
echo [4/4] Starting Frontend (React)...
echo Port: 3001 (or next available)
start "Kheti Sahayak Frontend" cmd /k "cd frontend && npm run dev"
echo Frontend starting in new window...
echo.

REM Wait for frontend to start
echo Waiting 5 seconds for frontend to initialize...
timeout /t 5 /nobreak >nul
echo.

echo ================================================================
echo   APPLICATION STARTED!
echo ================================================================
echo.
echo   Frontend:  http://localhost:3001
echo   Backend:   http://localhost:8080
echo   API Docs:  http://localhost:8080/api-docs
echo.
echo Opening in browser...
echo.

REM Open browser
start http://localhost:3001
timeout /t 2 /nobreak >nul
start http://localhost:8080/api-docs

echo.
echo ================================================================
echo   KHETI SAHAYAK IS RUNNING!
echo ================================================================
echo.
echo To stop the application:
echo   - Close the Backend and Frontend command windows
echo   - Or press Ctrl+C in each window
echo.
echo Enjoy testing the application!
echo.

pause


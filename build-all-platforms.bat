@echo off
REM Kheti Sahayak - Multi-Platform Build Script for Windows
REM Builds the application for Web, Android, and Windows

setlocal enabledelayedexpansion

echo.
echo ============================================
echo   KHETI SAHAYAK - WINDOWS BUILD SCRIPT
echo ============================================
echo.
echo Building for:
echo   * Web (React ^& Flutter)
echo   * Android
echo   * Windows
echo.

REM Create output directory
if not exist "builds" mkdir builds

REM ==========================================
REM 1. BUILD WEB (React)
REM ==========================================
echo.
echo [1/5] Building Web Application (React)...
echo ----------------------------------------

if exist "frontend" (
    cd frontend
    
    if not exist "node_modules" (
        echo Installing dependencies...
        call npm install
    )
    
    echo Building React web app...
    call npm run build
    
    REM Copy to output
    xcopy /E /I /Y dist ..\builds\web-react
    echo [OK] React web build complete - builds\web-react\
    
    cd ..
) else (
    echo [SKIP] Frontend directory not found
)

REM ==========================================
REM 2. BUILD FLUTTER APPS
REM ==========================================
if exist "kheti_sahayak_app" (
    cd kheti_sahayak_app
    
    REM Get dependencies
    echo.
    echo [2/5] Installing Flutter dependencies...
    echo ----------------------------------------
    call flutter pub get
    
    REM ==========================================
    REM 2.1 BUILD ANDROID
    REM ==========================================
    echo.
    echo [3/5] Building for Android...
    echo ----------------------------------------
    
    echo Building Android APK...
    call flutter build apk --release
    copy build\app\outputs\flutter-apk\app-release.apk ..\builds\kheti-sahayak-android.apk
    echo [OK] Android APK - builds\kheti-sahayak-android.apk
    
    echo Building Android App Bundle...
    call flutter build appbundle --release
    copy build\app\outputs\bundle\release\app-release.aab ..\builds\kheti-sahayak-android.aab
    echo [OK] Android AAB - builds\kheti-sahayak-android.aab
    
    REM ==========================================
    REM 2.2 BUILD FLUTTER WEB
    REM ==========================================
    echo.
    echo [4/5] Building Flutter Web...
    echo ----------------------------------------
    
    call flutter build web --release
    xcopy /E /I /Y build\web ..\builds\web-flutter
    echo [OK] Flutter Web - builds\web-flutter\
    
    REM ==========================================
    REM 2.3 BUILD WINDOWS
    REM ==========================================
    echo.
    echo [5/5] Building for Windows...
    echo ----------------------------------------
    
    REM Enable Windows desktop
    call flutter config --enable-windows-desktop
    
    echo Building Windows app...
    call flutter build windows --release
    
    REM Copy build output
    if exist "build\windows\runner\Release" (
        xcopy /E /I /Y build\windows\runner\Release ..\builds\windows
        echo [OK] Windows App - builds\windows\
    )
    
    cd ..
) else (
    echo [ERROR] Flutter app directory not found!
    exit /b 1
)

REM ==========================================
REM BUILD SUMMARY
REM ==========================================
echo.
echo ============================================
echo   BUILD SUMMARY
echo ============================================
echo.
echo Builds completed! Check the 'builds' directory:
echo.

if exist "builds\web-react" (
    echo   [OK] Web ^(React^):     builds\web-react\
)

if exist "builds\web-flutter" (
    echo   [OK] Web ^(Flutter^):   builds\web-flutter\
)

if exist "builds\kheti-sahayak-android.apk" (
    for %%A in ("builds\kheti-sahayak-android.apk") do set SIZE=%%~zA
    echo   [OK] Android APK:     builds\kheti-sahayak-android.apk ^(!SIZE! bytes^)
)

if exist "builds\kheti-sahayak-android.aab" (
    for %%A in ("builds\kheti-sahayak-android.aab") do set SIZE=%%~zA
    echo   [OK] Android AAB:     builds\kheti-sahayak-android.aab ^(!SIZE! bytes^)
)

if exist "builds\windows" (
    echo   [OK] Windows App:     builds\windows\
)

echo.
echo ============================================
echo   SUCCESS! All builds completed
echo ============================================
echo.
echo Next steps:
echo   1. Test each build
echo   2. Deploy web builds to hosting
echo   3. Submit Android app to Play Store
echo   4. Create Windows installer ^(optional^)
echo.
echo Kheti Sahayak is ready for deployment!
echo.

pause


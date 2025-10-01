#!/bin/bash

# Kheti Sahayak - Multi-Platform Build Script
# Builds the application for Web, Android, iOS, macOS, Windows, and Linux

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🌾 $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Print header
echo ""
print_step "KHETI SAHAYAK - CROSS-PLATFORM BUILD"
echo ""
echo "Building for all supported platforms:"
echo "  🌐 Web (React & Flutter)"
echo "  🤖 Android"
echo "  🍎 iOS (macOS only)"
echo "  💻 macOS (macOS only)"
echo "  🪟 Windows (Windows only)"
echo "  🐧 Linux (Linux only)"
echo ""

# Create output directory
OUTPUT_DIR="builds"
mkdir -p $OUTPUT_DIR

# ==========================================
# 1. BUILD WEB (React)
# ==========================================
print_step "Building Web Application (React)"

if [ -d "frontend" ]; then
    cd frontend
    
    if [ ! -d "node_modules" ]; then
        print_warning "Installing dependencies..."
        npm install
    fi
    
    print_success "Building React web app..."
    npm run build
    
    # Copy to output
    cp -r dist ../builds/web-react
    print_success "React web build complete → builds/web-react/"
    
    cd ..
else
    print_warning "Frontend directory not found, skipping React web build"
fi

# ==========================================
# 2. BUILD FLUTTER APPS
# ==========================================
if [ -d "kheti_sahayak_app" ]; then
    cd kheti_sahayak_app
    
    # Get dependencies
    print_step "Installing Flutter dependencies"
    flutter pub get
    
    # ==========================================
    # 2.1 BUILD ANDROID
    # ==========================================
    print_step "Building for Android"
    
    print_success "Building Android APK (Release)..."
    flutter build apk --release
    cp build/app/outputs/flutter-apk/app-release.apk ../builds/kheti-sahayak-android.apk
    print_success "Android APK → builds/kheti-sahayak-android.apk"
    
    print_success "Building Android App Bundle (Release)..."
    flutter build appbundle --release
    cp build/app/outputs/bundle/release/app-release.aab ../builds/kheti-sahayak-android.aab
    print_success "Android AAB → builds/kheti-sahayak-android.aab"
    
    # ==========================================
    # 2.2 BUILD FLUTTER WEB
    # ==========================================
    print_step "Building Flutter Web"
    
    flutter build web --release
    cp -r build/web ../builds/web-flutter
    print_success "Flutter Web → builds/web-flutter/"
    
    # ==========================================
    # 2.3 BUILD iOS (macOS only)
    # ==========================================
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_step "Building for iOS"
        
        # Install CocoaPods dependencies
        cd ios
        pod install 2>/dev/null || print_warning "CocoaPods not installed or dependencies already installed"
        cd ..
        
        print_success "Building iOS app..."
        flutter build ios --release --no-codesign
        print_success "iOS build complete → build/ios/iphoneos/Runner.app"
        
        # Build IPA if possible
        if command -v xcodebuild &> /dev/null; then
            print_success "Building IPA..."
            flutter build ipa --release
            
            if [ -f "build/ios/ipa/kheti_sahayak_app.ipa" ]; then
                cp build/ios/ipa/kheti_sahayak_app.ipa ../builds/kheti-sahayak-ios.ipa
                print_success "iOS IPA → builds/kheti-sahayak-ios.ipa"
            fi
        else
            print_warning "Xcode not found, skipping IPA generation"
        fi
    else
        print_warning "iOS build requires macOS, skipping..."
    fi
    
    # ==========================================
    # 2.4 BUILD macOS (macOS only)
    # ==========================================
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_step "Building for macOS"
        
        # Enable macOS desktop if not already enabled
        flutter config --enable-macos-desktop >/dev/null 2>&1
        
        print_success "Building macOS app..."
        flutter build macos --release
        
        # Copy app bundle
        if [ -d "build/macos/Build/Products/Release/kheti_sahayak_app.app" ]; then
            cp -r build/macos/Build/Products/Release/kheti_sahayak_app.app ../builds/
            print_success "macOS App → builds/kheti_sahayak_app.app"
            
            # Create DMG if create-dmg is available
            if command -v create-dmg &> /dev/null; then
                print_success "Creating DMG installer..."
                cd ../builds
                create-dmg \
                  --volname "Kheti Sahayak" \
                  --window-pos 200 120 \
                  --window-size 800 400 \
                  --icon-size 100 \
                  --app-drop-link 600 185 \
                  "Kheti-Sahayak-macOS.dmg" \
                  "kheti_sahayak_app.app" 2>/dev/null || print_warning "DMG creation failed"
                cd ../kheti_sahayak_app
                print_success "macOS DMG → builds/Kheti-Sahayak-macOS.dmg"
            else
                print_warning "create-dmg not installed, skipping DMG creation (brew install create-dmg)"
            fi
        fi
    else
        print_warning "macOS build requires macOS, skipping..."
    fi
    
    # ==========================================
    # 2.5 BUILD WINDOWS (Windows only)
    # ==========================================
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        print_step "Building for Windows"
        
        # Enable Windows desktop if not already enabled
        flutter config --enable-windows-desktop
        
        print_success "Building Windows app..."
        flutter build windows --release
        
        # Copy build output
        if [ -d "build/windows/runner/Release" ]; then
            cp -r build/windows/runner/Release ../builds/windows
            print_success "Windows App → builds/windows/"
        fi
    else
        print_warning "Windows build requires Windows OS, skipping..."
    fi
    
    # ==========================================
    # 2.6 BUILD LINUX (Linux only)
    # ==========================================
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_step "Building for Linux"
        
        # Enable Linux desktop if not already enabled
        flutter config --enable-linux-desktop
        
        print_success "Building Linux app..."
        flutter build linux --release
        
        # Copy build output
        if [ -d "build/linux/x64/release/bundle" ]; then
            cp -r build/linux/x64/release/bundle ../builds/linux
            print_success "Linux App → builds/linux/"
            
            # Create AppImage if appimagetool is available
            if command -v appimagetool &> /dev/null; then
                print_success "Creating AppImage..."
                # AppImage creation logic here
                print_warning "AppImage creation requires additional setup"
            fi
        fi
    else
        print_warning "Linux build requires Linux OS, skipping..."
    fi
    
    cd ..
else
    print_error "Flutter app directory not found!"
    exit 1
fi

# ==========================================
# BUILD SUMMARY
# ==========================================
echo ""
print_step "BUILD SUMMARY"
echo ""

echo "✅ Builds completed! Check the 'builds' directory for outputs:"
echo ""

if [ -d "builds/web-react" ]; then
    echo "  🌐 Web (React):     builds/web-react/"
fi

if [ -d "builds/web-flutter" ]; then
    echo "  🌐 Web (Flutter):   builds/web-flutter/"
fi

if [ -f "builds/kheti-sahayak-android.apk" ]; then
    SIZE=$(du -h "builds/kheti-sahayak-android.apk" | cut -f1)
    echo "  🤖 Android APK:     builds/kheti-sahayak-android.apk ($SIZE)"
fi

if [ -f "builds/kheti-sahayak-android.aab" ]; then
    SIZE=$(du -h "builds/kheti-sahayak-android.aab" | cut -f1)
    echo "  🤖 Android AAB:     builds/kheti-sahayak-android.aab ($SIZE)"
fi

if [ -f "builds/kheti-sahayak-ios.ipa" ]; then
    SIZE=$(du -h "builds/kheti-sahayak-ios.ipa" | cut -f1)
    echo "  🍎 iOS IPA:         builds/kheti-sahayak-ios.ipa ($SIZE)"
fi

if [ -d "builds/kheti_sahayak_app.app" ]; then
    SIZE=$(du -sh "builds/kheti_sahayak_app.app" | cut -f1)
    echo "  💻 macOS App:       builds/kheti_sahayak_app.app ($SIZE)"
fi

if [ -f "builds/Kheti-Sahayak-macOS.dmg" ]; then
    SIZE=$(du -h "builds/Kheti-Sahayak-macOS.dmg" | cut -f1)
    echo "  💻 macOS DMG:       builds/Kheti-Sahayak-macOS.dmg ($SIZE)"
fi

if [ -d "builds/windows" ]; then
    SIZE=$(du -sh "builds/windows" | cut -f1)
    echo "  🪟 Windows App:     builds/windows/ ($SIZE)"
fi

if [ -d "builds/linux" ]; then
    SIZE=$(du -sh "builds/linux" | cut -f1)
    echo "  🐧 Linux App:       builds/linux/ ($SIZE)"
fi

echo ""
print_success "🎉 All builds completed successfully!"
echo ""
echo "Next steps:"
echo "  1. Test each build on target platforms"
echo "  2. Deploy web builds to hosting services"
echo "  3. Submit mobile apps to app stores"
echo "  4. Distribute desktop apps via installers"
echo ""
print_success "🌾 Kheti Sahayak is now ready for all platforms!"


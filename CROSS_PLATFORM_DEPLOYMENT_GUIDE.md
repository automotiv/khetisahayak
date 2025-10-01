# 🌐 Kheti Sahayak - Cross-Platform Deployment Guide

## 📱 Multi-Platform Support

Kheti Sahayak is designed to run on **ALL major platforms**:
- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Android** (Phones & Tablets)
- ✅ **iOS** (iPhone & iPad)
- ✅ **macOS** (Desktop)
- ✅ **Windows** (Desktop)
- ✅ **Linux** (Desktop)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Backend API Server                    │
│              Spring Boot (Platform Agnostic)             │
│                  Port: 8080 (REST API)                   │
└─────────────────────────────────────────────────────────┘
                            ↓
    ┌───────────────────────┼───────────────────────┐
    ↓                       ↓                       ↓
┌─────────┐          ┌──────────┐           ┌──────────┐
│   WEB   │          │  MOBILE  │           │ DESKTOP  │
│  React  │          │ Flutter  │           │ Flutter  │
├─────────┤          ├──────────┤           ├──────────┤
│ Chrome  │          │ Android  │           │ Windows  │
│ Firefox │          │   iOS    │           │  macOS   │
│ Safari  │          │          │           │  Linux   │
│  Edge   │          │          │           │          │
└─────────┘          └──────────┘           └──────────┘
```

---

## 🌐 WEB DEPLOYMENT (React)

### **Supported Browsers:**
- Chrome 88+
- Firefox 85+
- Safari 14+
- Edge 88+

### **Build for Production:**

```bash
cd frontend

# Install dependencies
npm install

# Build for production
npm run build

# Output: frontend/dist/
```

### **Deployment Options:**

#### **1. Netlify (Recommended for Web):**
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=dist
```

#### **2. Vercel:**
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

#### **3. Firebase Hosting:**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize
firebase init hosting

# Deploy
firebase deploy --only hosting
```

#### **4. Traditional Web Server (Nginx):**
```nginx
# /etc/nginx/sites-available/khetisahayak
server {
    listen 80;
    server_name khetisahayak.com;
    
    root /var/www/khetisahayak/frontend/dist;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### **Environment Configuration:**
```bash
# frontend/.env.production
VITE_API_BASE_URL=https://api.khetisahayak.com
VITE_ENVIRONMENT=production
```

---

## 📱 ANDROID DEPLOYMENT (Flutter)

### **Requirements:**
- Android Studio
- Android SDK (API level 21+)
- Java JDK 11+

### **Build APK (For Testing):**

```bash
cd kheti_sahayak_app

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### **Build App Bundle (For Play Store):**

```bash
# Build release App Bundle
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### **Signing Configuration:**

Create `android/key.properties`:
```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=khetisahayak
storeFile=<path-to-keystore-file>
```

Generate Keystore:
```bash
keytool -genkey -v -keystore kheti-sahayak-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias khetisahayak
```

### **Google Play Store Deployment:**

1. **Create Developer Account:** https://play.google.com/console
2. **Create App Listing:**
   - App name: Kheti Sahayak
   - Category: Agriculture
   - Target audience: Farmers in India
3. **Upload App Bundle:** Upload the `.aab` file
4. **Complete Store Listing:**
   - Screenshots (Phone & Tablet)
   - Feature graphic
   - App icon
   - Privacy policy
5. **Submit for Review**

### **Configuration:**

Update `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        applicationId "com.khetisahayak.app"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
}
```

---

## 🍎 iOS DEPLOYMENT (Flutter)

### **Requirements:**
- macOS computer
- Xcode 14+
- Apple Developer Account ($99/year)

### **Build for iOS:**

```bash
cd kheti_sahayak_app

# Install iOS dependencies
cd ios && pod install && cd ..

# Build iOS app (requires macOS & Xcode)
flutter build ios --release

# Build IPA for distribution
flutter build ipa --release

# Output: build/ios/ipa/kheti_sahayak_app.ipa
```

### **App Store Deployment:**

1. **Apple Developer Program:**
   - Enroll at: https://developer.apple.com/programs/
   - Create App ID: `com.khetisahayak.app`
   - Create Provisioning Profiles

2. **Xcode Configuration:**
   ```bash
   # Open Xcode project
   open ios/Runner.xcworkspace
   
   # In Xcode:
   # - Set Team and Signing
   # - Set Bundle Identifier
   # - Configure capabilities
   ```

3. **Archive & Upload:**
   - In Xcode: Product → Archive
   - Distribute App → App Store Connect
   - Upload to TestFlight for beta testing
   - Submit for App Store review

### **Configuration:**

Update `ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Kheti Sahayak</string>
<key>CFBundleIdentifier</key>
<string>com.khetisahayak.app</string>
<key>CFBundleVersion</key>
<string>1.0.0</string>
```

---

## 💻 MACOS DEPLOYMENT (Flutter Desktop)

### **Requirements:**
- macOS 10.14+
- Xcode 14+

### **Enable macOS Support:**

```bash
cd kheti_sahayak_app

# Enable macOS desktop support
flutter config --enable-macos-desktop

# Create macOS project files
flutter create --platforms=macos .
```

### **Build for macOS:**

```bash
# Build macOS app
flutter build macos --release

# Output: build/macos/Build/Products/Release/kheti_sahayak_app.app
```

### **Create DMG Installer:**

```bash
# Install create-dmg
brew install create-dmg

# Create DMG
create-dmg \
  --volname "Kheti Sahayak Installer" \
  --volicon "assets/logo/kheti_sahayak_mark.icns" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "Kheti Sahayak.app" 200 190 \
  --hide-extension "Kheti Sahayak.app" \
  --app-drop-link 600 185 \
  "KhetiSahayak-Installer.dmg" \
  "build/macos/Build/Products/Release/"
```

### **Mac App Store Distribution:**

1. **Code Signing:**
   ```bash
   # Sign the app
   codesign --deep --force --verify --verbose \
     --sign "Developer ID Application: Your Name" \
     "build/macos/Build/Products/Release/kheti_sahayak_app.app"
   ```

2. **Notarization:**
   ```bash
   # Notarize with Apple
   xcrun altool --notarize-app \
     --primary-bundle-id "com.khetisahayak.app" \
     --username "your@apple.id" \
     --password "@keychain:AC_PASSWORD" \
     --file "KhetiSahayak-Installer.dmg"
   ```

---

## 🪟 WINDOWS DEPLOYMENT (Flutter Desktop)

### **Requirements:**
- Windows 10/11
- Visual Studio 2022 (with C++ development tools)

### **Enable Windows Support:**

```bash
cd kheti_sahayak_app

# Enable Windows desktop support
flutter config --enable-windows-desktop

# Create Windows project files
flutter create --platforms=windows .
```

### **Build for Windows:**

```bash
# Build Windows app
flutter build windows --release

# Output: build/windows/runner/Release/
```

### **Create Installer:**

#### **Option 1: Inno Setup (Recommended)**

Download Inno Setup: https://jrsoftware.org/isdl.php

Create `installer.iss`:
```iss
[Setup]
AppName=Kheti Sahayak
AppVersion=1.0.0
DefaultDirName={pf}\Kheti Sahayak
DefaultGroupName=Kheti Sahayak
OutputDir=installer
OutputBaseFilename=KhetiSahayak-Setup
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Kheti Sahayak"; Filename: "{app}\kheti_sahayak_app.exe"
Name: "{commondesktop}\Kheti Sahayak"; Filename: "{app}\kheti_sahayak_app.exe"

[Run]
Filename: "{app}\kheti_sahayak_app.exe"; Description: "Launch Kheti Sahayak"; Flags: nowait postinstall skipifsilent
```

Build installer:
```bash
# Compile with Inno Setup
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
```

#### **Option 2: MSIX Package (Microsoft Store)**

```bash
# Install MSIX packaging tool
# Build MSIX package
flutter build windows --release

# Create MSIX
# Use Visual Studio or MSIX Packaging Tool
```

### **Microsoft Store Distribution:**

1. **Create Developer Account:** https://partner.microsoft.com/dashboard
2. **Create App Submission**
3. **Upload MSIX package**
4. **Submit for certification**

---

## 🐧 LINUX DEPLOYMENT (Flutter Desktop)

### **Requirements:**
- Linux (Ubuntu 18.04+ / other distros)
- GTK 3.0+
- C++ build tools

### **Enable Linux Support:**

```bash
cd kheti_sahayak_app

# Enable Linux desktop support
flutter config --enable-linux-desktop

# Create Linux project files
flutter create --platforms=linux .

# Install dependencies (Ubuntu/Debian)
sudo apt-get install \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev
```

### **Build for Linux:**

```bash
# Build Linux app
flutter build linux --release

# Output: build/linux/x64/release/bundle/
```

### **Create AppImage:**

```bash
# Download appimagetool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# Create AppDir structure
mkdir -p KhetiSahayak.AppDir/usr/bin
mkdir -p KhetiSahayak.AppDir/usr/share/applications
mkdir -p KhetiSahayak.AppDir/usr/share/icons/hicolor/256x256/apps

# Copy files
cp -r build/linux/x64/release/bundle/* KhetiSahayak.AppDir/usr/bin/
cp assets/logo/kheti_sahayak_mark.png KhetiSahayak.AppDir/usr/share/icons/hicolor/256x256/apps/khetisahayak.png

# Create desktop file
cat > KhetiSahayak.AppDir/usr/share/applications/khetisahayak.desktop << EOF
[Desktop Entry]
Name=Kheti Sahayak
Exec=kheti_sahayak_app
Icon=khetisahayak
Type=Application
Categories=Agriculture;Education;
EOF

# Build AppImage
./appimagetool-x86_64.AppImage KhetiSahayak.AppDir KhetiSahayak-x86_64.AppImage
```

### **Create DEB Package (Debian/Ubuntu):**

```bash
# Create package structure
mkdir -p kheti-sahayak_1.0.0/DEBIAN
mkdir -p kheti-sahayak_1.0.0/usr/bin
mkdir -p kheti-sahayak_1.0.0/usr/share/applications

# Create control file
cat > kheti-sahayak_1.0.0/DEBIAN/control << EOF
Package: kheti-sahayak
Version: 1.0.0
Architecture: amd64
Maintainer: Kheti Sahayak Team <support@khetisahayak.com>
Description: Agricultural assistance platform for Indian farmers
 Kheti Sahayak provides AI-powered crop diagnostics, weather intelligence,
 marketplace, and expert consultations for farmers.
EOF

# Copy files
cp -r build/linux/x64/release/bundle/* kheti-sahayak_1.0.0/usr/bin/

# Build package
dpkg-deb --build kheti-sahayak_1.0.0
```

### **Snap Package (Universal Linux):**

Create `snap/snapcraft.yaml`:
```yaml
name: kheti-sahayak
version: '1.0.0'
summary: Agricultural assistance platform
description: |
  Kheti Sahayak provides comprehensive agricultural support including
  AI-powered diagnostics, weather intelligence, and expert consultations.

grade: stable
confinement: strict

apps:
  kheti-sahayak:
    command: kheti_sahayak_app
    plugs:
      - network
      - desktop

parts:
  kheti-sahayak:
    plugin: flutter
    source: .
    flutter-target: lib/main.dart
```

Build snap:
```bash
snapcraft
```

---

## 🔧 CROSS-PLATFORM CONFIGURATION

### **Environment Configuration for All Platforms:**

Create `.env` files for each platform:

```bash
# .env.production (All platforms)
API_BASE_URL=https://api.khetisahayak.com
ENVIRONMENT=production
ENABLE_ANALYTICS=true
```

### **Platform Detection in Flutter:**

```dart
// lib/utils/platform_utils.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isMacOS || isWindows || isLinux;
  
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isMacOS) return 'macOS';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }
}
```

### **Responsive UI for All Platforms:**

```dart
// lib/utils/responsive.dart
import 'package:flutter/material.dart';
import 'platform_utils.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? web;

  const Responsive({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.web,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isWeb && web != null) {
      return web!;
    }
    
    if (isDesktop(context) && desktop != null) {
      return desktop!;
    }
    
    if (isTablet(context) && tablet != null) {
      return tablet!;
    }
    
    return mobile;
  }
}
```

---

## 📦 BUILD AUTOMATION SCRIPTS

### **Build for All Platforms:**

Create `build-all-platforms.sh`:
```bash
#!/bin/bash

echo "🌾 Building Kheti Sahayak for All Platforms"
echo "==========================================="

# Web (React)
echo "📱 Building Web..."
cd frontend
npm run build
cd ..

# Flutter - All Platforms
cd kheti_sahayak_app

# Android
echo "🤖 Building Android..."
flutter build apk --release
flutter build appbundle --release

# iOS (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS..."
    flutter build ios --release
    flutter build ipa --release
fi

# Web (Flutter)
echo "🌐 Building Flutter Web..."
flutter build web --release

# Desktop - macOS (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "💻 Building macOS..."
    flutter build macos --release
fi

# Desktop - Windows (Windows only)
if [[ "$OSTYPE" == "msys" ]]; then
    echo "🪟 Building Windows..."
    flutter build windows --release
fi

# Desktop - Linux (Linux only)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Building Linux..."
    flutter build linux --release
fi

cd ..

echo "✅ Build Complete!"
echo "Check outputs in respective build directories"
```

Make it executable:
```bash
chmod +x build-all-platforms.sh
```

---

## 🚀 DEPLOYMENT SUMMARY

### **Quick Deployment Commands:**

```bash
# Web (Netlify)
cd frontend && npm run build && netlify deploy --prod

# Android (Generate APK)
cd kheti_sahayak_app && flutter build apk --release

# iOS (Generate IPA - macOS only)
cd kheti_sahayak_app && flutter build ipa --release

# macOS (Generate App)
cd kheti_sahayak_app && flutter build macos --release

# Windows (Generate EXE)
cd kheti_sahayak_app && flutter build windows --release

# Linux (Generate Bundle)
cd kheti_sahayak_app && flutter build linux --release
```

---

## 📊 PLATFORM COMPARISON

| Platform | File Size | Build Time | Distribution |
|----------|-----------|------------|--------------|
| **Web** | ~2 MB | 2-3 min | CDN / Web Server |
| **Android** | ~25 MB | 5-7 min | Google Play Store |
| **iOS** | ~30 MB | 8-10 min | Apple App Store |
| **macOS** | ~40 MB | 6-8 min | DMG / Mac App Store |
| **Windows** | ~35 MB | 5-7 min | EXE / Microsoft Store |
| **Linux** | ~35 MB | 5-7 min | AppImage / DEB / Snap |

---

## ✅ PLATFORM-SPECIFIC FEATURES

### **All Platforms:**
✅ Core agricultural features  
✅ API connectivity  
✅ Offline support  
✅ Multi-language ready  

### **Mobile (Android/iOS):**
✅ Camera integration for crop diagnostics  
✅ GPS for location-based services  
✅ Push notifications  
✅ Offline-first architecture  

### **Desktop (Windows/macOS/Linux):**
✅ Larger screen optimized UI  
✅ Keyboard shortcuts  
✅ File system access  
✅ Multi-window support  

### **Web:**
✅ No installation required  
✅ Cross-browser compatibility  
✅ Progressive Web App (PWA)  
✅ Responsive design  

---

## 🎯 NEXT STEPS

1. **Test on Each Platform:** Build and test on all target platforms
2. **Platform-Specific Optimization:** Optimize UI/UX for each platform
3. **Distribution:** Submit to respective app stores
4. **Analytics:** Track platform-specific usage
5. **Updates:** Set up CI/CD for automated builds

---

## 📞 SUPPORT

For platform-specific build issues:
- Web: Check browser console
- Android: Check `adb logcat`
- iOS: Check Xcode console
- Desktop: Check application logs

---

**🌾 Kheti Sahayak - Now Available Everywhere! 🌐**

*Built once, deployed everywhere - True cross-platform agricultural platform!*


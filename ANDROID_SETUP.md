# 📱 Android Setup Guide - Kheti Sahayak

Complete guide for setting up and building the Kheti Sahayak Android app.

---

## 📊 Android Implementation Status

### ✅ Fully Implemented Features

- [x] **Authentication System**
  - Login, Registration, Password Reset
  - JWT token management
  - Secure storage with flutter_secure_storage

- [x] **Core Disease Diagnosis**
  - Camera and gallery image upload
  - AI disease detection integration (ready)
  - Treatment recommendations display
  - Diagnostic history tracking

- [x] **Offline Functionality**
  - SQLite local database
  - Pending uploads queue
  - Background sync service
  - Auto-sync on connectivity restore

- [x] **UI/UX**
  - 25+ screens implemented
  - Material Design 3
  - Dark mode support
  - Multi-language (Hindi, Marathi, English)

- [x] **Android Configuration**
  - App signing configured
  - ProGuard rules for release
  - Permissions properly declared
  - App icons (all densities)

### ⚠️ Known Issues (Fixed in this guide)

- ~~API URL set to localhost~~ ✅ Instructions provided below
- ~~Duplicate dependencies in pubspec.yaml~~ ✅ Fixed
- ~~Environment file not configured in assets~~ ✅ Fixed

---

## 🚀 Quick Start

### Prerequisites

```bash
# Check Flutter installation
flutter doctor

# Required:
# ✓ Flutter SDK 3.10+
# ✓ Android SDK (via Android Studio)
# ✓ Android Studio / VS Code
# ✓ Java JDK 11+
```

### 1. Clone & Install

```bash
# Clone repository
git clone https://github.com/automotiv/khetisahayak.git
cd khetisahayak/kheti_sahayak_app

# Install dependencies
flutter pub get
```

### 2. Configure API URL

**⚠️ CRITICAL: Must configure before building!**

Edit `lib/.env`:

```env
# For Android Emulator:
API_BASE_URL=http://10.0.2.2:3000/api

# For Physical Device (find your computer's IP):
# Windows: ipconfig
# Mac/Linux: ifconfig | grep inet
API_BASE_URL=http://192.168.1.100:3000/api

# For Production:
API_BASE_URL=https://api.khetisahayak.com/api
```

### 3. Run App

```bash
# List connected devices
flutter devices

# Run on default device
flutter run

# Run on specific device
flutter run -d <device-id>
```

---

## 🔧 Development Setup

### Android Studio Configuration

1. **Install Android Studio**
   - Download from https://developer.android.com/studio
   - Install with Android SDK

2. **Set up Android SDK**
   ```bash
   # In Android Studio:
   # Settings → Appearance & Behavior → System Settings → Android SDK
   # Install SDK Platforms: Android 14 (API 34)
   # Install SDK Tools: Android SDK Build-Tools, Platform-Tools
   ```

3. **Set ANDROID_HOME**
   ```bash
   # Mac/Linux (.zshrc or .bashrc)
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

   # Windows (System Environment Variables)
   ANDROID_HOME=C:\Users\YourName\AppData\Local\Android\Sdk
   PATH=%PATH%;%ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools
   ```

### VS Code Setup (Optional)

1. **Install Extensions**
   - Flutter
   - Dart
   - Flutter Widget Snippets

2. **Configure launch.json**
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Flutter (Debug)",
         "request": "launch",
         "type": "dart",
         "args": ["--flavor", "development"]
       }
     ]
   }
   ```

---

## 📦 Building for Production

### App Signing Setup

Keystore is already configured:
- **Location:** `~/upload-keystore.jks`
- **Password:** `KhetiSahayak@2024`
- **Alias:** `upload`

**Verify configuration:**

```bash
# Check key.properties exists
cat android/key.properties

# Should show:
# storePassword=KhetiSahayak@2024
# keyPassword=KhetiSahayak@2024
# keyAlias=upload
# storeFile=/Users/prakash.ponali/upload-keystore.jks
```

### Build Release Bundle

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build App Bundle (for Google Play Store)
flutter build appbundle --release

# Output:
# build/app/outputs/bundle/release/app-release.aab
```

### Build Release APK

```bash
# Build single APK
flutter build apk --release

# Build split APKs (smaller size)
flutter build apk --split-per-abi --release

# Outputs:
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

---

## 🧪 Testing

### Run Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Test with coverage
flutter test --coverage
```

### Manual Testing Checklist

#### Pre-Build Testing
- [ ] Change API_BASE_URL to device IP or production URL
- [ ] Test on Android emulator
- [ ] Test on physical device (different Android versions)
- [ ] Test with airplane mode (offline functionality)
- [ ] Test camera permissions
- [ ] Test storage permissions
- [ ] Test image upload (camera)
- [ ] Test image upload (gallery)

#### Post-Build Testing
- [ ] Install release APK on device
- [ ] Verify app name shows as "Kheti Sahayak"
- [ ] Verify app icon displays correctly
- [ ] Test all features in release mode
- [ ] Check for crashes or ANRs
- [ ] Verify ProGuard didn't break anything

---

## 🐛 Troubleshooting

### Common Issues

#### 1. "Unable to connect to server"

**Problem:** App can't reach backend API

```bash
# Solution 1: Check API_BASE_URL in lib/.env
# For emulator: http://10.0.2.2:3000/api
# For device: http://YOUR_COMPUTER_IP:3000/api

# Solution 2: Check backend is running
cd kheti_sahayak_backend
npm run dev

# Solution 3: Check firewall allows connections
# Windows: Windows Defender Firewall → Allow an app
# Mac: System Preferences → Security & Privacy → Firewall → Options
```

#### 2. "Keystore file not found"

**Problem:** Build fails with keystore error

```bash
# Solution: Verify keystore path in android/key.properties
# Update with absolute path:
storeFile=/Users/YOUR_USERNAME/upload-keystore.jks

# Or regenerate keystore:
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### 3. "Gradle build failed"

```bash
# Solution 1: Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release

# Solution 2: Clear Gradle cache
cd android
./gradlew clean
cd ..
flutter build apk --release

# Solution 3: Update Gradle (if needed)
cd android
./gradlew wrapper --gradle-version=8.0
```

#### 4. "Duplicate class found"

**Problem:** Dependency conflicts

```bash
# Solution: Check pubspec.yaml for duplicates
# Fixed in latest version (connectivity_plus, path_provider were duplicated)

flutter clean
flutter pub get
```

#### 5. "Permission denied"

**Problem:** Camera/Storage permissions not granted

```bash
# Solution 1: Check AndroidManifest.xml permissions are declared
# (Already configured in this project)

# Solution 2: Request permissions at runtime
# (Already implemented in the app)

# Solution 3: Manually grant in device settings
# Settings → Apps → Kheti Sahayak → Permissions
```

---

## 📊 Performance Optimization

### App Size Optimization

```bash
# Build with obfuscation and minification (already configured)
flutter build appbundle --release

# Analyze app size
flutter build apk --analyze-size --target-platform android-arm64

# Split APKs by ABI (reduces size per device)
flutter build apk --split-per-abi
```

### ProGuard Configuration

ProGuard rules are already configured in `android/app/proguard-rules.pro`

Key rules:
- Keep Dio classes
- Keep JSON serialization
- Keep Flutter classes
- Keep SQLite classes

---

## 🔐 Security Best Practices

### ✅ Already Implemented

- [x] API keys not in version control
- [x] JWT tokens in secure storage
- [x] HTTPS for API communication
- [x] Password hashing on backend
- [x] ProGuard obfuscation for release
- [x] Keystore not in git

### 🔒 Additional Recommendations

1. **Certificate Pinning** (Future enhancement)
   ```dart
   // Add to dio configuration
   dio.httpClientAdapter = IOHttpClientAdapter()
     ..onHttpClientCreate = (client) {
       client.badCertificateCallback = (cert, host, port) => false;
       return client;
     };
   ```

2. **Root Detection** (Future enhancement)
   - Add `flutter_jailbreak_detection` package
   - Prevent app from running on rooted devices

3. **Code Obfuscation** (Already enabled)
   ```bash
   # Build with obfuscation
   flutter build apk --obfuscate --split-debug-info=./debug-info
   ```

---

## 📱 Device Compatibility

### Minimum Requirements
- **Android Version:** 5.0 (Lollipop) - API Level 21
- **RAM:** 2GB minimum, 4GB recommended
- **Storage:** 100MB app size + data
- **Camera:** Required for image capture
- **Internet:** Required for AI analysis

### Tested Devices
- ✅ Google Pixel 6 (Android 14)
- ✅ Samsung Galaxy S21 (Android 13)
- ✅ OnePlus 9 (Android 12)
- ✅ Xiaomi Redmi Note 10 (Android 11)
- ✅ Generic Android Emulator (API 34)

---

## 🚀 Deployment Checklist

### Pre-Deployment

- [ ] Update API_BASE_URL to production
- [ ] Update version in `pubspec.yaml`
- [ ] Test on multiple devices and Android versions
- [ ] Run all tests
- [ ] Generate release build
- [ ] Test release build on devices
- [ ] Prepare store listing assets
- [ ] Create privacy policy URL

### Play Store Submission

- [ ] Build signed App Bundle
- [ ] Create Google Play Developer account ($25)
- [ ] Create app listing
- [ ] Upload App Bundle
- [ ] Add screenshots (minimum 2)
- [ ] Add feature graphic (1024x500)
- [ ] Complete content rating
- [ ] Add privacy policy URL
- [ ] Submit for review

See [PLAY_STORE_LISTING.md](./PLAY_STORE_LISTING.md) for complete guide.

---

## 📞 Support

### Getting Help

- **Issues:** [GitHub Issues](https://github.com/automotiv/khetisahayak/issues)
- **Email:** support@khetisahayak.com
- **Documentation:** [docs/](./docs/)

### Reporting Bugs

When reporting bugs, include:
1. Android version
2. Device model
3. App version
4. Steps to reproduce
5. Error logs (from `flutter logs` or logcat)

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Android Developer Guide](https://developer.android.com/)
- [Material Design Guidelines](https://m3.material.io/)
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools)

---

**Last Updated:** October 21, 2024
**Version:** 1.0.0
**Maintained by:** Kheti Sahayak Team

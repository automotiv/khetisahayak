# Android Build Configuration for Kheti Sahayak

This directory contains the Android-specific configuration for the Kheti Sahayak mobile application.

## Application Details

- **Package Name**: `com.khetisahayak.app`
- **App Name**: Kheti Sahayak (खेती सहायक)
- **Build System**: Gradle with Flutter plugin
- **Language**: Kotlin

## Build Configuration

### Debug Build
```bash
flutter build apk --debug
# or
flutter run
```

### Release Build
```bash
flutter build apk --release
# or for App Bundle (recommended for Play Store)
flutter build appbundle --release
```

## Signing Configuration

### For Production Release

1. **Generate a keystore** (one-time setup):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Create key.properties file**:
   - Copy `key.properties.example` to `key.properties`
   - Fill in your keystore details:
     ```properties
     storePassword=<your_store_password>
     keyPassword=<your_key_password>
     keyAlias=upload
     storeFile=<path_to_keystore>/upload-keystore.jks
     ```

3. **Security**: The `key.properties` file is already in `.gitignore` - never commit it to version control!

## Permissions

The app requires the following permissions:

- **INTERNET**: API calls and data synchronization
- **ACCESS_NETWORK_STATE**: Check network connectivity
- **CAMERA**: Crop disease detection and image capture
- **READ_EXTERNAL_STORAGE**: Select images from gallery (Android 12 and below)
- **WRITE_EXTERNAL_STORAGE**: Save images (Android 10 and below)
- **READ_MEDIA_IMAGES**: Access photos (Android 13+)
- **ACCESS_FINE_LOCATION**: Weather data and location-based features
- **ACCESS_COARSE_LOCATION**: Approximate location for weather
- **POST_NOTIFICATIONS**: Alerts and reminders (Android 13+)

All runtime permissions are handled by the `permission_handler` package in the Flutter app.

## ProGuard Configuration

Release builds use ProGuard for:
- Code obfuscation
- Resource shrinking
- Optimization

ProGuard rules are defined in `app/proguard-rules.pro`. The configuration includes:
- Flutter-specific keep rules
- AndroidX compatibility
- Common library rules (Gson, Retrofit, OkHttp, etc.)
- Native method preservation

## Resources

### Localization
Supported languages with string resources:
- **English** (`values/strings.xml`)
- **Hindi** (`values-hi/strings.xml`)
- **Marathi** (`values-mr/strings.xml`)

### Themes
- Light theme: `values/styles.xml`
- Dark theme: `values-night/styles.xml`

### Design Resources
- Colors: `values/colors.xml`
- Dimensions: `values/dimens.xml`

## Minimum Requirements

- **Min SDK**: API 21 (Android 5.0 Lollipop)
- **Target SDK**: API 34 (Android 14)
- **Compile SDK**: API 34
- **Java Version**: 11
- **Kotlin Version**: 1.7.10

## Build Variants

The app currently has two build types:
- **debug**: Development builds with debugging enabled, no obfuscation
- **release**: Production builds with ProGuard enabled

## Publishing to Google Play Store

### First Time Setup

1. **Create a Google Play Developer account**
2. **Generate upload keystore** (see Signing Configuration above)
3. **Build App Bundle**:
   ```bash
   flutter build appbundle --release
   ```
4. **Upload** `build/app/outputs/bundle/release/app-release.aab` to Play Console

### Subsequent Updates

1. **Update version** in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # version_name+version_code
   ```
2. **Build and upload** new App Bundle

## Troubleshooting

### Common Issues

**Build fails with "Duplicate class" error**:
- Run `flutter clean` and rebuild

**ProGuard removes needed classes**:
- Add keep rules to `proguard-rules.pro`

**Permissions not working**:
- Check AndroidManifest.xml has required permissions
- Verify runtime permission handling in Flutter code

**Signing errors**:
- Verify key.properties file exists and has correct paths
- Check keystore password is correct

### Useful Commands

```bash
# Clean build
flutter clean

# Check for outdated dependencies
flutter pub outdated

# Analyze Dart code
flutter analyze

# Run tests
flutter test

# Check app size
flutter build apk --analyze-size

# Generate release APK for testing
flutter build apk --release

# View connected devices
flutter devices
```

## Directory Structure

```
android/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── kotlin/com/khetisahayak/app/
│   │   │   │   └── MainActivity.kt
│   │   │   ├── res/
│   │   │   │   ├── values/
│   │   │   │   ├── values-hi/
│   │   │   │   ├── values-mr/
│   │   │   │   ├── values-night/
│   │   │   │   ├── drawable/
│   │   │   │   └── mipmap-*/
│   │   │   └── AndroidManifest.xml
│   ├── build.gradle
│   └── proguard-rules.pro
├── gradle/
├── build.gradle
├── settings.gradle
├── key.properties.example
└── README.md
```

## Additional Resources

- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [ProGuard Documentation](https://www.guardsquare.com/manual/home)
- [Google Play Console](https://play.google.com/console)

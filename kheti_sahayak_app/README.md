# Kheti Sahayak Mobile App

A comprehensive Flutter mobile application for the Kheti Sahayak agricultural assistance platform. This app provides farmers with tools for crop diagnostics, educational content, marketplace access, and agricultural guidance.

## 🚀 Features

- **User Authentication**: Secure login and registration with JWT tokens
- **Crop Diagnostics**: AI-powered plant disease detection with image upload
- **Educational Content**: Articles, videos, and guides for agricultural learning
- **Marketplace**: Browse and purchase agricultural products
- **Crop Recommendations**: Season-based crop suggestions
- **Expert Reviews**: Professional agricultural expert consultation
- **Weather Information**: Real-time weather data and forecasts
- **Notifications**: Push notifications for important updates
- **Offline Support**: Basic offline functionality for core features
- **Multi-language Support**: Support for multiple Indian languages

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences
- **Image Handling**: Image Picker, Cached Network Image
- **UI Components**: Material Design 3
- **Navigation**: GoRouter
- **Testing**: Flutter Test
- **Build**: Flutter CLI

## 📋 Prerequisites

Before running this application, make sure you have the following installed:

- Flutter SDK (v3.10 or higher)
- Dart SDK (v3.0 or higher)
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)
- Git

## 🔧 Installation & Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd kheti_sahayak_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Environment Configuration

Create a `.env` file in the `lib` directory:

```bash
# API Configuration
API_BASE_URL=http://localhost:3000/api
API_TIMEOUT=30000

# Feature Flags
ENABLE_NOTIFICATIONS=true
ENABLE_OFFLINE_MODE=true
ENABLE_ANALYTICS=false

# App Configuration
APP_NAME=Kheti Sahayak
APP_VERSION=1.0.0
```

### 4. Platform-Specific Setup

#### Android Setup

1. Update `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

2. Add permissions in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS Setup

1. Update `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos for crop diagnostics</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images for crop diagnostics</string>
```

### 5. Run the Application

#### Development Mode

```bash
# Run on connected device/emulator
flutter run

# Run with specific device
flutter run -d <device-id>

# Run in debug mode
flutter run --debug
```

#### Release Mode

```bash
# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release
```

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── diagnostic.dart
│   ├── educational_content.dart
│   ├── product.dart
│   └── crop_recommendation.dart
├── providers/                # State management
│   ├── user_provider.dart
│   ├── auth_provider.dart
│   └── theme_provider.dart
├── services/                 # API services
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── diagnostic_service.dart
│   ├── educational_content_service.dart
│   └── marketplace_service.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── diagnostics/
│   │   ├── diagnostic_screen.dart
│   │   ├── upload_screen.dart
│   │   └── result_screen.dart
│   ├── education/
│   │   ├── education_screen.dart
│   │   ├── article_screen.dart
│   │   └── video_screen.dart
│   ├── marketplace/
│   │   ├── marketplace_screen.dart
│   │   ├── product_screen.dart
│   │   └── cart_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── widgets/                  # Reusable widgets
│   ├── common/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   └── loading_widget.dart
│   ├── diagnostic/
│   │   ├── image_upload_widget.dart
│   │   └── result_card.dart
│   └── education/
│       ├── content_card.dart
│       └── category_filter.dart
├── utils/                    # Utility functions
│   ├── constants.dart
│   ├── helpers.dart
│   └── validators.dart
└── routes/                   # Navigation routes
    └── app_routes.dart
```

## 🔌 API Integration

The app integrates with the Kheti Sahayak backend API. Key endpoints:

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/logout` - User logout

### Diagnostics
- `POST /api/diagnostics/upload` - Upload diagnostic image
- `GET /api/diagnostics` - Get diagnostic history
- `GET /api/diagnostics/recommendations` - Get crop recommendations

### Educational Content
- `GET /api/educational-content` - Get educational content
- `GET /api/educational-content/:id` - Get specific content
- `GET /api/educational-content/categories` - Get content categories

### Marketplace
- `GET /api/products` - Get products
- `GET /api/products/:id` - Get specific product
- `POST /api/orders` - Create order

## 🎨 UI/UX Features

- **Material Design 3**: Modern, accessible UI components
- **Responsive Design**: Adapts to different screen sizes
- **Dark/Light Theme**: User preference support
- **Loading States**: Smooth loading animations
- **Error Handling**: User-friendly error messages
- **Image Optimization**: Efficient image loading and caching
- **Gesture Support**: Intuitive touch interactions

## 📊 State Management

The app uses the Provider pattern for state management:

- **UserProvider**: Manages user authentication and profile data
- **AuthProvider**: Handles authentication state and tokens
- **ThemeProvider**: Manages app theme preferences
- **DiagnosticProvider**: Manages diagnostic data and results
- **EducationProvider**: Manages educational content data

## 🧪 Testing

### Unit Tests

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Integration Tests

```bash
# Run integration tests
flutter test integration_test/
```

### Widget Tests

```bash
# Run widget tests
flutter test test/widgets/
```

## 📦 Dependencies

Key dependencies used in the project:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  dio: ^5.3.2
  shared_preferences: ^2.2.2
  image_picker: ^1.0.4
  cached_network_image: ^3.3.0
  go_router: ^12.1.1
  flutter_dotenv: ^5.1.0
  carousel_slider: ^4.2.1
  readmore: ^2.2.0
  url_launcher: ^6.1.14
  permission_handler: ^11.0.1
  flutter_local_notifications: ^16.2.0
```

## 🚀 Build & Deployment

### Android Build

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Build for specific architecture
flutter build apk --release --target-platform android-arm64
```

### iOS Build

```bash
# Build for iOS
flutter build ios --release

# Archive for App Store
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release archive -archivePath build/Runner.xcarchive
```

### Web Build

```bash
# Build for web
flutter build web --release
```

## 🔒 Security Features

- JWT token management
- Secure API communication
- Input validation and sanitization
- Secure local storage
- Certificate pinning (optional)
- Biometric authentication support

## 📱 Platform Support

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **Web**: Modern browsers (Chrome, Firefox, Safari, Edge)
- **Desktop**: Windows, macOS, Linux (experimental)

## 🎯 Performance Optimization

- Image caching and optimization
- Lazy loading for lists
- Efficient state management
- Memory leak prevention
- Network request optimization
- Background processing

## 🔧 Development Tools

### Code Analysis

```bash
# Run static analysis
flutter analyze

# Fix analysis issues
dart fix --apply
```

### Code Formatting

```bash
# Format code
dart format lib/

# Check formatting
dart format --set-exit-if-changed lib/
```

### Dependency Management

```bash
# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Clean and get dependencies
flutter clean && flutter pub get
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter/Dart style guidelines
- Write unit tests for new features
- Update documentation for API changes
- Test on multiple devices/platforms
- Ensure accessibility compliance

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- Create an issue in the repository
- Contact the development team
- Check the Flutter documentation
- Review the backend API documentation

## 🔄 Version History

- **v1.0.0** - Initial release with core features
- **v1.1.0** - Added crop diagnostics
- **v1.2.0** - Enhanced educational content
- **v1.3.0** - Added marketplace functionality
- **v1.4.0** - Improved UI/UX and performance

## 📱 Screenshots

[Add screenshots of key app screens here]

---

**Note**: Make sure to configure the backend API URL and other environment variables according to your setup before running the application.

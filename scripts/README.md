# 🚀 Deployment Scripts

Automated deployment scripts for Kheti Sahayak application.

## Available Scripts

### 1. `deploy-all.sh` - Complete Deployment
Deploys everything: backend, Android, and iOS.

**Usage:**
```bash
./scripts/deploy-all.sh [VERSION] [BUILD_NUMBER] [DEPLOY_BACKEND] [DEPLOY_MOBILE]
```

**Examples:**
```bash
# Deploy everything with version 1.0.0
./scripts/deploy-all.sh 1.0.0 1 true true

# Deploy only backend
./scripts/deploy-all.sh 1.0.0 1 true false

# Deploy only mobile apps
./scripts/deploy-all.sh 1.0.0 1 false true
```

---

### 2. `deploy-backend-render.sh` - Backend Only
Deploys Node.js backend to Render.

**Usage:**
```bash
./scripts/deploy-backend-render.sh
```

**Prerequisites:**
- Render CLI installed: `npm install -g render-cli`
- Render account created
- `.env` file configured

**What it does:**
1. Logs into Render
2. Installs backend dependencies
3. Runs tests
4. Deploys using `render.yaml`
5. Verifies health endpoint

---

### 3. `build-android.sh` - Build Android AAB
Builds release AAB for Google Play Store.

**Usage:**
```bash
./scripts/build-android.sh [BUILD_TYPE] [FLAVOR] [BUILD_NUMBER] [VERSION]
```

**Examples:**
```bash
# Build release AAB
./scripts/build-android.sh release production 1 1.0.0

# Build debug APK
./scripts/build-android.sh debug dev
```

**Prerequisites:**
- Flutter SDK installed
- Android keystore exists: `kheti_sahayak_app/android/app/upload-keystore.jks`
- `key.properties` configured

**Outputs:**
- AAB: `kheti_sahayak_app/build/app/outputs/bundle/release/app-release.aab`
- APKs: `kheti_sahayak_app/build/app/outputs/flutter-apk/`

---

### 4. `build-ios.sh` - Build iOS IPA
Builds release IPA for Apple App Store.

**Usage:**
```bash
./scripts/build-ios.sh [BUILD_NUMBER] [VERSION]
```

**Examples:**
```bash
# Build release IPA
./scripts/build-ios.sh 1 1.0.0
```

**Prerequisites:**
- macOS required
- Flutter SDK installed
- Xcode installed
- Distribution certificate configured
- Provisioning profile installed

**Outputs:**
- IPA: `kheti_sahayak_app/build/ios/ipa/kheti_sahayak_app.ipa`

---

## Quick Start

### First Time Setup

1. **Install Prerequisites:**
   ```bash
   # Flutter
   brew install flutter

   # Render CLI (for backend deployment)
   npm install -g render-cli

   # Vercel CLI (for frontend deployment)
   npm install -g vercel
   ```

2. **Configure Signing:**
   ```bash
   # Android - verify keystore exists
   ls kheti_sahayak_app/android/app/upload-keystore.jks

   # iOS - configure in Xcode
   cd kheti_sahayak_app/ios
   open Runner.xcworkspace
   # Go to Signing & Capabilities → Enable "Automatically manage signing"
   ```

3. **Set Environment Variables:**
   ```bash
   # Backend
   cd kheti_sahayak_backend
   cp .env.example .env
   # Edit .env with your values
   ```

### Deploy Everything

```bash
# Make sure you're on main branch
git checkout main
git pull

# Run complete deployment
./scripts/deploy-all.sh 1.0.0 1
```

This will:
1. Run all tests
2. Update version numbers
3. Deploy backend to Render
4. Build Android AAB
5. Build iOS IPA
6. Create Git tag

---

## CI/CD with GitHub Actions

For automated deployment, use GitHub Actions:

```bash
# Push a version tag to trigger deployment
git tag v1.0.0
git push origin v1.0.0
```

This triggers `.github/workflows/deploy-production.yml` which:
- Runs all tests
- Deploys backend
- Builds and uploads Android to Play Store
- Builds and uploads iOS to TestFlight
- Creates GitHub release

---

## Manual Deployment Steps

### Backend to Render

1. Create Render account: https://render.com
2. Create PostgreSQL database
3. Create Web Service:
   - Connect GitHub repo
   - Select `kheti_sahayak_backend` as root directory
   - Add environment variables
4. Deploy: `./scripts/deploy-backend-render.sh`

### Android to Play Store

1. Create Play Console account: https://play.google.com/console ($25 one-time)
2. Create app in Play Console
3. Complete store listing (see `PLAY_STORE_LISTING.md`)
4. Build AAB: `./scripts/build-android.sh release production 1 1.0.0`
5. Upload to Internal Testing
6. Test with testers
7. Promote to Production with staged rollout

### iOS to App Store

1. Enroll in Apple Developer Program: https://developer.apple.com ($99/year)
2. Create app in App Store Connect: https://appstoreconnect.apple.com
3. Configure certificates and provisioning profiles
4. Build IPA: `./scripts/build-ios.sh 1 1.0.0`
5. Upload to TestFlight via Transporter or Xcode
6. Submit for review

---

## Troubleshooting

### Flutter not found
```bash
# Install Flutter
brew install flutter
# Or download from: https://flutter.dev
```

### Android build fails
```bash
cd kheti_sahayak_app/android
./gradlew clean
./gradlew --refresh-dependencies
cd ..
flutter clean
flutter pub get
```

### iOS build fails
```bash
cd kheti_sahayak_app/ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### Render deployment fails
```bash
# Check Render logs
render logs kheti-sahayak-api --tail

# Common issues:
# - DATABASE_URL not set
# - Port not using $PORT variable
# - Dependencies not installing
```

---

## Script Maintenance

### Adding New Scripts

1. Create script in `scripts/` directory
2. Add shebang: `#!/bin/bash`
3. Set error handling: `set -e`
4. Make executable: `chmod +x scripts/your-script.sh`
5. Document in this README

### Updating Scripts

- Test in staging environment first
- Update version in script comments
- Update this README
- Notify team of changes

---

## Support

For issues or questions:
- See main deployment guide: `DEPLOYMENT_GUIDE.md`
- Check deployment checklist: `DEPLOYMENT_CHECKLIST.md`
- Contact deployment team: `@devops-release-manager`

---

**Happy Deploying! 🚀**

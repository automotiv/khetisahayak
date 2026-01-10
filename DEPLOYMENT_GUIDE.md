# 🚀 Kheti Sahayak - Complete Deployment Guide

**Last Updated:** January 6, 2026
**Version:** 1.0.0
**Platforms:** Play Store | App Store | Render | Vercel

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Team](#deployment-team)
4. [Platform Deployments](#platform-deployments)
   - [Backend (Render)](#backend-deployment-render)
   - [Frontend (Vercel)](#frontend-deployment-vercel)
   - [Android (Play Store)](#android-deployment-play-store)
   - [iOS (App Store)](#ios-deployment-app-store)
5. [CI/CD Automation](#cicd-automation)
6. [Monitoring & Rollback](#monitoring--rollback)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This guide provides step-by-step instructions for deploying the complete Kheti Sahayak application stack across all platforms.

### Architecture Overview

```
┌─────────────────────────────────────────┐
│   Mobile Apps (Play Store + App Store) │
│     - Flutter iOS & Android             │
│     - AI Disease Detection              │
│     - Treatment Recommendations         │
└──────────────┬──────────────────────────┘
               │
               │ HTTPS/REST API
               │
┌──────────────▼──────────────────────────┐
│     Backend API (Render - Node.js)      │
│   - Express REST API                    │
│   - JWT Authentication                  │
│   - Image Processing                    │
└──┬────────────────────────────────────┬─┘
   │                                    │
   │                                    │
┌──▼─────────────────┐    ┌─────────────▼────────┐
│  PostgreSQL DB     │    │  ML Service (Render) │
│  (Render)          │    │  - FastAPI + PyTorch │
│  - User Data       │    │  - Disease Detection │
│  - Diagnostics     │    │  - Image Analysis    │
│  - Treatments      │    └──────────────────────┘
└────────────────────┘
         │
         │
┌────────▼───────────────────────────────┐
│  Web Dashboard (Vercel - Next.js)      │
│  - Admin Interface                     │
│  - Analytics Dashboard                 │
│  - Farmer Web Portal                   │
└────────────────────────────────────────┘
```

---

## Prerequisites

### Required Accounts
- ✅ **Google Play Console** - For Android deployment ($25 one-time fee)
- ✅ **Apple Developer Program** - For iOS deployment ($99/year)
- ✅ **Render Account** - For backend/database hosting (Free tier available)
- ✅ **Vercel Account** - For frontend hosting (Free tier available)
- ✅ **GitHub Account** - For version control and CI/CD

### Required Tools
```bash
# Flutter SDK (for mobile builds)
flutter --version  # Should be 3.16.0+

# Node.js (for backend)
node --version  # Should be 18+

# Git (for version control)
git --version

# Optional but recommended
brew install fastlane  # Mobile automation
npm install -g vercel  # Vercel CLI
npm install -g render-cli  # Render CLI
```

### Required Credentials
- Android keystore file and passwords
- iOS distribution certificate and provisioning profile
- Render API token
- Vercel API token
- Database connection strings
- API keys for external services

---

## Deployment Team

We have specialized AI agents to help with deployment. See [.claude/DEPLOYMENT_TEAM.md](.claude/DEPLOYMENT_TEAM.md) for details.

**Quick Reference:**
- `@devops-release-manager` - Orchestrates all deployments
- `@play-store-deployment-specialist` - Android deployment
- `@app-store-deployment-specialist` - iOS deployment
- `@render-deployment-specialist` - Backend deployment
- `@vercel-deployment-specialist` - Frontend deployment
- `@mobile-build-engineer` - Build configuration

**Example Usage:**
```
@devops-release-manager deploy version 1.0.0 to all platforms
```

---

## Platform Deployments

### Backend Deployment (Render)

#### Step 1: Create Render Account
1. Go to [https://render.com](https://render.com)
2. Sign up with GitHub
3. Authorize Render to access your repositories

#### Step 2: Create PostgreSQL Database
1. In Render Dashboard, click "New +" → "PostgreSQL"
2. Configure:
   - **Name:** `kheti-sahayak-db`
   - **Database:** `kheti_sahayak`
   - **User:** `kheti_admin`
   - **Region:** Singapore (closest to India)
   - **Plan:** Starter ($7/month) or Free (90 days)
3. Click "Create Database"
4. Copy the **Internal Database URL** (starts with `postgres://`)

#### Step 3: Deploy Backend API
1. In Render Dashboard, click "New +" → "Web Service"
2. Connect your GitHub repository
3. Configure:
   - **Name:** `kheti-sahayak-api`
   - **Region:** Singapore
   - **Branch:** `main`
   - **Root Directory:** `kheti_sahayak_backend`
   - **Runtime:** Node
   - **Build Command:** `npm install && npm run build`
   - **Start Command:** `npm run start`
   - **Plan:** Starter ($7/month) or Free

4. Add Environment Variables:
   ```
   NODE_ENV=production
   PORT=3000
   DATABASE_URL=<paste your internal database URL>
   JWT_SECRET=<generate a strong random string>
   ML_API_URL=https://kheti-ml.onrender.com
   ```

5. Click "Create Web Service"

#### Step 4: Run Database Migrations
Once deployed, open the Shell:
```bash
# In Render Shell
npm run migrate:up
node seedTreatmentData.js
```

Verify:
```bash
curl https://kheti-sahayak-api.onrender.com/api/health
```

#### Step 5: Deploy ML Service (Optional)
1. Create another Web Service
2. Configure:
   - **Name:** `kheti-ml-service`
   - **Runtime:** Python
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

---

### Frontend Deployment (Vercel)

#### Step 1: Create Vercel Account
1. Go to [https://vercel.com](https://vercel.com)
2. Sign up with GitHub
3. Authorize Vercel

#### Step 2: Deploy Dashboard (Next.js)
1. Click "Add New Project"
2. Import your GitHub repository
3. Configure:
   - **Framework Preset:** Next.js
   - **Root Directory:** `kheti_sahayak_web` (if you have a web dashboard)
   - **Build Command:** `npm run build`
   - **Output Directory:** `.next`

4. Add Environment Variables:
   ```
   NEXT_PUBLIC_API_URL=https://kheti-sahayak-api.onrender.com
   NEXT_PUBLIC_ML_API_URL=https://kheti-ml.onrender.com
   ```

5. Click "Deploy"

#### Step 3: Configure Custom Domain (Optional)
1. Go to Project Settings → Domains
2. Add your domain: `khetisahayak.com`
3. Update DNS records as instructed
4. SSL will be automatically configured

Verify:
```bash
curl https://khetisahayak.vercel.app
```

---

### Android Deployment (Play Store)

#### Step 1: Verify Build Configuration

Check existing configuration:
```bash
cd kheti_sahayak_app/android

# Verify keystore exists
ls app/upload-keystore.jks

# Verify key.properties exists
cat key.properties
```

Your `key.properties` should contain:
```properties
storePassword=khetisahayak2024
keyPassword=khetisahayak2024
keyAlias=upload
storeFile=app/upload-keystore.jks
```

#### Step 2: Build Release AAB

```bash
cd kheti_sahayak_app

# Clean previous builds
flutter clean
flutter pub get

# Build release AAB
flutter build appbundle --release \
  --build-number=1 \
  --build-name=1.0.0

# Verify the build
ls -lh build/app/outputs/bundle/release/app-release.aab
```

Expected output: `app-release.aab` (should be < 25 MB)

#### Step 3: Create Play Store Listing

1. Go to [Google Play Console](https://play.google.com/console)
2. Create App:
   - **App name:** Kheti Sahayak - Farm Assistant
   - **Default language:** English (United States)
   - **App or game:** App
   - **Free or paid:** Free

3. Complete Store Listing (see [PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md)):
   - Short description (80 chars)
   - Full description (4000 chars)
   - App icon (512x512 px)
   - Feature graphic (1024x500 px)
   - Screenshots (minimum 2)

#### Step 4: Upload AAB

1. Go to "Release" → "Production"
2. Click "Create new release"
3. Upload `app-release.aab`
4. Add release notes:
   ```
   First release of Kheti Sahayak - AI-powered crop disease detection

   Features:
   - Upload crop images for instant disease detection
   - Get treatment recommendations in Hindi & English
   - Expert consultation support
   - Crop recommendations based on season and soil
   ```

#### Step 5: Internal Testing First
1. Go to "Release" → "Testing" → "Internal testing"
2. Create new release
3. Upload AAB
4. Add testers (5-10 people)
5. Share test link
6. Collect feedback for 1-2 weeks

#### Step 6: Staged Production Rollout
1. Promote from internal to production
2. Set rollout percentage to 10%
3. Monitor for 24 hours
4. Increase to 25%, 50%, then 100%

**Important Notes:**
- First review typically takes 3-7 days
- Keep app under 20 MB for better downloads
- Respond to review feedback within 24 hours

---

### iOS Deployment (App Store)

#### Step 1: Apple Developer Account Setup
1. Enroll in [Apple Developer Program](https://developer.apple.com/programs/) ($99/year)
2. Wait for approval (usually 24-48 hours)
3. Complete profile setup

#### Step 2: Create App in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+" → "New App"
3. Configure:
   - **Platform:** iOS
   - **Name:** Kheti Sahayak
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** com.khetisahayak.app
   - **SKU:** KHETISAHAYAK001

#### Step 3: Create Certificates & Provisioning Profiles

Using Xcode:
```bash
# Open iOS project in Xcode
cd kheti_sahayak_app/ios
open Runner.xcworkspace

# In Xcode:
# 1. Select Runner project
# 2. Go to Signing & Capabilities
# 3. Enable "Automatically manage signing"
# 4. Select your Team
# 5. Xcode will create certificate and provisioning profile
```

Or manually via Apple Developer Portal:
1. Create **iOS Distribution Certificate**
2. Create **App Store Provisioning Profile**
3. Download and install both

#### Step 4: Build IPA

```bash
cd kheti_sahayak_app

# Clean build
flutter clean
cd ios
pod deintegrate
pod install
cd ..

# Build IPA
flutter build ipa --release \
  --build-number=1 \
  --build-name=1.0.0

# Output location
ls build/ios/ipa/kheti_sahayak_app.ipa
```

#### Step 5: Upload to TestFlight

**Option A: Using Xcode**
1. Open `build/ios/archive/Runner.xcarchive` in Xcode
2. Click "Distribute App"
3. Select "App Store Connect"
4. Upload

**Option B: Using Transporter**
1. Download Apple Transporter app
2. Open the app
3. Drag and drop IPA file
4. Click "Deliver"

**Option C: Using fastlane**
```bash
cd kheti_sahayak_app/ios
fastlane beta
```

#### Step 6: TestFlight Beta Testing
1. In App Store Connect, go to TestFlight
2. Add internal testers (up to 100)
3. Share TestFlight link
4. Collect feedback for 2-4 weeks
5. Fix any issues

#### Step 7: Submit for App Review
1. Complete App Store listing:
   - Description (see PLAY_STORE_LISTING.md)
   - Keywords
   - Screenshots (all iPhone and iPad sizes)
   - Privacy Policy URL
   - Support URL

2. Configure App Review Information:
   - **Contact information**
   - **Demo account** (if needed):
     ```
     Username: demo@khetisahayak.com
     Password: Demo@123
     ```
   - **Notes:** "App helps Indian farmers detect crop diseases using AI"

3. Submit for Review
4. Wait 1-2 days for review
5. If approved, release manually or automatically

**Important Notes:**
- App Review is strict - prepare detailed notes
- Provide demo credentials if app requires login
- Respond to review feedback quickly
- Use phased release for safer rollout

---

## CI/CD Automation

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy All Platforms

on:
  push:
    branches: [main]
    tags: ['v*']

env:
  FLUTTER_VERSION: '3.16.0'
  NODE_VERSION: '18'

jobs:
  # Backend deployment
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Trigger Render deployment
        run: curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK }}"

  # Frontend deployment
  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'

  # Android build
  build-android:
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}

      - name: Decode keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks

      - name: Build AAB
        run: |
          cd kheti_sahayak_app
          flutter build appbundle --release

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.khetisahayak.app
          releaseFiles: kheti_sahayak_app/build/app/outputs/bundle/release/app-release.aab
          track: internal

  # iOS build
  build-ios:
    runs-on: macos-latest
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      - name: Build IPA
        run: |
          cd kheti_sahayak_app
          flutter build ipa --release

      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: kheti_sahayak_app/build/ios/ipa/kheti_sahayak_app.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
```

### Required GitHub Secrets

Add these in Settings → Secrets:
```
RENDER_DEPLOY_HOOK=https://api.render.com/deploy/...
VERCEL_TOKEN=...
VERCEL_ORG_ID=...
VERCEL_PROJECT_ID=...
ANDROID_KEYSTORE_BASE64=...
ANDROID_KEYSTORE_PASSWORD=...
PLAY_STORE_SERVICE_ACCOUNT=...
APPSTORE_ISSUER_ID=...
APPSTORE_API_KEY_ID=...
APPSTORE_API_PRIVATE_KEY=...
```

---

## Monitoring & Rollback

### Health Checks

**Backend (Render):**
```bash
curl https://kheti-sahayak-api.onrender.com/api/health
```

**Frontend (Vercel):**
```bash
curl https://khetisahayak.vercel.app
```

**Play Store:**
- Monitor in Play Console → Quality → Android vitals
- Target: Crash-free rate >99.5%

**App Store:**
- Monitor in App Store Connect → Analytics
- Target: Crash rate <1%

### Rollback Procedures

**Backend (Render):**
```bash
# Via Dashboard
# 1. Go to service → Events
# 2. Click on previous successful deployment
# 3. Click "Redeploy"

# Or via CLI
render rollback kheti-sahayak-api --to-version 1.0.0
```

**Frontend (Vercel):**
```bash
vercel rollback kheti-sahayak-web
```

**Play Store:**
1. Go to Release management → App releases
2. Select previous release
3. Create new release with previous AAB
4. Set rollout to 100%

**App Store:**
1. Cannot rollback directly
2. Must submit new version with previous code
3. Request expedited review if critical

---

## Troubleshooting

### Android Build Issues

**Issue:** Gradle build fails
```bash
# Solution
cd kheti_sahayak_app/android
./gradlew clean
./gradlew --refresh-dependencies
./gradlew assembleRelease
```

**Issue:** Signing failed
```bash
# Verify keystore
keytool -list -v -keystore app/upload-keystore.jks

# Check key.properties file exists
cat key.properties
```

### iOS Build Issues

**Issue:** Pod install fails
```bash
cd kheti_sahayak_app/ios
pod deintegrate
pod install
```

**Issue:** Code signing error
```bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Verify certificate
security find-identity -v -p codesigning
```

### Backend Issues

**Issue:** Database connection fails
```bash
# Check DATABASE_URL environment variable
# Verify database is running in Render dashboard
# Check IP allowlist if using external DB
```

**Issue:** Service won't start
```bash
# Check Render logs
render logs kheti-sahayak-api --tail

# Common issues:
# - PORT environment variable not used
# - Database migrations not run
# - Missing environment variables
```

### Frontend Issues

**Issue:** Build fails on Vercel
```bash
# Check Vercel logs in dashboard
# Common issues:
# - Environment variables missing NEXT_PUBLIC_ prefix
# - Node version mismatch
# - Build command incorrect
```

---

## Quick Reference Commands

### Build Commands
```bash
# Android AAB
flutter build appbundle --release

# iOS IPA
flutter build ipa --release

# Android APK (for testing)
flutter build apk --release --split-per-abi
```

### Deployment Commands
```bash
# Render
render deploy

# Vercel
vercel --prod

# Play Store (using fastlane)
cd android && fastlane deploy

# App Store (using fastlane)
cd ios && fastlane release
```

### Version Bump
```bash
# Update version in pubspec.yaml
# Example: version: 1.0.1+2
# Format: {major}.{minor}.{patch}+{build_number}

# Then build with new version
flutter build appbundle --build-number=2 --build-name=1.0.1
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Code reviewed
- [ ] Version numbers updated
- [ ] Changelog prepared
- [ ] Database migrations tested
- [ ] Environment variables verified
- [ ] Secrets rotated (if needed)

### Backend Deployment
- [ ] Deploy to Render
- [ ] Run database migrations
- [ ] Verify health endpoint
- [ ] Check logs for errors
- [ ] Monitor for 15 minutes

### Frontend Deployment
- [ ] Deploy to Vercel preview
- [ ] Test preview environment
- [ ] Deploy to production
- [ ] Verify home page loads
- [ ] Check Core Web Vitals

### Mobile Deployment
- [ ] Build AAB and IPA
- [ ] Test builds on devices
- [ ] Upload to internal tracks
- [ ] Internal testing (1 week)
- [ ] Promote to beta
- [ ] Beta testing (2 weeks)
- [ ] Submit for review
- [ ] Staged rollout (10%→100%)

### Post-Deployment
- [ ] Monitor crash rates
- [ ] Check user reviews
- [ ] Verify analytics
- [ ] Update documentation
- [ ] Notify stakeholders

---

## Support & Resources

### Documentation
- [Play Store Listing](PLAY_STORE_LISTING.md)
- [Deployment Team](.claude/DEPLOYMENT_TEAM.md)
- [MVP Setup Guide](MVP_COMPLETE_SETUP_GUIDE.md)

### Platform Docs
- [Render Documentation](https://render.com/docs)
- [Vercel Documentation](https://vercel.com/docs)
- [Google Play Console Help](https://support.google.com/googleplay)
- [App Store Connect Help](https://help.apple.com/app-store-connect)

### Tools
- [Flutter Documentation](https://flutter.dev/docs)
- [Fastlane Documentation](https://docs.fastlane.tools)

---

**🎉 Ready to deploy Kheti Sahayak to millions of farmers!**

For deployment assistance, call: `@devops-release-manager`

# Kheti Sahayak Deployment Guide

This guide covers both manual build/deployment processes and the automated GitHub Actions workflow.

---

## 🏗️ Manual Build & Deployment

Since you might need to build the app manually in your local environment, follow these steps.

### Step 1: Clean and Prepare Build Environment

Open your terminal and navigate to the project directory:

```bash
cd /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app
```

Run the following commands to ensure a clean slate:

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Verify Flutter environment (optional but recommended)
flutter doctor
```

### Step 2: Build Release App Bundle (AAB) - For Play Store

The Android App Bundle (AAB) is the required format for Google Play Store verification and uploading.

```bash
# Build the App Bundle with release configuration
flutter build appbundle --release
```

*   **Significance:** This compiles Dart to native code, applies ProGuard minification, signs it with your upload keystore, and creates an optimized AAB.
*   **Output Location:** `build/app/outputs/bundle/release/app-release.aab`
*   **Expected Size:** ~20-40 MB (with minification)

### Step 3: Build Release APK - For Testing

If you want to test the release build on a device before uploading:

```bash
# Build APK for testing on your device
flutter build apk --release
```

*   **Output Location:** `build/app/outputs/flutter-apk/app-release.apk`

### Step 4: Install and Test on Physical Device

Connect your Android device via USB (ensure USB Debugging is ON).

```bash
# Install the release build directly
flutter install --release
```

OR manually via ADB:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎮 Google Play Console Setup

Once your build is ready, follow these steps to set up the store listing.

### 1. Create App
1.  Go to [Play Console](https://play.google.com/console).
2.  Click **Create app**.
3.  **Name:** `Kheti Sahayak`
4.  **Language:** English (United States) or Hindi.
5.  **Type:** App (Free).
6.  Accept policies.

### 2. Store Listing
*   **Short Description:** AI-powered farming assistant for crop health, weather, and market insights.
*   **Full Description:**
    > Kheti Sahayak (खेती सहायक) - Your Intelligent Farming Companion
    >
    > Empower your farming with cutting-edge AI technology and comprehensive agricultural resources. Kheti Sahayak is designed specifically for Indian farmers to make informed decisions and improve crop yields.
    >
    > 🌱 **KEY FEATURES:**
    > *   **AI-Powered Crop Disease Detection:** Instant diagnosis, treatment recommendations.
    > *   **Real-Time Weather:** Hyperlocal forecasts, rainfall alerts.
    > *   **Digital Marketplace:** Buy seeds/fertilizers, sell produce.
    > *   **Expert Consultation:** Ask questions, get advice.
    > *   **Smart Farm Management:** Expense tracking, crop rotation.
    > *   **Offline Mode:** Access data without internet.
    >
    > 🌍 **MULTI-LANGUAGE:** English, Hindi, Marathi, Tamil, Kannada, Telugu, Gujarati.
    >
    > \#SmartFarming #Agriculture #CropHealth #IndianFarmers #AIFarming

*   **Graphics:**
    *   **Icon:** 512x512 PNG
    *   **Feature Graphic:** 1024x500 PNG
    *   **Screenshots:** 2-8 images (1080x1920 recommended)

### 3. Content Rating & Privacy
*   **Category:** Productivity or Education.
*   **Questionnaire:** Answer specific questions (Violence: NO, etc.).
*   **Privacy Policy:** Add your hosted privacy policy URL.
*   **Data Safety:**
    *   **Location:** Yes (Weather/Features).
    *   **Personal Info:** Yes (Name/Email).
    *   **Photos:** Yes (Disease Detection).
    *   **Device ID:** Yes (Analytics).

### 4. Upload & Release regarding
1.  **Internal Testing:** Create a new release, upload `app-release.aab`, add testers.
2.  **Production:** detailed notes in "Release Notes" section (Draft provided in user request).

---

## 🤖 Automated Deployment (GitHub Actions)

If you prefer to let GitHub build your app automatically when you push to the `main` branch.

### 1. Generate Upload Keystore
Run this locally to generate the signing key:
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*   Keep the **password** and **alias** safe.

### 2. Configure GitHub Secrets
Go to **Settings** -> **Secrets and variables** -> **Actions** in your repo and add:

| Name | Description |
|------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64 encoded string of your `.jks` file (`base64 -i upload-keystore.jks`). |
| `KEY_STORE_PASSWORD` | Password from Step 1. |
| `KEY_PASSWORD` | Password from Step 1. |
| `KEY_ALIAS` | `upload`. |

### 3. Trigger Build
Push to `main`. The "Android Release Build" workflow will run. Download the artifact from the **Actions** tab.

---

## 🎯 Post-Submission Monitoring

*   **Review Time:** 1-3 days (up to 7 days).
*   **Common Rejections:** Incomplete privacy policy, unjustified permissions.
*   **After Live:** Verify link, monitor Android Vitals for crashes.

# Kheti Sahayak - Play Store Screenshot Capture Checklist

A comprehensive guide for capturing the 8 required screenshots for Google Play Store submission.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Device Specifications](#device-specifications)
3. [Image Requirements](#image-requirements)
4. [Mock Data Setup](#mock-data-setup)
5. [Screenshot Capture Guide](#screenshot-capture-guide)
6. [ADB Commands Reference](#adb-commands-reference)
7. [Post-Processing](#post-processing)
8. [Verification Checklist](#verification-checklist)

---

## Prerequisites

### Development Environment

```bash
# Verify Flutter installation
flutter doctor

# Verify ADB is available
adb version

# Verify connected device/emulator
flutter devices
adb devices
```

### Required Software

- Flutter SDK 3.10+
- Android Studio with emulator OR physical device
- ADB (Android Debug Bridge)
- Image editing software (optional: for adding frames/captions)

### App Setup

```bash
# Navigate to app directory
cd kheti_sahayak_app

# Install dependencies
flutter pub get

# Run in release mode (for clean screenshots)
flutter run --release
```

---

## Device Specifications

### Recommended Emulator Configurations

| Device Profile | Resolution | Aspect Ratio | Notes |
|---------------|------------|--------------|-------|
| **Pixel 4** | 1080 x 2280 | 19:9 | Modern notch device |
| **Pixel 6** | 1080 x 2400 | 20:9 | Latest standard |
| **Pixel 3a** | 1080 x 2220 | 18.5:9 | Mid-range reference |
| **Nexus 5X** | 1080 x 1920 | 16:9 | Classic ratio |

### Create Emulator (if needed)

```bash
# List available system images
sdkmanager --list | grep system-images

# Create emulator for screenshots
avdmanager create avd \
  --name "PlayStore_Screenshots" \
  --package "system-images;android-33;google_apis_playstore;x86_64" \
  --device "pixel_4"

# Start emulator
emulator -avd PlayStore_Screenshots -gpu swiftshader_indirect
```

---

## Image Requirements

### Play Store Specifications

| Requirement | Specification |
|-------------|---------------|
| **Phone Screenshots** | 1080 x 1920 px (16:9) OR 1080 x 2340 px (19.5:9) |
| **Minimum Required** | 2 screenshots |
| **Recommended** | 8 screenshots |
| **Format** | PNG or JPEG |
| **Max File Size** | 8 MB per image |
| **Aspect Ratios** | 16:9 or 9:16 (portrait) |

### Resolution Mapping

```
Standard Phone (16:9):   1080 x 1920 px
Modern Phone (19.5:9):   1080 x 2340 px
Modern Phone (20:9):     1080 x 2400 px
```

---

## Mock Data Setup

Before capturing screenshots, ensure the app has realistic demonstration data.

### Backend Setup (Required for live data)

```bash
# Start backend server
cd kheti_sahayak_backend
npm run dev

# Seed database with test data
npm run db:seed
```

### Test User Credentials

After seeding, use these accounts:

| Role | Email | Password |
|------|-------|----------|
| Farmer | farmer@khetisahayak.com | user123 |
| Expert | expert@khetisahayak.com | expert123 |
| Admin | admin@khetisahayak.com | admin123 |

### Data Requirements Per Screenshot

| Screenshot | Required Data |
|------------|---------------|
| Home/Dashboard | Weather data, recent diagnostics, educational content |
| Disease Detection | Sample crop images ready to upload |
| AI Analysis | Pre-analyzed diagnostic result |
| Treatment Results | Complete treatment recommendations |
| Expert Connect | List of verified experts with ratings |
| Diagnostic History | 3-5 past diagnostic records |
| Profile | Complete user profile with farm details |
| Offline Mode | Pending sync items indicator |

---

## Screenshot Capture Guide

### Screenshot 1: Home Dashboard

**Route:** `/dashboard`

**Navigation Path:**
```
AppRoutes.dashboard -> DashboardScreen
```

**What to Show:**
- Weather widget with current conditions
- Recent diagnostics summary
- Featured educational content
- Quick action cards

**Setup Steps:**
1. Login as farmer user
2. Navigate to Dashboard (default screen after login)
3. Wait for all data to load
4. Ensure weather widget shows realistic data

**Flutter Navigation:**
```dart
Navigator.pushNamed(context, AppRoutes.dashboard);
```

**Caption:** "Your Complete Farm Dashboard"

---

### Screenshot 2: Disease Detection (Upload Screen)

**Route:** `/diagnostics`

**Navigation Path:**
```
AppRoutes.diagnostics -> DiagnosticsScreen
```

**What to Show:**
- Image capture interface (camera/gallery options)
- Crop type selection field
- Issue description input
- Clean, inviting interface

**Setup Steps:**
1. From Dashboard, navigate to Diagnostics
2. Show the initial state with camera/gallery buttons visible
3. Optionally show a sample image already selected
4. Fill in crop type (e.g., "Rice") and description

**Flutter Navigation:**
```dart
Navigator.pushNamed(context, AppRoutes.diagnostics);
```

**Caption:** "AI-Powered Crop Disease Detection"

---

### Screenshot 3: AI Analysis (Processing Screen)

**Route:** `/diagnostics` (during analysis)

**Navigation Path:**
```
DiagnosticsScreen -> _analyzeImage() -> Loading state
```

**What to Show:**
- Loading/analyzing indicator
- Selected crop image visible
- "Analyzing..." text or progress indicator
- AI processing animation

**Setup Steps:**
1. Select a crop image
2. Fill in crop type and description
3. Tap "Analyze Plant" button
4. Capture screenshot during loading state

**Timing Note:** This requires capturing during the brief loading period. Consider using screen recording and extracting a frame.

**Caption:** "Instant AI Analysis"

---

### Screenshot 4: Disease Detection Results

**Route:** `/diagnostics` (result view)

**Navigation Path:**
```
DiagnosticsScreen -> LocalizedDiagnosticResultCard
```

**What to Show:**
- Disease name with confidence score
- Crop image thumbnail
- Disease severity indicator
- "View Treatments" button

**Setup Steps:**
1. Complete a diagnostic analysis
2. Wait for results to display
3. Ensure the LocalizedDiagnosticResultCard is fully visible
4. Show confidence score (aim for 85%+ for demo)

**Key UI Elements:**
- Disease name prominently displayed
- Confidence percentage badge
- Status indicator (analyzed/pending/resolved)
- Clear call-to-action buttons

**Flutter Navigation:**
```dart
// Result displays automatically after analysis completes
// Or view from history:
_viewDiagnosticResult(diagnostic);
```

**Caption:** "Accurate Disease Detection with Confidence Score"

---

### Screenshot 5: Treatment Recommendations

**Route:** `/treatment-details`

**Navigation Path:**
```
AppRoutes.treatmentDetails -> LocalizedTreatmentDetailsScreen
```

**What to Show:**
- Disease info card at top
- Filter chips (All, Organic, Chemical, Cultural)
- Treatment cards with:
  - Treatment name
  - Type badge (Organic/Chemical/Cultural)
  - Effectiveness rating (stars)
  - Cost estimate in INR

**Setup Steps:**
1. From a diagnostic result, tap "View Treatments"
2. Show the treatment list with filters visible
3. Have at least 2-3 treatments displayed
4. One treatment card expanded to show details

**Flutter Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LocalizedTreatmentDetailsScreen(
      diagnosticId: 'your_diagnostic_id',
    ),
  ),
);
```

**Caption:** "Get Expert Treatment Recommendations"

---

### Screenshot 6: Diagnostic History

**Route:** `/diagnostics` (history modal)

**Navigation Path:**
```
DiagnosticsScreen -> _showDiagnosticHistory() -> BottomSheet
```

**What to Show:**
- List of past diagnostics
- Each item showing:
  - Crop type
  - Status (pending/analyzed/resolved)
  - Date
  - Status icon color-coded

**Setup Steps:**
1. Navigate to Diagnostics screen
2. Tap the history icon in app bar
3. Bottom sheet opens showing diagnostic history
4. Ensure 4-5 items are visible

**Key UI Elements:**
- Draggable bottom sheet
- Status-colored icons
- Date stamps
- Crop types clearly visible

**Flutter Navigation:**
```dart
// Tap history icon or call:
_showDiagnosticHistory();
```

**Caption:** "Track Your Crop Health Over Time"

---

### Screenshot 7: Expert Connect

**Route:** `/experts`

**Navigation Path:**
```
AppRoutes.expertList -> ExpertListScreen
```

**What to Show:**
- Expert list with cards showing:
  - Expert photo/avatar
  - Name and specialization
  - Rating stars
  - Experience years
  - Consultation fee in INR
  - "Book Now" button
- Filter chips for specializations
- Search bar

**Setup Steps:**
1. Navigate to Expert Connect section from drawer
2. Ensure experts are loaded
3. Show at least 2 expert cards fully visible
4. One expert should show "Verified" badge and online status

**Flutter Navigation:**
```dart
Navigator.pushNamed(context, AppRoutes.expertList);
```

**Caption:** "Connect with Agricultural Experts"

---

### Screenshot 8: Profile & Settings

**Route:** `/profile`

**Navigation Path:**
```
AppRoutes.profile -> ProfileScreen
```

**What to Show:**
- User profile header with:
  - Profile image/avatar
  - Name
  - Email
  - "Verified Farmer" badge
- Farm details card (farm size, crops, soil type)
- Notification settings toggles
- Language selection option
- App settings menu

**Setup Steps:**
1. Login as farmer with complete profile
2. Navigate to Profile from drawer
3. Ensure farm details are populated
4. Show notification toggles in ON state

**Flutter Navigation:**
```dart
Navigator.pushNamed(context, AppRoutes.profile);
```

**Caption:** "Personalized for Your Farm"

---

## ADB Commands Reference

### Basic Screenshot Capture

```bash
# Create screenshots directory
mkdir -p ./screenshots/playstore

# Take screenshot and save to device
adb shell screencap -p /sdcard/screenshot.png

# Pull screenshot to local machine
adb pull /sdcard/screenshot.png ./screenshots/playstore/

# Clean up device storage
adb shell rm /sdcard/screenshot.png
```

### Batch Capture Script

Save as `take_screenshots.sh`:

```bash
#!/bin/bash

# Kheti Sahayak Screenshot Capture Script
# Usage: ./take_screenshots.sh

SCREENSHOT_DIR="./screenshots/playstore"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$SCREENSHOT_DIR"

# Screenshot names matching Play Store requirements
SCREENSHOTS=(
    "01_home_dashboard"
    "02_disease_detection"
    "03_ai_analysis"
    "04_detection_results"
    "05_treatment_recommendations"
    "06_diagnostic_history"
    "07_expert_connect"
    "08_profile_settings"
)

# Routes to navigate (for reference)
ROUTES=(
    "/dashboard"
    "/diagnostics"
    "/diagnostics (analyzing)"
    "/diagnostics (result)"
    "/treatment-details"
    "/diagnostics (history)"
    "/experts"
    "/profile"
)

echo "==========================================="
echo "  Kheti Sahayak Screenshot Capture Tool"
echo "==========================================="
echo ""

# Check device connection
if ! adb devices | grep -q "device$"; then
    echo "ERROR: No Android device connected!"
    echo "Please connect a device or start an emulator."
    exit 1
fi

echo "Device connected. Starting capture..."
echo ""

for i in "${!SCREENSHOTS[@]}"; do
    name="${SCREENSHOTS[$i]}"
    route="${ROUTES[$i]}"
    
    echo "-------------------------------------------"
    echo "Screenshot $((i+1))/8: $name"
    echo "Navigate to: $route"
    echo ""
    
    read -p "Press ENTER when ready to capture..."
    
    # Capture screenshot
    adb shell screencap -p /sdcard/screenshot_temp.png
    adb pull /sdcard/screenshot_temp.png "$SCREENSHOT_DIR/${name}.png"
    adb shell rm /sdcard/screenshot_temp.png
    
    echo "Saved: $SCREENSHOT_DIR/${name}.png"
    echo ""
done

echo "==========================================="
echo "  Screenshot capture complete!"
echo "  Location: $SCREENSHOT_DIR"
echo "==========================================="

# List captured files
echo ""
echo "Captured files:"
ls -la "$SCREENSHOT_DIR"
```

### Make Script Executable

```bash
chmod +x take_screenshots.sh
./take_screenshots.sh
```

### Individual Screenshot Commands

```bash
# Screenshot 1: Home Dashboard
adb shell screencap -p /sdcard/01_home.png && adb pull /sdcard/01_home.png ./screenshots/

# Screenshot 2: Disease Detection
adb shell screencap -p /sdcard/02_disease.png && adb pull /sdcard/02_disease.png ./screenshots/

# Screenshot 3: AI Analysis
adb shell screencap -p /sdcard/03_analysis.png && adb pull /sdcard/03_analysis.png ./screenshots/

# Screenshot 4: Detection Results
adb shell screencap -p /sdcard/04_results.png && adb pull /sdcard/04_results.png ./screenshots/

# Screenshot 5: Treatment Recommendations
adb shell screencap -p /sdcard/05_treatments.png && adb pull /sdcard/05_treatments.png ./screenshots/

# Screenshot 6: Diagnostic History
adb shell screencap -p /sdcard/06_history.png && adb pull /sdcard/06_history.png ./screenshots/

# Screenshot 7: Expert Connect
adb shell screencap -p /sdcard/07_experts.png && adb pull /sdcard/07_experts.png ./screenshots/

# Screenshot 8: Profile Settings
adb shell screencap -p /sdcard/08_profile.png && adb pull /sdcard/08_profile.png ./screenshots/
```

---

## Alternative: Flutter Integration Test Screenshots

Create `integration_test/screenshot_test.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kheti_sahayak_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Play Store Screenshots', () {
    testWidgets('Capture all screenshots', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Screenshot 1: After login, on dashboard
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('01_home_dashboard');

      // Navigate to diagnostics
      final drawer = find.byTooltip('Open navigation menu');
      await tester.tap(drawer);
      await tester.pumpAndSettle();
      
      final diagnosticsItem = find.text('Diagnostics');
      await tester.tap(diagnosticsItem);
      await tester.pumpAndSettle();

      // Screenshot 2: Disease Detection
      await binding.takeScreenshot('02_disease_detection');

      // Continue for other screenshots...
    });
  });
}
```

Run integration test:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_test.dart \
  --profile
```

---

## Post-Processing

### Resize to Exact Dimensions (ImageMagick)

```bash
# Resize to 1080x1920 (16:9)
convert input.png -resize 1080x1920^ -gravity center -extent 1080x1920 output.png

# Resize to 1080x2340 (19.5:9)
convert input.png -resize 1080x2340^ -gravity center -extent 1080x2340 output.png
```

### Add Text Captions (Optional)

```bash
# Add caption at bottom
convert screenshot.png \
  -gravity South \
  -font Arial-Bold \
  -pointsize 48 \
  -fill white \
  -annotate +0+50 "Your Caption Here" \
  screenshot_captioned.png
```

### Add Device Frame (Optional)

Use online tools like:
- [MockUPhone](https://mockuphone.com/)
- [AppMockUp](https://app-mockup.com/)
- [Figma Device Frames](https://www.figma.com/community/file/devices)

---

## Verification Checklist

### Before Capture

- [ ] App running in release mode (`flutter run --release`)
- [ ] Backend server running with seed data
- [ ] User logged in with complete profile
- [ ] All API endpoints returning data
- [ ] Device/emulator at correct resolution
- [ ] Status bar shows good signal/battery (demo mode)
- [ ] No debug banner visible
- [ ] No error dialogs or toasts visible

### For Each Screenshot

| Screenshot | Captured | Correct Size | Content Valid | Caption Ready |
|------------|----------|--------------|---------------|---------------|
| 01_home_dashboard | [ ] | [ ] | [ ] | [ ] |
| 02_disease_detection | [ ] | [ ] | [ ] | [ ] |
| 03_ai_analysis | [ ] | [ ] | [ ] | [ ] |
| 04_detection_results | [ ] | [ ] | [ ] | [ ] |
| 05_treatment_recommendations | [ ] | [ ] | [ ] | [ ] |
| 06_diagnostic_history | [ ] | [ ] | [ ] | [ ] |
| 07_expert_connect | [ ] | [ ] | [ ] | [ ] |
| 08_profile_settings | [ ] | [ ] | [ ] | [ ] |

### Final Quality Check

- [ ] All screenshots same dimensions
- [ ] No personal/test data visible (use demo data)
- [ ] UI elements fully loaded (no spinners)
- [ ] Text is readable and not cut off
- [ ] Colors look correct (no color profile issues)
- [ ] File sizes under 8MB each
- [ ] Filenames follow naming convention

---

## Storage Location (Fastlane)

After capturing, place screenshots in the Fastlane metadata directory:

```
kheti_sahayak_app/
  android/
    fastlane/
      metadata/
        android/
          en-US/
            images/
              phoneScreenshots/
                1_home_dashboard.png
                2_disease_detection.png
                3_ai_analysis.png
                4_detection_results.png
                5_treatment_recommendations.png
                6_diagnostic_history.png
                7_expert_connect.png
                8_profile_settings.png
```

### Copy Command

```bash
# Copy all screenshots to Fastlane directory
cp ./screenshots/playstore/*.png \
   ./android/fastlane/metadata/android/en-US/images/phoneScreenshots/

# Rename if needed
cd ./android/fastlane/metadata/android/en-US/images/phoneScreenshots/
for i in *.png; do
  mv "$i" "${i//_/-}"  # Replace underscores with hyphens if needed
done
```

---

## Quick Reference Card

| # | Screenshot | Route | Key UI Element |
|---|------------|-------|----------------|
| 1 | Home Dashboard | `/dashboard` | Weather widget + diagnostics |
| 2 | Disease Detection | `/diagnostics` | Camera/Gallery buttons |
| 3 | AI Analysis | `/diagnostics` | Loading indicator |
| 4 | Detection Results | `/diagnostics` | Result card with confidence |
| 5 | Treatments | `/treatment-details` | Treatment list with filters |
| 6 | History | `/diagnostics` + history | Bottom sheet with past items |
| 7 | Expert Connect | `/experts` | Expert cards with ratings |
| 8 | Profile | `/profile` | User info + settings |

---

## Support

For issues with screenshot capture:

- Check Flutter logs: `flutter logs`
- Check ADB connection: `adb devices`
- Restart ADB server: `adb kill-server && adb start-server`

---

*Last Updated: January 2026*
*Version: 1.0*
*For Kheti Sahayak v1.0.0 Play Store Submission*

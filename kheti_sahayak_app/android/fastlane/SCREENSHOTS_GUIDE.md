# Play Store Screenshots Guide - Kheti Sahayak

This guide provides instructions for creating Play Store screenshots and graphics.

---

## Required Assets

### Screenshots

| Device Type | Dimensions | Required | Recommended |
|------------|------------|----------|-------------|
| Phone | 1080 x 1920 px (16:9) or 1080 x 2340 px (19.5:9) | Min 2 | 8 |
| 7" Tablet | 1200 x 1920 px | Min 1 | 4-8 |
| 10" Tablet | 1600 x 2560 px | Min 1 | 4-8 |

### Graphics

| Asset | Dimensions | Required | Format |
|-------|------------|----------|--------|
| Feature Graphic | 1024 x 500 px | YES | PNG or JPEG |
| Icon | 512 x 512 px | YES | PNG (32-bit with alpha) |
| Promo Video | YouTube URL | NO | MP4 (recommended) |

---

## Screenshot Capture Methods

### Method 1: Flutter Screenshot Tool (Automated)

```bash
# Install screenshot package
flutter pub add --dev screenshot_test

# Create screenshot test
# test/screenshots/screenshot_test.dart
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Screenshot home screen', (tester) async {
    // Load app
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    
    // Take screenshot
    await binding.takeScreenshot('01_home_screen');
  });
}
```

### Method 2: Android Emulator

```bash
# Start emulator with specific size
emulator -avd Pixel_4_API_30 -gpu swiftshader_indirect

# Take screenshot via ADB
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./screenshots/

# Or use Android Studio
# View > Tool Windows > Emulator > Camera icon
```

### Method 3: Physical Device

1. Connect device via USB
2. Enable USB debugging
3. Run app in release mode:
   ```bash
   flutter run --release
   ```
4. Take screenshots using device controls
5. Pull from device:
   ```bash
   adb pull /sdcard/DCIM/Screenshots/ ./screenshots/
   ```

---

## Recommended Screenshots

### Screen 1: Home Dashboard
**File:** `01_home_dashboard.png`
**Content:** Main app home screen showing:
- Weather widget
- Crop health overview
- Quick action buttons
- Recent activity

**Caption:** "Your Complete Farm Dashboard"

### Screen 2: Disease Detection
**File:** `02_disease_detection.png`
**Content:** AI disease detection feature:
- Camera view or captured image
- Disease analysis results
- Treatment recommendations

**Caption:** "AI-Powered Crop Disease Detection"

### Screen 3: Weather Forecast
**File:** `03_weather_forecast.png`
**Content:** Weather screen showing:
- 7-day forecast
- Farming advisories
- Rain alerts

**Caption:** "Hyperlocal Weather for Your Farm"

### Screen 4: Expert Consultation
**File:** `04_expert_consultation.png`
**Content:** Expert network screen:
- List of available experts
- Chat interface
- Expert credentials

**Caption:** "Connect with Agricultural Experts"

### Screen 5: Marketplace
**File:** `05_marketplace.png`
**Content:** Digital marketplace:
- Product listings
- Categories
- Prices

**Caption:** "Buy Seeds, Fertilizers & Equipment"

### Screen 6: Educational Content
**File:** `06_education.png`
**Content:** Learning hub:
- Video tutorials
- Article listings
- Categories

**Caption:** "Learn Best Farming Practices"

### Screen 7: Community Forum
**File:** `07_community.png`
**Content:** Q&A community:
- Recent questions
- Expert answers
- Categories

**Caption:** "Join the Farming Community"

### Screen 8: Profile/Settings
**File:** `08_profile.png`
**Content:** User profile:
- Farm details
- Crop preferences
- Language settings

**Caption:** "Personalized for Your Farm"

---

## Screenshot Design Tips

### Best Practices

1. **Show Real Data:** Use realistic Indian farming data
2. **Localization:** Consider Hindi/Marathi versions
3. **Clean State:** Remove debug banners, use release mode
4. **Good Time:** Use appropriate time (daylight)
5. **Full Content:** Ensure all content is loaded
6. **Highlight Features:** Show unique selling points

### Design Enhancements

Consider adding frames and text overlays:

```bash
# Using ImageMagick for overlays
convert screenshot.png \
  -fill white -font Arial -pointsize 48 \
  -gravity North -annotate +0+50 "AI Disease Detection" \
  screenshot_enhanced.png
```

### Recommended Tools

- **Figma:** Design screenshot frames
- **Canva:** Quick graphics creation
- **Screenshot Pro:** Frame generator
- **AppMockUp:** Device mockups
- **LaunchMatic:** Automated screenshot generation

---

## Feature Graphic (1024 x 500)

### Required Elements

1. **App Logo:** Kheti Sahayak logo/icon
2. **App Name:** "Kheti Sahayak" in clear text
3. **Tagline:** "Your Digital Farm Helper"
4. **Key Visual:** Farming imagery (crops, farmer, technology blend)
5. **Brand Colors:** Green (#2E7D32), accent colors

### Design Suggestions

```
+--------------------------------------------------+
|                                                   |
|   [LOGO]  Kheti Sahayak                          |
|           खेती सहायक                              |
|                                                   |
|   "AI-Powered Farm Assistant for Indian Farmers" |
|                                                   |
|   [Crop images]  [Weather icon]  [Expert icon]   |
|                                                   |
+--------------------------------------------------+
```

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Green | #2E7D32 | Main brand color |
| Light Green | #4CAF50 | Accents |
| Earth Brown | #795548 | Secondary |
| Sky Blue | #03A9F4 | Weather elements |
| White | #FFFFFF | Text on dark |
| Black | #212121 | Text on light |

---

## Creating Assets with Figma

### Feature Graphic Template

1. Create new file: 1024 x 500 px
2. Add background gradient (green tones)
3. Place app icon (left side)
4. Add app name and tagline
5. Include 3-4 feature icons
6. Export as PNG

### Screenshot Frames

1. Use device mockup template
2. Insert actual screenshots
3. Add text captions below
4. Maintain consistent style
5. Export at proper resolution

---

## Storage Locations

```
kheti_sahayak_app/
└── android/
    └── fastlane/
        └── metadata/
            └── android/
                └── en-US/
                    ├── images/
                    │   ├── featureGraphic.png     (1024x500)
                    │   ├── icon.png               (512x512)
                    │   ├── phoneScreenshots/
                    │   │   ├── 1_home.png
                    │   │   ├── 2_disease.png
                    │   │   └── ...
                    │   ├── sevenInchScreenshots/
                    │   │   └── ...
                    │   └── tenInchScreenshots/
                    │       └── ...
                    ├── title.txt
                    ├── short_description.txt
                    └── full_description.txt
```

---

## Quick Screenshot Script

Create `take_screenshots.sh`:

```bash
#!/bin/bash

# Kheti Sahayak Screenshot Capture Script

SCREENSHOT_DIR="./screenshots"
mkdir -p "$SCREENSHOT_DIR"

echo "Starting screenshot capture..."

# Ensure device is connected
adb devices

# List of screens to capture
SCREENS=(
    "home_dashboard"
    "disease_detection"
    "weather_forecast"
    "expert_consultation"
    "marketplace"
    "education"
    "community"
    "profile"
)

# Function to take screenshot
take_screenshot() {
    local name=$1
    local filename="${SCREENSHOT_DIR}/${name}.png"
    
    echo "Capturing: $name"
    adb shell screencap -p /sdcard/screenshot.png
    adb pull /sdcard/screenshot.png "$filename"
    echo "Saved: $filename"
}

# Manual mode - prompt for each screen
for screen in "${SCREENS[@]}"; do
    echo ""
    echo "Navigate to: $screen"
    read -p "Press Enter when ready to capture..."
    take_screenshot "$screen"
done

echo ""
echo "Screenshots saved to: $SCREENSHOT_DIR"
echo "Done!"
```

---

## Uploading via API

After creating screenshots, upload using:

```python
# Add to playstore_manager.py
def upload_screenshots(service, edit_id, language='en-US'):
    image_dir = Path(__file__).parent / 'metadata' / 'android' / language / 'images'
    
    # Upload phone screenshots
    phone_dir = image_dir / 'phoneScreenshots'
    for img in sorted(phone_dir.glob('*.png')):
        media = MediaFileUpload(str(img), mimetype='image/png')
        service.edits().images().upload(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            language=language,
            imageType='phoneScreenshots',
            media_body=media
        ).execute()
        print(f"Uploaded: {img.name}")
```

---

## Checklist

- [ ] Create screenshot directory structure
- [ ] Capture 8 phone screenshots
- [ ] Capture 4+ tablet screenshots (7" and 10")
- [ ] Design feature graphic (1024x500)
- [ ] Verify icon is 512x512 PNG
- [ ] Add text captions to screenshots (optional)
- [ ] Create device mockup frames (optional)
- [ ] Upload via fastlane or API
- [ ] Preview in Play Console

---

*Use this guide to create compelling Play Store visuals for Kheti Sahayak*

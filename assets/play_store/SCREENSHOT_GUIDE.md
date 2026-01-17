# Play Store Screenshot Guide

## Requirements
- **Minimum**: 2 screenshots (currently have 1, need 1 more)
- **Recommended**: 4-8 screenshots
- **Dimensions**:
  - Minimum: 320px
  - Maximum: 3840px
  - Aspect ratio: 16:9 or 9:16 recommended
  - PNG or JPEG format

## Current Screenshots
✓ `screenshot_home.png` - Home/Dashboard screen

## Required Additional Screenshots (Priority Order)

### 1. CRITICAL - Need at least 1 more to meet minimum:
- **Disease Detection Screen** (HIGH PRIORITY)
  - Show camera interface or a detection result
  - Highlight the AI analysis feature
  - Include treatment recommendations

### 2. Recommended Additional Screenshots:

#### Screenshot 2: Disease Detection in Action
- Open the app → Go to Diagnostics/Disease Detection
- Take screenshot showing:
  - Image upload interface OR
  - Analysis result with disease name, confidence %, treatment

#### Screenshot 3: Market Prices / Marketplace
- Navigate to Marketplace section
- Show:
  - Live market prices table
  - Crop prices with trends
  - Buy/Sell interface

#### Screenshot 4: Weather Dashboard
- Navigate to Weather section
- Show:
  - Current weather
  - 7-day forecast
  - Agricultural advisories

#### Screenshot 5: Expert Consultation
- Navigate to Expert/Consultation section
- Show:
  - Expert profiles
  - Chat/consultation interface
  - Q&A forum

#### Screenshot 6: Farm Logbook
- Navigate to Farm Management/Logbook
- Show:
  - Activity tracking
  - Expense records
  - Reports/analytics

#### Screenshot 7: Profile/Settings
- Show user profile
- Highlight multilingual support
- Show settings with Hindi/regional language options

#### Screenshot 8: Government Schemes
- Navigate to Schemes/Benefits section
- Show:
  - List of agricultural schemes
  - Eligibility checker
  - Application status

## How to Capture Screenshots

### On Android Emulator:
```bash
cd kheti_sahayak_app
flutter run

# While app is running, press:
# - Windows/Linux: Ctrl + S
# - Mac: Cmd + S
# Or use emulator screenshot button
```

### On Physical Device:
- Run the app: `flutter run`
- Use device screenshot (Power + Volume Down on most Android)
- Or use `adb shell screencap -p /sdcard/screenshot.png`

### Alternatively - Use Flutter DevTools:
```bash
flutter run
# Press 'd' to open DevTools
# Use DevTools screenshot feature
```

## Screenshot Best Practices

1. **Clean data**: Use realistic but clean sample data
2. **Hide sensitive info**: No real phone numbers, addresses, user data
3. **Good lighting**: Clear, well-lit screenshots
4. **Focus on features**: Highlight key app functionality
5. **Consistent device**: Use same device/resolution for all
6. **Status bar**: Clean status bar (full battery, good signal)

## Naming Convention
Save screenshots as:
- `screenshot_1_disease_detection.png`
- `screenshot_2_marketplace.png`
- `screenshot_3_weather.png`
- etc.

## Where to Save
Place all screenshots in: `assets/play_store/`

## Upload Order in Play Console
Arrange screenshots to tell a story:
1. Home/Dashboard (overview)
2. Disease Detection (killer feature - AI)
3. Market Prices (value proposition)
4. Weather (utility)
5. Expert Consultation (support)
6. Farm Logbook (management)

This showcases your app's progression from overview → key features → value adds.

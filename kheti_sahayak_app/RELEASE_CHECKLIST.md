# Release Checklist

## ✅ Testing Checklist

### Core Functionality
- [ ] App launches without crashes
- [ ] Login/registration works
- [ ] Dashboard loads data from production API
- [ ] Navigation between all tabs works

### Permissions & Features
- [ ] Camera permission request appears
- [ ] Camera opens and captures images
- [ ] Crop disease detection works
- [ ] Location permission request appears
- [ ] Weather data loads
- [ ] Notification permission appears (Android 13+)

### Network & API
- [ ] All data syncs with production API (https://khetisahayak.onrender.com/api)
- [ ] No HTTP/HTTPS errors
- [ ] Offline mode works
- [ ] Error handling gracefully handles network issues

### Multi-language
- [ ] Switch to Hindi - UI updates correctly
- [ ] Switch to Marathi - UI updates correctly
- [ ] All 7 languages work properly

### Performance
- [ ] App launches in < 3 seconds
- [ ] No lag or stuttering
- [ ] Images load smoothly
- [ ] No crashes after 5+ minutes of use

## 🛡️ Data Safety & Privacy Compliance

### Privacy Policy
- [ ] Privacy Policy URL is accessible and up-to-date.

### Data Collection Declarations
Ensure the following are declared in the Play Console Data Safety form:
- [ ] **Location**: Approximate location (Purpose: Weather forecasts/features).
- [ ] **Personal Info**: Name, Email (Purpose: User account).
- [ ] **Photos**: (Purpose: Crop disease detection).
- [ ] **Device ID**: (Purpose: Analytics/Crash reports).

### Security Practices
- [ ] Data is encrypted in transit (HTTPS).
- [ ] Data is encrypted at rest.
- [ ] Mechanism exists for users to request data deletion.
- [ ] Mechanism exists for users to request data export.

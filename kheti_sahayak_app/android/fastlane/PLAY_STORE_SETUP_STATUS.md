# Play Store Setup Status - Kheti Sahayak

**Last Updated:** January 7, 2026  
**Status:** Waiting for Upload Key Reset Approval

---

## Completed Tasks

### 1. Store Listing (API) - DONE
- [x] English (en-US) listing updated via API
- [x] Hindi (hi-IN) listing updated via API
- [x] Marathi (mr-IN) listing updated via API
- [x] App title set
- [x] Short description set
- [x] Full description set
- [x] Contact email: support@khetisahayak.com
- [x] Contact website: https://www.khetisahayak.com
- [x] Contact phone: +91-1234567890

### 2. Privacy Policy - DONE
- [x] Privacy policy HTML page created
- Location: `docs/privacy-policy.html`
- Ready for GitHub Pages hosting

**To host on GitHub Pages:**
```bash
# Option 1: Enable GitHub Pages in repo settings
# Point to /docs folder on main branch

# Option 2: Create gh-pages branch
git checkout -b gh-pages
git add docs/privacy-policy.html
git commit -m "Add privacy policy for Play Store"
git push origin gh-pages

# URL will be: https://yourusername.github.io/khetisahayak/privacy-policy.html
```

### 3. Data Safety Questionnaire - DONE
- [x] Guidance document created
- Location: `android/fastlane/DATA_SAFETY_QUESTIONNAIRE.md`
- Contains all answers for Play Console Data Safety form

### 4. Content Rating Questionnaire - DONE
- [x] Guidance document created
- Location: `android/fastlane/CONTENT_RATING_QUESTIONNAIRE.md`
- Expected rating: Everyone (PEGI 3 / ESRB E)

### 5. Metadata Structure - DONE
- [x] Fastlane metadata directory created
- Location: `android/fastlane/metadata/android/en-US/`
  - `title.txt`
  - `short_description.txt`
  - `full_description.txt`
  - `images/phoneScreenshots/` (empty - needs screenshots)
  - `images/sevenInchScreenshots/` (empty)
  - `images/tenInchScreenshots/` (empty)

### 6. Auto-Deploy Monitoring - DONE
- [x] Python auto-deploy script created
- Location: `android/fastlane/auto_deploy_check.py`
- [x] launchd plist created and loaded
- Location: `~/Library/LaunchAgents/com.khetisahayak.deployment-monitor.plist`
- Runs every hour to check if key reset is approved

**Monitor logs:**
```bash
# View auto-deploy log
tail -f android/fastlane/auto_deploy.log

# View deployment status
cat android/fastlane/deployment_status.json

# Check launchd status
launchctl list | grep khetisahayak
```

---

## Pending Tasks (Manual Action Required)

### 1. Screenshots - MANUAL
- [ ] Capture 8 phone screenshots (1080x1920 or 1080x2340)
- [ ] Capture 4+ tablet screenshots
- [ ] Create device mockup frames (optional)

**Guide:** See `SCREENSHOTS_GUIDE.md`

**Quick capture:**
```bash
# Connect device and run
flutter run --release
# Navigate to each screen and capture via ADB
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./screenshots/
```

### 2. Feature Graphic - MANUAL
- [ ] Create 1024 x 500 px feature graphic
- [ ] Use app branding (green theme)
- [ ] Include app name and key features

**Recommended tools:** Figma, Canva, Adobe XD

### 3. Privacy Policy Hosting - MANUAL
- [ ] Host privacy policy HTML on GitHub Pages or domain
- [ ] Update URL in Play Console

### 4. Data Safety Form - MANUAL
- [ ] Fill out Data Safety form in Play Console
- [ ] Use `DATA_SAFETY_QUESTIONNAIRE.md` as reference

### 5. Content Rating - MANUAL
- [ ] Complete rating questionnaire in Play Console
- [ ] Use `CONTENT_RATING_QUESTIONNAIRE.md` as reference

### 6. Upload Key Reset - WAITING
- [ ] Google approval for upload key reset (2-3 days)
- Auto-monitoring is active

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `playstore_manager.py` | API management script |
| `auto_deploy_check.py` | Hourly deployment check |
| `DATA_SAFETY_QUESTIONNAIRE.md` | Data safety form answers |
| `CONTENT_RATING_QUESTIONNAIRE.md` | Content rating answers |
| `SCREENSHOTS_GUIDE.md` | Screenshot creation guide |
| `UPLOAD_KEY_RESET_INSTRUCTIONS.md` | Key reset process |
| `docs/privacy-policy.html` | Privacy policy page |
| `metadata/android/en-US/` | Fastlane metadata |

---

## Quick Commands

```bash
# Update store listing
python3 playstore_manager.py --update-listing

# Check app status
python3 playstore_manager.py --check-status

# Attempt deployment (after key reset)
python3 playstore_manager.py --deploy --track internal

# Manual auto-deploy check
python3 auto_deploy_check.py

# View monitoring logs
tail -f auto_deploy.log
```

---

## Timeline Estimate

| Task | Status | ETA |
|------|--------|-----|
| Upload Key Reset | Waiting | 2-3 days |
| Screenshots | Pending | 1-2 hours |
| Feature Graphic | Pending | 1 hour |
| Data Safety Form | Pending | 30 mins |
| Content Rating | Pending | 15 mins |
| First Internal Release | Blocked | After key reset |

---

## Next Steps After Key Reset Approval

1. **Auto-deploy will trigger** (if AAB exists)
2. Or manually run:
   ```bash
   # Build AAB
   cd kheti_sahayak_app
   flutter build appbundle --release
   
   # Deploy
   cd android/fastlane
   python3 playstore_manager.py --deploy --track internal
   ```

3. **Test on internal track** with team

4. **Promote to production** when ready:
   ```bash
   python3 playstore_manager.py --deploy --track production --rollout 0.1
   ```

---

*Document auto-generated by Play Store setup automation*

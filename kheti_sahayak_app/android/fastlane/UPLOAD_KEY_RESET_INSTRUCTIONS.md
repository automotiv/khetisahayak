# Upload Key Reset Instructions for Kheti Sahayak

## Current Situation

**Problem**: The AAB is signed with a different key than what Play Console expects.

| Key Type | SHA1 Fingerprint |
|----------|------------------|
| **Your Current Upload Key** | `B4:B4:78:60:C8:97:36:BD:B5:3F:76:90:AA:89:B3:F4:D1:AC:99:65` |
| **Play Console Expects** | `EA:5E:8F:A2:C2:90:DB:0A:0F:92:79:BF:A4:3C:95:68:59:F1:F6:8D` |

**Root Cause**: The app was previously uploaded with a different signing key. The current `upload-keystore.jks` doesn't match what's registered in Play Console.

## Important Note

**Upload key reset CANNOT be done via API** - Google intentionally keeps all signing key management operations manual for security reasons.

## Step-by-Step Instructions

### Step 1: Export Your Certificate (Already Done)

Your certificate is already exported at:
```
/Users/ponali.prakash/Documents/practice/khetisahayak/upload_certificate.pem
```

If you need to regenerate:
```bash
keytool -export -rfc \
  -keystore /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app/android/app/upload-keystore.jks \
  -alias upload \
  -file /Users/ponali.prakash/Documents/practice/khetisahayak/upload_certificate.pem
# Password: khetisahayak2024
```

### Step 2: Request Upload Key Reset in Play Console

1. **Open Play Console**: https://play.google.com/console/developers

2. **Navigate to App**:
   - Find "Kheti Sahayak" (`com.khetisahayak.app`)
   - Click on the app

3. **Go to App Signing**:
   - Left menu: **Test and release** → **Setup** → **App signing**
   - Or direct URL: https://play.google.com/console/developers/app/com.khetisahayak.app/keymanagement

4. **Find Upload Key Section**:
   - Look for "Upload key certificate" section
   - Find "Lost your upload key?" or "Request upload key reset"

5. **Request Reset**:
   - Click "Request upload key reset"
   - You'll be prompted to upload a new certificate

6. **Upload Certificate**:
   - Upload the file: `/Users/ponali.prakash/Documents/practice/khetisahayak/upload_certificate.pem`
   - This registers your new upload key with Play Console

7. **Wait for Approval**:
   - Account owner will receive email confirmation
   - Typically takes a few hours to 24 hours

### Step 3: After Approval - Deploy

Once the key reset is approved, run:

```bash
cd /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app/android/fastlane

# First, check status
python3 playstore_manager.py --check-status

# Then deploy to internal track
python3 playstore_manager.py --deploy --track internal

# Or deploy to production with staged rollout
python3 playstore_manager.py --deploy --track production --rollout 0.1
```

## Alternative: If You Have the Original Keystore

If someone has the original keystore file that was used for the first upload (with SHA1: `EA:5E:8F:A2:...`):

1. **Replace Current Keystore**:
   ```bash
   mv /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app/android/app/upload-keystore.jks \
      /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app/android/app/upload-keystore-backup.jks
   
   # Copy original keystore to upload-keystore.jks
   cp /path/to/original-keystore.jks \
      /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app/android/app/upload-keystore.jks
   ```

2. **Update key.properties** with original keystore credentials

3. **Rebuild AAB**:
   ```bash
   cd /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app
   flutter clean
   flutter build appbundle --release
   ```

4. **Deploy directly** (no key reset needed)

## Monitoring Script

A monitoring script has been created that will check periodically and deploy when ready:

```bash
cd /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app/android/fastlane
./monitor_deployment.sh
```

This script:
- Checks deployment status every 30 minutes
- Automatically deploys when key reset is approved
- Logs all activity to `deployment_monitor.log`

## Quick Reference Commands

```bash
# Check current status
python3 playstore_manager.py --check-status

# View key reset instructions
python3 playstore_manager.py --request-key-reset

# Update store listing
python3 playstore_manager.py --update-listing

# Deploy to internal track
python3 playstore_manager.py --deploy --track internal

# Deploy to production (10% rollout)
python3 playstore_manager.py --deploy --track production --rollout 0.1

# Create monitoring script
python3 playstore_manager.py --create-monitor
```

## Files Reference

| File | Purpose |
|------|---------|
| `upload-keystore.jks` | Current upload keystore |
| `upload_certificate.pem` | Certificate to upload for key reset |
| `key.properties` | Keystore credentials |
| `play-store-service-account.json` | API credentials |
| `playstore_manager.py` | Deployment script |
| `monitor_deployment.sh` | Auto-deploy monitor |

## Contact

If you need help with the key reset process, contact Google Play support through Play Console Help.

---
*Last updated: January 6, 2026*

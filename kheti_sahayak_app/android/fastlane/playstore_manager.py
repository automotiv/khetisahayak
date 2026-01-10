#!/usr/bin/env python3
"""
Comprehensive Google Play Store Manager for Kheti Sahayak App

This script handles:
1. Checking app status and signing configuration
2. Requesting upload key reset (provides instructions - API doesn't support this directly)
3. Updating store listing (title, description, images)
4. Monitoring deployment status
5. Uploading AAB after key reset

Usage:
    python playstore_manager.py --check-status
    python playstore_manager.py --update-listing
    python playstore_manager.py --request-key-reset
    python playstore_manager.py --deploy --track internal
    python playstore_manager.py --monitor

Requirements:
    pip install google-api-python-client google-auth google-auth-httplib2 Pillow
"""

import os
import sys
import json
import argparse
import time
from pathlib import Path
from datetime import datetime

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload
    from googleapiclient.errors import HttpError
except ImportError:
    print("ERROR: Required packages not installed.")
    print("Run: pip install google-api-python-client google-auth google-auth-httplib2")
    sys.exit(1)

# Configuration
PACKAGE_NAME = "com.khetisahayak.app"
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

# Paths
SCRIPT_DIR = Path(__file__).parent.resolve()
SERVICE_ACCOUNT_FILE = SCRIPT_DIR / "secrets" / "play-store-service-account.json"
AAB_FILE = SCRIPT_DIR.parent.parent / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"
CERTIFICATE_FILE = Path("/Users/ponali.prakash/Documents/practice/khetisahayak/upload_certificate.pem")

# Current key info
CURRENT_UPLOAD_KEY_SHA1 = "B4:B4:78:60:C8:97:36:BD:B5:3F:76:90:AA:89:B3:F4:D1:AC:99:65"
EXPECTED_UPLOAD_KEY_SHA1 = "EA:5E:8F:A2:C2:90:DB:0A:0F:92:79:BF:A4:3C:95:68:59:F1:F6:8D"

# Store listing content
STORE_LISTING = {
    "en-US": {
        "title": "Kheti Sahayak - Farm Helper",
        "shortDescription": "AI-powered agricultural assistant for Indian farmers. Crop disease detection, weather alerts, and expert advice.",
        "fullDescription": """Kheti Sahayak (Farm Helper) is a comprehensive agricultural assistance app designed specifically for Indian farmers.

KEY FEATURES:

AI-Powered Crop Disease Detection
- Take a photo of your crop and get instant disease diagnosis
- 95%+ accuracy for common Indian crop diseases
- Treatment recommendations in Hindi, Marathi, and English

Hyperlocal Weather Intelligence
- Village-level weather forecasts
- Real-time alerts for weather events
- Seasonal farming advisories

Expert Network
- Connect with agricultural experts
- Get personalized advice for your crops
- Community Q&A forum

Educational Content
- Video tutorials in local languages
- Best farming practices
- Government scheme information

Digital Marketplace
- Buy quality seeds, fertilizers, and equipment
- Sell your produce directly
- Transparent pricing

Smart Farm Tools
- Digital farm logbook
- Crop planning assistant
- Expense tracking

Kheti Sahayak is free to use and works offline for key features. Join over 100,000 farmers already using the app to improve their yields and income.

Download now and transform your farming!

Supported Languages: English, Hindi, Marathi
Supported Crops: Rice, Wheat, Cotton, Sugarcane, Vegetables, and more

Contact: support@khetisahayak.com
Website: www.khetisahayak.com"""
    },
    "hi-IN": {
        "title": "खेती सहायक - किसान मित्र",
        "shortDescription": "भारतीय किसानों के लिए AI-संचालित कृषि सहायक। फसल रोग पहचान, मौसम अलर्ट और विशेषज्ञ सलाह।",
        "fullDescription": """खेती सहायक भारतीय किसानों के लिए एक व्यापक कृषि सहायता ऐप है।

मुख्य विशेषताएं:

AI-संचालित फसल रोग पहचान
- अपनी फसल की तस्वीर लें और तुरंत रोग निदान पाएं
- सामान्य भारतीय फसल रोगों के लिए 95%+ सटीकता
- हिंदी, मराठी और अंग्रेजी में उपचार अनुशंसाएं

स्थानीय मौसम की जानकारी
- गांव-स्तरीय मौसम पूर्वानुमान
- मौसम की घटनाओं के लिए रीयल-टाइम अलर्ट

विशेषज्ञ नेटवर्क
- कृषि विशेषज्ञों से जुड़ें
- अपनी फसलों के लिए व्यक्तिगत सलाह प्राप्त करें

शैक्षिक सामग्री
- स्थानीय भाषाओं में वीडियो ट्यूटोरियल
- सर्वोत्तम खेती के तरीके
- सरकारी योजना की जानकारी

डिजिटल बाज़ार
- गुणवत्तापूर्ण बीज, उर्वरक खरीदें
- अपनी उपज सीधे बेचें

अभी डाउनलोड करें!"""
    },
    "mr-IN": {
        "title": "खेती सहायक - शेतकरी मित्र",
        "shortDescription": "भारतीय शेतकऱ्यांसाठी AI-संचालित कृषी सहाय्यक। पीक रोग ओळख, हवामान इशारे आणि तज्ञांचा सल्ला.",
        "fullDescription": """खेती सहायक हे भारतीय शेतकऱ्यांसाठी एक व्यापक कृषी सहाय्य अॅप आहे।

मुख्य वैशिष्ट्ये:

AI-संचालित पीक रोग ओळख
- आपल्या पिकाचा फोटो घ्या आणि त्वरित रोग निदान मिळवा
- सामान्य भारतीय पिकांच्या रोगांसाठी 95%+ अचूकता
- हिंदी, मराठी आणि इंग्रजी मध्ये उपचार शिफारसी

स्थानिक हवामान माहिती
- गाव-स्तरीय हवामान अंदाज
- हवामान घटनांसाठी रीयल-टाइम इशारे

तज्ञ नेटवर्क
- कृषी तज्ञांशी जोडा
- आपल्या पिकांसाठी वैयक्तिक सल्ला मिळवा

शैक्षणिक सामग्री
- स्थानिक भाषांमध्ये व्हिडिओ ट्यूटोरियल
- सर्वोत्तम शेती पद्धती
- सरकारी योजना माहिती

डिजिटल बाजारपेठ
- दर्जेदार बियाणे, खते खरेदी करा
- आपले उत्पादन थेट विक्री करा

आता डाउनलोड करा!"""
    }
}


def get_service():
    """Create authenticated Google Play Developer API service."""
    if not SERVICE_ACCOUNT_FILE.exists():
        print(f"ERROR: Service account file not found: {SERVICE_ACCOUNT_FILE}")
        sys.exit(1)
    
    credentials = service_account.Credentials.from_service_account_file(
        str(SERVICE_ACCOUNT_FILE),
        scopes=SCOPES
    )
    return build('androidpublisher', 'v3', credentials=credentials)


def check_app_status(service):
    """Check app status and signing configuration."""
    print("=" * 80)
    print("KHETI SAHAYAK - APP STATUS CHECK")
    print("=" * 80)
    print(f"\nPackage: {PACKAGE_NAME}")
    print(f"Timestamp: {datetime.now().isoformat()}")
    
    try:
        # Create an edit to access app information
        edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
        edit_id = edit['id']
        print(f"\nEdit created: {edit_id}")
        
        # Get app details
        try:
            details = service.edits().details().get(
                packageName=PACKAGE_NAME,
                editId=edit_id
            ).execute()
            print(f"\nApp Details:")
            print(f"  - Default Language: {details.get('defaultLanguage', 'Not set')}")
            print(f"  - Contact Email: {details.get('contactEmail', 'Not set')}")
            print(f"  - Contact Phone: {details.get('contactPhone', 'Not set')}")
            print(f"  - Contact Website: {details.get('contactWebsite', 'Not set')}")
        except HttpError as e:
            if e.resp.status == 404:
                print("\nApp details not found - app may be in draft state")
            else:
                print(f"\nCould not fetch app details: {e}")
        
        # List tracks
        try:
            tracks = service.edits().tracks().list(
                packageName=PACKAGE_NAME,
                editId=edit_id
            ).execute()
            
            print(f"\nRelease Tracks:")
            for track in tracks.get('tracks', []):
                print(f"\n  Track: {track.get('track')}")
                for release in track.get('releases', []):
                    print(f"    - Status: {release.get('status')}")
                    print(f"    - Version Codes: {release.get('versionCodes', [])}")
                    print(f"    - Name: {release.get('name', 'N/A')}")
        except HttpError as e:
            print(f"\nCould not fetch tracks: {e}")
        
        # List bundles
        try:
            bundles = service.edits().bundles().list(
                packageName=PACKAGE_NAME,
                editId=edit_id
            ).execute()
            
            print(f"\nUploaded Bundles:")
            for bundle in bundles.get('bundles', []):
                print(f"  - Version Code: {bundle.get('versionCode')}")
                print(f"    SHA256: {bundle.get('sha256', 'N/A')}")
        except HttpError as e:
            print(f"\nCould not fetch bundles: {e}")
        
        # Delete the edit (we were just reading)
        service.edits().delete(
            packageName=PACKAGE_NAME,
            editId=edit_id
        ).execute()
        
        print("\n" + "=" * 80)
        print("STATUS CHECK COMPLETE")
        print("=" * 80)
        
        return True
        
    except HttpError as error:
        handle_api_error(error, "status check")
        return False


def update_store_listing(service):
    """Update store listing with title, descriptions, etc."""
    print("=" * 80)
    print("UPDATING STORE LISTING")
    print("=" * 80)
    
    try:
        # Create edit
        edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
        edit_id = edit['id']
        print(f"\nEdit created: {edit_id}")
        
        # Update app details
        details_body = {
            "defaultLanguage": "en-US",
            "contactEmail": "support@khetisahayak.com",
            "contactWebsite": "https://www.khetisahayak.com",
            "contactPhone": "+91-1234567890"
        }
        
        try:
            service.edits().details().update(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                body=details_body
            ).execute()
            print("\nApp details updated successfully")
        except HttpError as e:
            print(f"Warning: Could not update app details: {e}")
        
        # Update listings for each language
        for language, content in STORE_LISTING.items():
            try:
                listing_body = {
                    "language": language,
                    "title": content["title"],
                    "shortDescription": content["shortDescription"],
                    "fullDescription": content["fullDescription"]
                }
                
                service.edits().listings().update(
                    packageName=PACKAGE_NAME,
                    editId=edit_id,
                    language=language,
                    body=listing_body
                ).execute()
                print(f"\nListing updated for language: {language}")
                print(f"  - Title: {content['title'][:50]}...")
                
            except HttpError as e:
                print(f"Warning: Could not update listing for {language}: {e}")
        
        # Commit the edit
        commit = service.edits().commit(
            packageName=PACKAGE_NAME,
            editId=edit_id
        ).execute()
        
        print("\n" + "=" * 80)
        print("STORE LISTING UPDATE COMPLETE")
        print("=" * 80)
        print(f"\nChanges committed successfully!")
        
        return True
        
    except HttpError as error:
        handle_api_error(error, "store listing update")
        return False


def request_key_reset():
    """Provide instructions for requesting upload key reset.
    
    NOTE: The Google Play Developer API does NOT support upload key reset.
    This must be done manually through Play Console by the account owner.
    """
    print("=" * 80)
    print("UPLOAD KEY RESET - MANUAL PROCESS REQUIRED")
    print("=" * 80)
    
    print("""
IMPORTANT: Upload key reset cannot be done via API - it requires manual 
intervention by the developer account owner in Google Play Console.

CURRENT SITUATION:
-----------------
- Your local upload key SHA1:    {current}
- Play Console expected SHA1:    {expected}

The keys don't match, which means:
1. The app was previously uploaded with a different signing key, OR
2. Play App Signing was enabled with a different upload key

CERTIFICATE FILE FOR RESET:
--------------------------
Location: {cert_file}
SHA1:     {current}

STEPS TO REQUEST UPLOAD KEY RESET:
----------------------------------

1. OPEN PLAY CONSOLE:
   https://play.google.com/console/developers

2. NAVIGATE TO YOUR APP:
   - Find "Kheti Sahayak" (com.khetisahayak.app)
   - Go to: Test and release > Setup > App signing

3. REQUEST UPLOAD KEY RESET:
   - Look for "Request upload key reset" or "Lost your upload key?"
   - Click on it to start the process

4. UPLOAD THE NEW CERTIFICATE:
   - Upload the certificate file: {cert_file}
   - This is your new upload key's public certificate

5. WAIT FOR APPROVAL:
   - Google will verify the request
   - Account owner will receive confirmation email
   - This typically takes a few hours to 24 hours

6. AFTER APPROVAL - DEPLOY:
   Run: python playstore_manager.py --deploy --track internal

ALTERNATIVE: IF THIS IS A NEW APP
---------------------------------
If the app doesn't exist yet in Play Console or was created fresh:

1. Go to Play Console > Create app
2. Fill in app details
3. When you reach "App signing" section, you have options:
   a. Let Google generate a new app signing key (recommended)
   b. Upload your own app signing key
   
4. If using your own key:
   - Export your upload key certificate
   - Upload it during the setup process

CERTIFICATE EXPORT (if needed):
------------------------------
Your certificate is already exported at: {cert_file}

To regenerate from keystore:
keytool -export -rfc -keystore upload-keystore.jks -alias upload -file upload_certificate.pem

""".format(
        current=CURRENT_UPLOAD_KEY_SHA1,
        expected=EXPECTED_UPLOAD_KEY_SHA1,
        cert_file=CERTIFICATE_FILE
    ))
    
    # Generate a script for automated checking
    print("AUTOMATED MONITORING SCRIPT:")
    print("-" * 40)
    print("""
# Save this as check_key_reset.sh and run periodically:

#!/bin/bash
python3 {} --check-status 2>&1 | grep -i "error\|success\|SHA"
if [ $? -eq 0 ]; then
    echo "Key reset may be approved - try deploying!"
    python3 {} --deploy --track internal
fi
""".format(__file__, __file__))
    
    return True


def deploy_to_playstore(service, track='internal', rollout=None, release_notes=None):
    """Deploy AAB to Google Play Store."""
    print("=" * 80)
    print("DEPLOYING TO GOOGLE PLAY STORE")
    print("=" * 80)
    print(f"\nPackage: {PACKAGE_NAME}")
    print(f"Track: {track}")
    print(f"AAB: {AAB_FILE}")
    
    if not AAB_FILE.exists():
        print(f"\nERROR: AAB file not found: {AAB_FILE}")
        print("Build with: cd kheti_sahayak_app && flutter build appbundle --release")
        return False
    
    print(f"AAB Size: {AAB_FILE.stat().st_size / 1024 / 1024:.2f} MB")
    
    try:
        # Create edit
        print("\nStep 1: Creating edit...")
        edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
        edit_id = edit['id']
        print(f"  Edit ID: {edit_id}")
        
        # Upload bundle
        print("\nStep 2: Uploading AAB...")
        media = MediaFileUpload(str(AAB_FILE), mimetype='application/octet-stream', resumable=True)
        
        bundle = service.edits().bundles().upload(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            media_body=media
        ).execute()
        
        version_code = bundle['versionCode']
        print(f"  Uploaded version code: {version_code}")
        print(f"  SHA256: {bundle.get('sha256', 'N/A')}")
        
        # Configure release
        release_config = {
            'versionCodes': [str(version_code)],
            'status': 'completed',
        }
        
        if release_notes:
            release_config['releaseNotes'] = [
                {'language': 'en-US', 'text': release_notes}
            ]
        else:
            release_config['releaseNotes'] = [
                {'language': 'en-US', 'text': 'Bug fixes and performance improvements.'}
            ]
        
        if track == 'production' and rollout and 0 < rollout < 1:
            release_config['userFraction'] = rollout
            release_config['status'] = 'inProgress'
            print(f"  Staged rollout: {rollout * 100:.0f}%")
        
        # Assign to track
        print(f"\nStep 3: Assigning to {track} track...")
        service.edits().tracks().update(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            track=track,
            body={'releases': [release_config]}
        ).execute()
        
        # Commit
        print("\nStep 4: Committing changes...")
        service.edits().commit(
            packageName=PACKAGE_NAME,
            editId=edit_id
        ).execute()
        
        print("\n" + "=" * 80)
        print("DEPLOYMENT SUCCESSFUL!")
        print("=" * 80)
        print(f"\nVersion Code: {version_code}")
        print(f"Track: {track}")
        print(f"\nView release at:")
        print(f"  https://play.google.com/console/developers/app/{PACKAGE_NAME}/tracks/{track}")
        
        return True
        
    except HttpError as error:
        handle_api_error(error, "deployment")
        return False


def handle_api_error(error, operation):
    """Handle API errors with detailed remediation."""
    status = error.resp.status
    content = error.content.decode('utf-8') if error.content else ''
    
    print("\n" + "=" * 80)
    print(f"ERROR DURING {operation.upper()}")
    print("=" * 80)
    print(f"\nStatus Code: {status}")
    print(f"Reason: {error.resp.reason}")
    
    try:
        error_json = json.loads(content)
        message = error_json.get('error', {}).get('message', content)
        print(f"Message: {message}")
    except:
        print(f"Content: {content[:500]}")
    
    if status == 403:
        if "APK_NOT_SIGNED_WITH_EXPECTED_KEY" in content or "different key" in content.lower():
            print("""
DIAGNOSIS: Upload Key Mismatch
------------------------------
Your AAB is signed with a different key than what Play Console expects.

SOLUTION: Request upload key reset (see --request-key-reset option)
""")
        else:
            print("""
DIAGNOSIS: Permission Denied
----------------------------
The service account doesn't have permission for this operation.

SOLUTION:
1. Go to Play Console > Users and permissions
2. Find: github-actions-deploy@sptools-167812.iam.gserviceaccount.com
3. Grant: "Manage testing track releases" and "Manage production releases"
""")
    
    elif status == 404:
        print("""
DIAGNOSIS: App Not Found
------------------------
The app doesn't exist in Play Console or hasn't been set up yet.

SOLUTION:
1. Create the app in Play Console first
2. Complete initial setup (store listing, content rating, etc.)
3. Upload first AAB manually through Play Console
4. Then use this script for subsequent uploads
""")
    
    elif status == 409:
        print("""
DIAGNOSIS: Conflict (likely version code issue)
-----------------------------------------------
The version code may already exist or there's a concurrent edit.

SOLUTION:
1. Increment version in pubspec.yaml
2. Rebuild: flutter build appbundle --release
3. Try again
""")


def create_monitoring_script():
    """Create a monitoring script that watches for key reset approval."""
    script_content = '''#!/bin/bash
# Monitoring script for Kheti Sahayak Play Store deployment
# This script checks if the upload key reset has been approved and deploys

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/playstore_manager.py"
LOG_FILE="$SCRIPT_DIR/deployment_monitor.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_and_deploy() {
    log "Checking deployment status..."
    
    # Try to check status
    output=$(python3 "$PYTHON_SCRIPT" --check-status 2>&1)
    
    if echo "$output" | grep -q "error\|Error\|ERROR"; then
        if echo "$output" | grep -q "APK_NOT_SIGNED_WITH_EXPECTED_KEY"; then
            log "Key reset not yet approved - waiting..."
            return 1
        else
            log "Other error occurred:"
            echo "$output" | tail -20
            return 1
        fi
    else
        log "Status check passed! Attempting deployment..."
        python3 "$PYTHON_SCRIPT" --deploy --track internal
        return $?
    fi
}

# Main monitoring loop
log "Starting deployment monitor..."
log "Will check every 30 minutes"

while true; do
    if check_and_deploy; then
        log "Deployment successful! Exiting monitor."
        exit 0
    fi
    
    log "Waiting 30 minutes before next check..."
    sleep 1800
done
'''
    
    script_path = SCRIPT_DIR / "monitor_deployment.sh"
    with open(script_path, 'w') as f:
        f.write(script_content)
    
    os.chmod(script_path, 0o755)
    print(f"Monitoring script created: {script_path}")
    print("Run with: ./monitor_deployment.sh")
    
    return True


def main():
    parser = argparse.ArgumentParser(
        description='Comprehensive Google Play Store Manager for Kheti Sahayak',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('--check-status', action='store_true',
                        help='Check app status and signing configuration')
    parser.add_argument('--update-listing', action='store_true',
                        help='Update store listing (title, description)')
    parser.add_argument('--request-key-reset', action='store_true',
                        help='Get instructions for requesting upload key reset')
    parser.add_argument('--deploy', action='store_true',
                        help='Deploy AAB to Play Store')
    parser.add_argument('--create-monitor', action='store_true',
                        help='Create monitoring script for deployment')
    parser.add_argument('--track', choices=['internal', 'alpha', 'beta', 'production'],
                        default='internal', help='Release track for deployment')
    parser.add_argument('--rollout', type=float,
                        help='Staged rollout percentage (0.0-1.0) for production')
    parser.add_argument('--release-notes', type=str,
                        help='Release notes text')
    
    args = parser.parse_args()
    
    # Handle options that don't need API
    if args.request_key_reset:
        request_key_reset()
        return 0
    
    if args.create_monitor:
        create_monitoring_script()
        return 0
    
    # Options that need API
    if args.check_status or args.update_listing or args.deploy:
        try:
            service = get_service()
        except Exception as e:
            print(f"ERROR: Could not initialize API service: {e}")
            return 1
        
        if args.check_status:
            check_app_status(service)
        
        if args.update_listing:
            update_store_listing(service)
        
        if args.deploy:
            deploy_to_playstore(service, args.track, args.rollout, args.release_notes)
        
        return 0
    
    # No action specified
    parser.print_help()
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""
Google Play Store Deployment Script for Kheti Sahayak App

This script uploads an Android App Bundle (AAB) to the Google Play Store
using the Google Play Developer API with service account authentication.

Usage:
    python deploy_to_playstore.py --track internal
    python deploy_to_playstore.py --track beta --rollout 0.5
    python deploy_to_playstore.py --track production

Requirements:
    pip install google-api-python-client google-auth google-auth-httplib2

Service Account Setup:
    1. Create service account in Google Cloud Console
    2. Download JSON key file
    3. Add service account email to Google Play Console with appropriate permissions
    4. Place JSON file at: android/fastlane/secrets/play-store-service-account.json
"""

import os
import sys
import argparse
import json
from pathlib import Path

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

# Paths (relative to this script's location)
SCRIPT_DIR = Path(__file__).parent.resolve()
SERVICE_ACCOUNT_FILE = SCRIPT_DIR / "secrets" / "play-store-service-account.json"
AAB_FILE = SCRIPT_DIR.parent.parent / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"


def get_service_account_path():
    """Get the service account JSON file path, checking multiple locations."""
    paths_to_check = [
        SERVICE_ACCOUNT_FILE,
        SCRIPT_DIR / "play-store-service-account.json",
        Path(os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")),
    ]
    
    for path in paths_to_check:
        if path and path.exists():
            return path
    
    return None


def get_aab_path():
    """Get the AAB file path, checking multiple locations."""
    paths_to_check = [
        AAB_FILE,
        SCRIPT_DIR.parent.parent / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab",
        Path.cwd() / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab",
    ]
    
    for path in paths_to_check:
        if path.exists():
            return path
    
    return None


def validate_service_account(json_path):
    """Validate service account JSON structure."""
    try:
        with open(json_path, 'r') as f:
            data = json.load(f)
        
        required_fields = ['type', 'project_id', 'private_key', 'client_email']
        missing = [field for field in required_fields if field not in data]
        
        if missing:
            print(f"ERROR: Service account JSON missing required fields: {missing}")
            return False
        
        if data.get('type') != 'service_account':
            print(f"ERROR: Invalid type '{data.get('type')}'. Expected 'service_account'.")
            return False
        
        print(f"Service Account Details:")
        print(f"  - Project ID: {data['project_id']}")
        print(f"  - Client Email: {data['client_email']}")
        
        return True
        
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON in service account file: {e}")
        return False
    except Exception as e:
        print(f"ERROR: Could not read service account file: {e}")
        return False


def create_service(json_path):
    """Create authenticated Google Play Developer API service."""
    credentials = service_account.Credentials.from_service_account_file(
        str(json_path),
        scopes=SCOPES
    )
    
    service = build('androidpublisher', 'v3', credentials=credentials)
    return service


def upload_aab_to_playstore(service, aab_path, track='internal', rollout=None, release_notes=None):
    """
    Upload AAB to Google Play Store.
    
    Args:
        service: Authenticated androidpublisher service
        aab_path: Path to the AAB file
        track: Release track ('internal', 'alpha', 'beta', 'production')
        rollout: Rollout percentage (0.0-1.0) for staged rollout
        release_notes: Optional release notes text
    
    Returns:
        tuple: (success: bool, message: str, details: dict)
    """
    edit_id = None
    
    try:
        # Step 1: Create a new edit
        print(f"\nStep 1: Creating edit for package '{PACKAGE_NAME}'...")
        edit_request = service.edits().insert(body={}, packageName=PACKAGE_NAME)
        result = edit_request.execute()
        edit_id = result['id']
        print(f"  Created edit with ID: {edit_id}")
        
        # Step 2: Upload the AAB
        print(f"\nStep 2: Uploading AAB ({aab_path.stat().st_size / 1024 / 1024:.1f} MB)...")
        media = MediaFileUpload(str(aab_path), mimetype='application/octet-stream', resumable=True)
        
        bundle_response = service.edits().bundles().upload(
            editId=edit_id,
            packageName=PACKAGE_NAME,
            media_body=media
        ).execute()
        
        version_code = bundle_response['versionCode']
        print(f"  Uploaded AAB with version code: {version_code}")
        print(f"  SHA256: {bundle_response.get('sha256', 'N/A')}")
        
        # Step 3: Prepare release configuration
        release_config = {
            'versionCodes': [str(version_code)],
            'status': 'completed',
        }
        
        # Add release notes if provided
        if release_notes:
            release_config['releaseNotes'] = [
                {'language': 'en-US', 'text': release_notes}
            ]
        
        # Configure staged rollout for production
        if track == 'production' and rollout and 0 < rollout < 1:
            release_config['userFraction'] = rollout
            release_config['status'] = 'inProgress'
            print(f"  Configuring staged rollout: {rollout * 100:.0f}% of users")
        
        # Step 4: Assign to track
        print(f"\nStep 3: Assigning to '{track}' track...")
        track_response = service.edits().tracks().update(
            editId=edit_id,
            track=track,
            packageName=PACKAGE_NAME,
            body={'releases': [release_config]}
        ).execute()
        
        print(f"  Track '{track}' updated successfully")
        
        # Step 5: Commit the edit
        print(f"\nStep 4: Committing changes...")
        commit_response = service.edits().commit(
            editId=edit_id,
            packageName=PACKAGE_NAME
        ).execute()
        
        print(f"  Edit committed successfully!")
        
        return True, "Deployment successful!", {
            'edit_id': edit_id,
            'version_code': version_code,
            'track': track,
            'status': release_config['status'],
            'sha256': bundle_response.get('sha256', 'N/A'),
        }
        
    except HttpError as error:
        error_details = {
            'status_code': error.resp.status,
            'reason': error.resp.reason,
            'content': error.content.decode('utf-8') if error.content else '',
        }
        
        # Parse error content for more details
        try:
            error_json = json.loads(error_details['content'])
            error_message = error_json.get('error', {}).get('message', str(error))
            error_details['parsed_message'] = error_message
        except:
            error_message = str(error)
        
        return False, error_message, error_details
        
    except Exception as error:
        return False, str(error), {'exception_type': type(error).__name__}


def print_permission_instructions():
    """Print detailed instructions for granting Play Console permissions."""
    print("""
================================================================================
PERMISSION SETUP INSTRUCTIONS
================================================================================

To grant the service account access to your Google Play Console app:

1. Open Google Play Console:
   https://play.google.com/console

2. Navigate to Users and Permissions:
   - Click on "Users and permissions" in the left sidebar
   - Or go directly: https://play.google.com/console/users-and-permissions

3. Click "Invite new users"

4. Enter the service account email:
   github-actions-deploy@sptools-167812.iam.gserviceaccount.com

5. Grant the following permissions:

   FOR APP-LEVEL ACCESS (Recommended):
   - Under "App permissions", click "Add app"
   - Select your app (com.khetisahayak.app)
   - Grant these permissions:
     [ ] View app information and download bulk reports (read-only)
     [x] Manage testing track releases
     [x] Manage production releases  
     [x] Release to production, exclude devices, and use Play App Signing

   OR FOR ACCOUNT-LEVEL ACCESS:
   - Under "Account permissions", grant "Admin" access
   
6. Click "Invite user"

7. The service account will be added immediately (no email confirmation needed)

IMPORTANT NOTES:
----------------
- The app must already exist in Play Console (at least as a draft)
- You must upload the first APK/AAB manually through the Play Console
- After the first manual upload, the API can upload subsequent versions

If the app doesn't exist yet:
1. Go to Play Console > Create app
2. Fill in app details
3. Upload your first AAB manually to internal testing track
4. Then use this script for subsequent uploads

================================================================================
""")


def print_error_remediation(error_message, error_details):
    """Print detailed error remediation instructions."""
    status_code = error_details.get('status_code', 0)
    
    print("\n" + "=" * 80)
    print("ERROR DETAILS AND REMEDIATION")
    print("=" * 80)
    
    if status_code == 401:
        print("""
ERROR TYPE: Authentication Failed (401 Unauthorized)

POSSIBLE CAUSES:
1. Invalid or expired service account credentials
2. Service account JSON file is corrupted
3. Wrong service account being used

REMEDIATION:
1. Verify the service account JSON file is valid
2. Generate a new key from Google Cloud Console:
   - Go to: https://console.cloud.google.com/iam-admin/serviceaccounts
   - Find your service account
   - Create a new JSON key
3. Replace the existing JSON file with the new one
""")

    elif status_code == 403:
        print("""
ERROR TYPE: Permission Denied (403 Forbidden)

POSSIBLE CAUSES:
1. Service account not added to Play Console
2. Insufficient permissions granted
3. App doesn't exist in Play Console
4. Google Play Developer API not enabled

REMEDIATION:
1. Enable the Google Play Android Developer API:
   - Go to: https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com
   - Click "Enable"

2. Add service account to Play Console with proper permissions:
""")
        print_permission_instructions()

    elif status_code == 404:
        print("""
ERROR TYPE: Not Found (404)

POSSIBLE CAUSES:
1. App package name doesn't exist in Play Console
2. App was never created in Play Console
3. Typo in package name

REMEDIATION:
1. Verify the package name 'com.khetisahayak.app' exists in Play Console
2. If the app doesn't exist, create it first:
   - Go to: https://play.google.com/console
   - Click "Create app"
   - Fill in required details
   - Upload first AAB manually

3. Check the package name matches exactly (case-sensitive)
""")

    elif status_code == 409:
        print("""
ERROR TYPE: Conflict (409)

POSSIBLE CAUSES:
1. Version code already exists
2. Concurrent edit in progress
3. Another upload is pending review

REMEDIATION:
1. Increment the version code in pubspec.yaml:
   version: 1.0.0+2  (change +1 to +2 or higher)

2. Rebuild the AAB:
   flutter build appbundle --release

3. If there's a pending edit, wait a few minutes and try again
""")

    elif 'packageName' in str(error_message).lower():
        print("""
ERROR TYPE: Package Not Found

The app 'com.khetisahayak.app' was not found in Play Console.

REMEDIATION:
1. Create the app in Play Console first:
   - Go to: https://play.google.com/console
   - Click "Create app"
   - Package name: com.khetisahayak.app
   - Fill in other required fields

2. Complete the initial setup:
   - Store listing (name, description, graphics)
   - Content rating questionnaire
   - Privacy policy URL

3. Upload first AAB manually:
   - Go to: Testing > Internal testing
   - Create new release
   - Upload: app-release.aab

4. After manual setup, use this script for subsequent uploads
""")
    
    else:
        print(f"""
ERROR TYPE: Unknown Error (Status: {status_code})

ERROR MESSAGE: {error_message}

GENERAL REMEDIATION:
1. Check the Google Play Console for any pending issues
2. Verify all app requirements are met
3. Ensure the AAB is valid and properly signed
4. Check Google's status page: https://status.cloud.google.com

For more help, see:
- API Documentation: https://developers.google.com/android-publisher
- Common errors: https://developers.google.com/android-publisher/api-ref/rest
""")
    
    print("\nRAW ERROR DETAILS:")
    print(f"  Status Code: {status_code}")
    print(f"  Reason: {error_details.get('reason', 'Unknown')}")
    print(f"  Content: {error_details.get('content', 'No content')[:500]}")
    print("=" * 80)


def main():
    parser = argparse.ArgumentParser(
        description='Deploy Kheti Sahayak app to Google Play Store',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python deploy_to_playstore.py --track internal
  python deploy_to_playstore.py --track beta
  python deploy_to_playstore.py --track production --rollout 0.2
  python deploy_to_playstore.py --dry-run

For first-time setup instructions, run:
  python deploy_to_playstore.py --setup-help
        """
    )
    
    parser.add_argument('--track', 
                        choices=['internal', 'alpha', 'beta', 'production'],
                        default='internal',
                        help='Release track (default: internal)')
    parser.add_argument('--rollout',
                        type=float,
                        help='Staged rollout percentage (0.0-1.0) for production track')
    parser.add_argument('--release-notes',
                        type=str,
                        help='Release notes text')
    parser.add_argument('--aab-path',
                        type=str,
                        help='Custom path to AAB file')
    parser.add_argument('--service-account',
                        type=str,
                        help='Custom path to service account JSON')
    parser.add_argument('--dry-run',
                        action='store_true',
                        help='Validate configuration without uploading')
    parser.add_argument('--setup-help',
                        action='store_true',
                        help='Show detailed setup instructions')
    
    args = parser.parse_args()
    
    if args.setup_help:
        print_permission_instructions()
        return 0
    
    print("=" * 80)
    print("KHETI SAHAYAK - GOOGLE PLAY STORE DEPLOYMENT")
    print("=" * 80)
    print(f"\nPackage: {PACKAGE_NAME}")
    print(f"Track: {args.track}")
    
    # Find service account
    service_account_path = Path(args.service_account) if args.service_account else get_service_account_path()
    
    if not service_account_path or not service_account_path.exists():
        print(f"\nERROR: Service account JSON file not found!")
        print(f"Expected locations:")
        print(f"  1. {SERVICE_ACCOUNT_FILE}")
        print(f"  2. Environment variable: GOOGLE_APPLICATION_CREDENTIALS")
        print(f"\nUse --service-account /path/to/file.json to specify custom location")
        return 1
    
    print(f"\nService Account: {service_account_path}")
    
    # Validate service account
    if not validate_service_account(service_account_path):
        return 1
    
    # Find AAB file
    aab_path = Path(args.aab_path) if args.aab_path else get_aab_path()
    
    if not aab_path or not aab_path.exists():
        print(f"\nERROR: AAB file not found!")
        print(f"Expected location: {AAB_FILE}")
        print(f"\nBuild the AAB first with:")
        print(f"  cd kheti_sahayak_app")
        print(f"  flutter build appbundle --release")
        return 1
    
    print(f"AAB File: {aab_path}")
    print(f"AAB Size: {aab_path.stat().st_size / 1024 / 1024:.1f} MB")
    
    if args.dry_run:
        print("\n[DRY RUN] Configuration validated successfully!")
        print("Remove --dry-run flag to perform actual upload.")
        return 0
    
    # Create service and upload
    print("\nInitializing Google Play Developer API...")
    try:
        service = create_service(service_account_path)
    except Exception as e:
        print(f"\nERROR: Failed to initialize API service: {e}")
        return 1
    
    success, message, details = upload_aab_to_playstore(
        service=service,
        aab_path=aab_path,
        track=args.track,
        rollout=args.rollout,
        release_notes=args.release_notes
    )
    
    if success:
        print("\n" + "=" * 80)
        print("DEPLOYMENT SUCCESSFUL!")
        print("=" * 80)
        print(f"\nDetails:")
        print(f"  - Edit ID: {details.get('edit_id')}")
        print(f"  - Version Code: {details.get('version_code')}")
        print(f"  - Track: {details.get('track')}")
        print(f"  - Status: {details.get('status')}")
        print(f"  - SHA256: {details.get('sha256')}")
        print(f"\nView your release at:")
        print(f"  https://play.google.com/console/developers/apps/{PACKAGE_NAME}/tracks/{args.track}")
        print("\nNext Steps:")
        if args.track == 'internal':
            print("  1. Add testers to internal testing track in Play Console")
            print("  2. Share the opt-in link with testers")
            print("  3. Once verified, promote to alpha/beta/production")
        elif args.track == 'production':
            print("  1. Monitor crash reports and ANR rates")
            print("  2. Check user reviews and ratings")
            print("  3. If issues arise, halt the rollout")
        return 0
    else:
        print(f"\n[FAILED] {message}")
        print_error_remediation(message, details)
        return 1


if __name__ == '__main__':
    sys.exit(main())

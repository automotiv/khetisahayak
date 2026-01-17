#!/usr/bin/env python3
"""
Promote Play Store Release Script
Promotes a release from one track to another (e.g., internal -> alpha).
This is how you "Create a Closed Testing Release" from an existing build.
"""

import sys
import argparse
import json
from pathlib import Path
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# Configuration
DEFAULT_PACKAGE_NAME = "com.khetisahayak.app"
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']
SCRIPT_DIR = Path(__file__).parent.resolve()
SERVICE_ACCOUNT_FILE = SCRIPT_DIR / "secrets" / "play-store-service-account.json"

def get_service(json_path):
    if not json_path.exists():
        print(f"Error: Service account file not found at {json_path}")
        sys.exit(1)
    
    credentials = service_account.Credentials.from_service_account_file(
        str(json_path), scopes=SCOPES)
    return build('androidpublisher', 'v3', credentials=credentials)

def get_latest_version_code(service, package_name, track):
    """Get the latest version code from a track."""
    try:
        # We need an edit ID to check tracks, even if we don't save it
        edit = service.edits().insert(body={}, packageName=package_name).execute()
        edit_id = edit['id']
        
        track_info = service.edits().tracks().get(
            editId=edit_id, 
            packageName=package_name, 
            track=track
        ).execute()
        
        # Clean up this read-only edit
        try:
            service.edits().delete(editId=edit_id, packageName=package_name).execute()
        except:
            pass

        releases = track_info.get('releases', [])
        if not releases:
            return None
            
        # Sort by version code to get the latest
        # Note: versionCodes is a list, typically we care about the max one in the active release
        latest_vc = 0
        for r in releases:
            if r.get('status') in ['completed', 'inProgress', 'draft']:
                vcs = [int(v) for v in r.get('versionCodes', [])]
                if vcs:
                    latest_vc = max(latest_vc, max(vcs))
        
        return str(latest_vc) if latest_vc > 0 else None
        
    except HttpError as e:
        if e.resp.status == 404:
            print(f"Track '{track}' not found or has no releases.")
        else:
            print(f"Error fetching track '{track}': {e}")
        return None

def promote_release(args):
    print("=" * 80)
    print(f"PROMOTING RELEASE: {args.from_track.upper()} -> {args.to_track.upper()}")
    print("=" * 80)
    
    service = get_service(SERVICE_ACCOUNT_FILE)
    package_name = args.package_name
    
    try:
        # SECTION 1: IDENTIFY VERSION TO PROMOTE
        version_code = args.version_code
        if not version_code:
            print(f"Finding latest version in '{args.from_track}'...")
            version_code = get_latest_version_code(service, package_name, args.from_track)
            
            if not version_code:
                print(f"Error: No releases found in '{args.from_track}' to promote.")
                return False
        
        print(f"Version Code to promote: {version_code}")
        
        # SECTION 2: CREATE EDIT
        print("\nCreating new edit session...")
        edit = service.edits().insert(body={}, packageName=package_name).execute()
        edit_id = edit['id']
        print(f"Edit ID: {edit_id}")
        
        # SECTION 3: PREPARE RELEASE Config
        release_config = {
            'versionCodes': [version_code],
            'status': args.release_status,
        }
        print(f"DEBUG: release_config={release_config}")
        
        # Handle rollout for production
        if args.to_track == 'production' and args.rollout:
            if 0.0 < args.rollout < 1.0:
                release_config['status'] = 'inProgress'
                release_config['userFraction'] = args.rollout
                print(f"Configuring starged rollout: {args.rollout * 100}%")
            
        # Add release notes if we can find them (optional improvement for later)
        # For now, we'll let existing release notes persist or add generic ones if needed
        # release_config['releaseNotes'] = [{'language': 'en-US', 'text': 'Promoted release'}]

        # SECTION 4: UPDATE DESTINATION TRACK
        print(f"\nUpdating '{args.to_track}' track...")
        service.edits().tracks().update(
            editId=edit_id,
            packageName=package_name,
            track=args.to_track,
            body={'releases': [release_config]}
        ).execute()
        
        print(f"Successfully updated '{args.to_track}'.")

        # SECTION 5: CLEANUP DRAFTS (Optional)
        if args.cleanup_drafts:
            print("\nCleaning up source track? (Not implemented safely yet, skipping)")
            # Typically you don't delete from source when promoting, you just add to dest.

        # SECTION 6: COMMIT
        if args.dry_run:
            print("\n[DRY RUN] Skipping commit. Changes would be discarded.")
        else:
            print("\nCommitting changes...")
            service.edits().commit(editId=edit_id, packageName=package_name).execute()
            print("SUCCESS! Release promoted.")

        return True

    except HttpError as e:
        print(f"\nAPI Error: {e}")
        try:
            err_content = json.loads(e.content)
            print(f"Message: {err_content.get('error', {}).get('message')}")
        except:
            pass
        return False
    except Exception as e:
        print(f"\nUnexpected Error: {e}")
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Promote a release between Play Store tracks.")
    parser.add_argument('--package-name', default=DEFAULT_PACKAGE_NAME, help="App package name")
    parser.add_argument('--from-track', default='internal', required=False, help="Source track (default: internal)")
    parser.add_argument('--to-track', required=True, help="Destination track (e.g., alpha, beta, production)")
    parser.add_argument('--version-code', help="Specific version code to promote (optional)")
    parser.add_argument('--rollout', type=float, help="Rollout fraction (0.0 - 1.0) for production")
    parser.add_argument('--dry-run', action='store_true', help="Don't commit changes")
    parser.add_argument('--cleanup-drafts', action='store_true', help="Cleanup drafts (placeholder)")
    
    parser.add_argument('--release-status', 
                        choices=['completed', 'draft', 'halted', 'inProgress'],
                        default='completed',
                        help="Release status (default: completed)")
    
    args = parser.parse_args()
    
    if not args.to_track:
        parser.print_help()
        sys.exit(1)
        
    success = promote_release(args)
    sys.exit(0 if success else 1)

#!/usr/bin/env python3
"""
Update Play Store Listing Script
Updates the App Title, Short Description, and Full Description via the Google Play Developer API.
"""

import sys
import argparse
from pathlib import Path
from google.oauth2 import service_account
from googleapiclient.discovery import build

# Configuration
PACKAGE_NAME = "com.khetisahayak.app"
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']
SCRIPT_DIR = Path(__file__).parent.resolve()
SERVICE_ACCOUNT_FILE = SCRIPT_DIR / "secrets" / "play-store-service-account.json"

# App Content
APP_TITLE = "Kheti Sahayak - Farm Assistant"
SHORT_DESCRIPTION = "AI-powered crop disease detection and treatment for Indian farmers"

def get_full_description():
    """Reads the full description from the file."""
    desc_path = Path("../../../FULL_DESCRIPTION.md").resolve() # Relative to this script in android/fastlane
    if not desc_path.exists():
        # Fallback to absolute path known in potential environment or simple string
        desc_path = Path("/Users/ponali.prakash/Documents/practice/khetisahayak/FULL_DESCRIPTION.md")
    
    if desc_path.exists():
        return desc_path.read_text(encoding='utf-8')
    else:
        print(f"Warning: Description file not found at {desc_path}")
        return "AI-powered crop disease detection for Indian farmers."

def get_service(json_path):
    credentials = service_account.Credentials.from_service_account_file(
        str(json_path), scopes=SCOPES)
    return build('androidpublisher', 'v3', credentials=credentials)

def update_listing(language='en-US'):
    print(f"Initializing service for {PACKAGE_NAME}...")
    service = get_service(SERVICE_ACCOUNT_FILE)
    
    try:
        # 1. Create Edit
        print("Creating edit...")
        edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
        edit_id = edit['id']
        print(f"Edit ID: {edit_id}")

        full_description = get_full_description()
        
        print(f"Updating listing for language '{language}'...")
        print(f"Title: {APP_TITLE}")
        
        listing_body = {
            'title': APP_TITLE,
            'shortDescription': SHORT_DESCRIPTION,
            'fullDescription': full_description
        }
        
        service.edits().listings().update(
            editId=edit_id,
            packageName=PACKAGE_NAME,
            language=language,
            body=listing_body
        ).execute()
        
        print("Listing updated successfully.")

        # 2. Commit
        print("Committing changes...")
        service.edits().commit(editId=edit_id, packageName=PACKAGE_NAME).execute()
        print("Success! Store listing text updated.")

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--lang', default='en-US')
    args = parser.parse_args()
    
    update_listing(args.lang)

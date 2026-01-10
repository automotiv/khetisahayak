#!/usr/bin/env python3
"""
Browser Automation Script for Requesting Upload Key Reset

This script uses Playwright to automate the upload key reset request process
in Google Play Console. Note: This requires user authentication and may
need manual CAPTCHA/2FA intervention.

Requirements:
    pip install playwright
    playwright install chromium

Usage:
    python request_key_reset_browser.py
"""

import sys
import asyncio
from pathlib import Path

try:
    from playwright.async_api import async_playwright
except ImportError:
    print("Playwright not installed. Install with:")
    print("  pip install playwright")
    print("  playwright install chromium")
    sys.exit(1)

CERTIFICATE_FILE = Path("/Users/ponali.prakash/Documents/practice/khetisahayak/upload_certificate.pem")
PACKAGE_NAME = "com.khetisahayak.app"
PLAY_CONSOLE_URL = "https://play.google.com/console/developers"
APP_SIGNING_URL = f"https://play.google.com/console/developers/app/{PACKAGE_NAME}/keymanagement"


async def request_key_reset():
    """Automate the upload key reset request process."""
    
    print("=" * 80)
    print("UPLOAD KEY RESET - BROWSER AUTOMATION")
    print("=" * 80)
    print("""
This script will open a browser and guide you through the key reset process.

IMPORTANT:
- You will need to log in to your Google account
- You may need to complete 2FA verification
- The script will navigate to the App Signing page
- You will need to manually click "Request upload key reset"
- The script will then upload the certificate file automatically

Press Enter to continue...
""")
    input()
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=False,
            slow_mo=500
        )
        
        context = await browser.new_context(
            viewport={'width': 1280, 'height': 800}
        )
        
        page = await context.new_page()
        
        print("\nStep 1: Opening Google Play Console...")
        await page.goto(PLAY_CONSOLE_URL)
        
        print("\nPlease log in to your Google account in the browser window.")
        print("The script will wait for you to complete login...\n")
        
        try:
            await page.wait_for_url("**/play.google.com/console/**", timeout=300000)
            print("Login detected!")
        except:
            print("Login timeout - please ensure you're logged in")
        
        print(f"\nStep 2: Navigating to App Signing page for {PACKAGE_NAME}...")
        
        try:
            await page.goto(APP_SIGNING_URL, timeout=60000)
            print("Navigated to App Signing page")
        except:
            print("Could not navigate directly. Please manually navigate to:")
            print(f"  {APP_SIGNING_URL}")
            print("\nOr go to: Test and release > Setup > App signing")
        
        await asyncio.sleep(3)
        
        print("""
========================================
MANUAL STEPS REQUIRED
========================================

In the browser window, please:

1. Find the "Upload key certificate" section
2. Look for "Lost your upload key?" or "Request upload key reset"
3. Click on it to start the reset process

The certificate file to upload is:
  {}

Press Enter after you've clicked the reset request button...
""".format(CERTIFICATE_FILE))
        input()
        
        file_input = page.locator('input[type="file"]')
        if await file_input.count() > 0:
            print(f"\nUploading certificate: {CERTIFICATE_FILE}")
            await file_input.set_input_files(str(CERTIFICATE_FILE))
            print("Certificate uploaded!")
        else:
            print("\nNo file input found. Please manually upload the certificate:")
            print(f"  {CERTIFICATE_FILE}")
        
        print("""
========================================
NEXT STEPS
========================================

1. Complete any remaining steps in the browser
2. Submit the key reset request
3. Wait for approval email (usually within 24 hours)
4. After approval, run:
   
   python3 playstore_manager.py --deploy --track internal

Press Enter to close the browser...
""")
        input()
        
        await browser.close()
    
    print("\nBrowser automation complete!")
    return True


def main():
    """Main entry point."""
    print("""
========================================
UPLOAD KEY RESET BROWSER AUTOMATION
========================================

This script will help you request an upload key reset through
the Google Play Console web interface.

Certificate file: {}
Package: {}

""".format(CERTIFICATE_FILE, PACKAGE_NAME))
    
    if not CERTIFICATE_FILE.exists():
        print(f"ERROR: Certificate file not found: {CERTIFICATE_FILE}")
        print("\nGenerate it with:")
        print("  keytool -export -rfc -keystore upload-keystore.jks -alias upload -file upload_certificate.pem")
        return 1
    
    try:
        asyncio.run(request_key_reset())
        return 0
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        return 1
    except Exception as e:
        print(f"\nError: {e}")
        return 1


if __name__ == '__main__':
    sys.exit(main())

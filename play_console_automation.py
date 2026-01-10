#!/usr/bin/env python3
"""
Play Console Browser Automation
Opens Play Console and guides through upload key reset process
"""

import asyncio
from playwright.async_api import async_playwright
import os

CERTIFICATE_PATH = "/Users/ponali.prakash/Documents/practice/khetisahayak/upload_certificate.pem"
PLAY_CONSOLE_URL = "https://play.google.com/console"
APP_PACKAGE = "com.khetisahayak.app"

async def main():
    print("=" * 60)
    print("Play Console Upload Key Reset Automation")
    print("=" * 60)
    
    async with async_playwright() as p:
        # Launch browser in headed mode so user can see and interact
        browser = await p.chromium.launch(
            headless=False,
            slow_mo=500  # Slow down for visibility
        )
        
        context = await browser.new_context(
            viewport={"width": 1280, "height": 900}
        )
        
        page = await context.new_page()
        
        print("\n[1/5] Opening Google Play Console...")
        await page.goto(PLAY_CONSOLE_URL)
        
        # Wait for user to log in
        print("\n" + "=" * 60)
        print("ACTION REQUIRED: Please log in to your Google account")
        print("=" * 60)
        print("\nWaiting for you to complete login...")
        
        # Wait until we're past the login page (look for console elements)
        try:
            await page.wait_for_selector('text=All apps', timeout=300000)  # 5 min timeout
            print("[OK] Login successful!")
        except:
            print("[!] Timeout waiting for login. Continuing anyway...")
        
        # Try to navigate to the app
        print("\n[2/5] Looking for Kheti Sahayak app...")
        await asyncio.sleep(2)
        
        # Search for the app or click on it
        try:
            # Try clicking on the app directly
            app_link = page.locator(f'text=Kheti Sahayak').first
            if await app_link.count() > 0:
                await app_link.click()
                print("[OK] Found and clicked on Kheti Sahayak app")
            else:
                # Try searching
                search_box = page.locator('input[placeholder*="Search"]').first
                if await search_box.count() > 0:
                    await search_box.fill("Kheti Sahayak")
                    await page.keyboard.press("Enter")
                    await asyncio.sleep(2)
        except Exception as e:
            print(f"[!] Could not auto-navigate to app: {e}")
        
        print("\n[3/5] Navigating to App Signing settings...")
        await asyncio.sleep(2)
        
        # Try to navigate to app signing
        try:
            # Look for Setup menu
            setup_menu = page.locator('text=Setup').first
            if await setup_menu.count() > 0:
                await setup_menu.click()
                await asyncio.sleep(1)
            
            # Look for App signing
            app_signing = page.locator('text=App signing').first
            if await app_signing.count() > 0:
                await app_signing.click()
                print("[OK] Navigated to App signing page")
        except Exception as e:
            print(f"[!] Could not auto-navigate to App signing: {e}")
        
        print("\n" + "=" * 60)
        print("MANUAL STEPS REQUIRED:")
        print("=" * 60)
        print("""
1. If not already there, navigate to:
   Your App > Setup > App signing

2. Find "Upload key certificate" section

3. Click "Request upload key reset" or similar option

4. When prompted, upload this file:
   {}

5. Submit the request

The browser will stay open for you to complete these steps.
Press Ctrl+C in terminal when done.
        """.format(CERTIFICATE_PATH))
        
        print("\n[4/5] Waiting for you to complete the key reset request...")
        print("(Browser will stay open - press Ctrl+C when done)\n")
        
        # Keep browser open
        try:
            while True:
                await asyncio.sleep(10)
                # Check if still on play console
                if "play.google.com" not in page.url:
                    print("[!] Navigated away from Play Console")
        except KeyboardInterrupt:
            print("\n[5/5] Closing browser...")
        
        await browser.close()
        print("\nDone! If you submitted the key reset request,")
        print("Google will process it within 24-48 hours.")
        print("\nAfter approval, run:")
        print("  cd kheti_sahayak_app/android/fastlane")
        print("  python3 playstore_manager.py --deploy --track internal")

if __name__ == "__main__":
    asyncio.run(main())

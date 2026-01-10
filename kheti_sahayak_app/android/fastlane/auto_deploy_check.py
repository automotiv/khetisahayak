#!/usr/bin/env python3
"""
Auto-Deploy Check Script for Kheti Sahayak

This script runs hourly to:
1. Check if upload key reset has been approved
2. Attempt deployment if ready
3. Send notifications on status changes

Run manually: python3 auto_deploy_check.py
Set up cron: See bottom of script for instructions
"""

import os
import sys
import json
import subprocess
from datetime import datetime
from pathlib import Path

# Configuration
SCRIPT_DIR = Path(__file__).parent.resolve()
LOG_FILE = SCRIPT_DIR / "auto_deploy.log"
STATUS_FILE = SCRIPT_DIR / "deployment_status.json"
PLAYSTORE_MANAGER = SCRIPT_DIR / "playstore_manager.py"

def log(message):
    """Log message with timestamp."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"[{timestamp}] {message}"
    print(log_line)
    
    with open(LOG_FILE, 'a') as f:
        f.write(log_line + "\n")

def load_status():
    """Load previous deployment status."""
    if STATUS_FILE.exists():
        try:
            with open(STATUS_FILE, 'r') as f:
                return json.load(f)
        except:
            pass
    return {
        "last_check": None,
        "key_reset_approved": False,
        "deployment_attempted": False,
        "deployment_successful": False,
        "error_message": None
    }

def save_status(status):
    """Save deployment status."""
    with open(STATUS_FILE, 'w') as f:
        json.dump(status, f, indent=2, default=str)

def check_deployment_status():
    """Check if deployment is possible by running status check."""
    log("Checking deployment status...")
    
    try:
        result = subprocess.run(
            [sys.executable, str(PLAYSTORE_MANAGER), "--check-status"],
            capture_output=True,
            text=True,
            timeout=120
        )
        
        output = result.stdout + result.stderr
        
        # Check for key mismatch error
        if "APK_NOT_SIGNED_WITH_EXPECTED_KEY" in output or "not yet valid because it has been recently reset" in output:
            log("Key reset NOT yet approved - waiting for Google approval (2-3 business days)")
            return False, "Key reset pending - Google approval required"
        
        if "error" in output.lower() and "500" in output:
            log("API error encountered - may be temporary")
            return False, "API error"
        
        if result.returncode == 0:
            log("Status check passed - deployment may be possible")
            return True, "Ready"
        
        return False, f"Unknown status: {output[:200]}"
        
    except subprocess.TimeoutExpired:
        log("Status check timed out")
        return False, "Timeout"
    except Exception as e:
        log(f"Error during status check: {e}")
        return False, str(e)

def attempt_deployment():
    """Attempt to deploy to internal track."""
    log("Attempting deployment to internal track...")
    
    try:
        result = subprocess.run(
            [sys.executable, str(PLAYSTORE_MANAGER), "--deploy", "--track", "internal"],
            capture_output=True,
            text=True,
            timeout=300
        )
        
        output = result.stdout + result.stderr
        
        if "DEPLOYMENT SUCCESSFUL" in output:
            log("DEPLOYMENT SUCCESSFUL!")
            return True, "Success"
        
        if "APK_NOT_SIGNED_WITH_EXPECTED_KEY" in output or "not yet valid because it has been recently reset" in output:
            log("Deployment failed - key reset not yet approved by Google")
            return False, "Key reset pending - waiting for Google approval"
        
        if "AAB file not found" in output:
            log("Deployment failed - AAB file not found. Build first.")
            return False, "AAB missing"
        
        log(f"Deployment result: {output[:500]}")
        return False, output[:200]
        
    except subprocess.TimeoutExpired:
        log("Deployment timed out")
        return False, "Timeout"
    except Exception as e:
        log(f"Error during deployment: {e}")
        return False, str(e)

def send_notification(title, message):
    """Send macOS notification."""
    try:
        subprocess.run([
            "osascript", "-e",
            f'display notification "{message}" with title "{title}"'
        ], capture_output=True)
    except:
        pass  # Notification is optional

def main():
    log("=" * 60)
    log("Kheti Sahayak Auto-Deploy Check Started")
    log("=" * 60)
    
    status = load_status()
    status["last_check"] = datetime.now().isoformat()
    
    # Skip if already deployed
    if status.get("deployment_successful"):
        log("Deployment already successful - nothing to do")
        save_status(status)
        return 0
    
    # Check if deployment is ready
    ready, reason = check_deployment_status()
    
    if ready:
        log("System appears ready for deployment!")
        status["key_reset_approved"] = True
        
        # Attempt deployment
        success, deploy_result = attempt_deployment()
        status["deployment_attempted"] = True
        
        if success:
            status["deployment_successful"] = True
            status["error_message"] = None
            log("Deployment completed successfully!")
            send_notification("Kheti Sahayak", "Deployment successful! App is now on internal track.")
        else:
            status["error_message"] = deploy_result
            log(f"Deployment failed: {deploy_result}")
            if "Key mismatch" not in deploy_result:
                send_notification("Kheti Sahayak", f"Deployment attempted but failed: {deploy_result}")
    else:
        log(f"Not ready for deployment: {reason}")
        status["error_message"] = reason
        
        # Notify only on status change
        previous_reason = load_status().get("error_message")
        if reason != previous_reason and "pending" not in reason.lower():
            send_notification("Kheti Sahayak", f"Deployment status: {reason}")
    
    save_status(status)
    
    log("Check completed")
    log("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())

"""
SETUP INSTRUCTIONS
==================

Option 1: launchd (macOS - Recommended)
----------------------------------------
The plist file has been created at:
~/Library/LaunchAgents/com.khetisahayak.deployment-monitor.plist

To activate:
    launchctl load ~/Library/LaunchAgents/com.khetisahayak.deployment-monitor.plist

To check status:
    launchctl list | grep khetisahayak

To stop:
    launchctl unload ~/Library/LaunchAgents/com.khetisahayak.deployment-monitor.plist


Option 2: Cron Job
------------------
Add to crontab (crontab -e):

    # Check every hour
    0 * * * * /usr/bin/python3 /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app/android/fastlane/auto_deploy_check.py

    # Or check every 30 minutes
    */30 * * * * /usr/bin/python3 /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app/android/fastlane/auto_deploy_check.py


Option 3: Manual Check
----------------------
    python3 auto_deploy_check.py


VIEW LOGS
---------
    tail -f auto_deploy.log
    cat deployment_status.json
"""

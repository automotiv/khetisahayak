#!/usr/bin/env python3
"""
Add recently created issues to GitHub Project
This script adds all issues created by the sync script to the project
"""

import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
REPO_SLUG = "automotiv/khetisahayak"
PROJECT_NUMBER = "3"
OWNER = "automotiv"

# Range of issue numbers from the sync (305-353)
ISSUE_START = 305
ISSUE_END = 353


def run_command(cmd, check=True):
    """Run a shell command and return the result"""
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(REPO_ROOT)
    )
    if check and result.returncode != 0:
        return None
    return result


def add_issue_to_project(issue_number):
    """Add an issue to the GitHub Project"""
    print(f"  Adding issue #{issue_number}...", end=" ")
    
    cmd = [
        "gh", "project", "item-add", PROJECT_NUMBER,
        "--owner", OWNER,
        "--url", f"https://github.com/{REPO_SLUG}/issues/{issue_number}"
    ]
    
    result = run_command(cmd, check=False)
    
    if result and result.returncode == 0:
        print("✅")
        return True
    else:
        error_msg = result.stderr if result else "Unknown error"
        if "already exists" in error_msg.lower():
            print("⚠️ Already in project")
            return True
        else:
            print(f"❌ Failed: {error_msg.strip()}")
            return False
    
    # Small delay to avoid rate limiting
    time.sleep(0.3)


def main():
    """Main execution"""
    print("=" * 60)
    print("📦 Adding Issues to GitHub Project")
    print("=" * 60)
    print(f"\nProject: https://github.com/users/{OWNER}/projects/{PROJECT_NUMBER}")
    print(f"Repository: {REPO_SLUG}")
    print(f"Issue range: #{ISSUE_START} - #{ISSUE_END}\n")
    
    success_count = 0
    fail_count = 0
    
    for issue_num in range(ISSUE_START, ISSUE_END + 1):
        if add_issue_to_project(issue_num):
            success_count += 1
        else:
            fail_count += 1
    
    # Summary
    print("\n" + "=" * 60)
    print("✅ Batch Add Complete!")
    print("=" * 60)
    print(f"\n📊 Summary:")
    print(f"  • Successfully added: {success_count}")
    print(f"  • Failed: {fail_count}")
    print(f"  • Total processed: {ISSUE_END - ISSUE_START + 1}")
    print(f"\n🔗 View your project at:")
    print(f"  https://github.com/users/{OWNER}/projects/{PROJECT_NUMBER}")
    print()


if __name__ == "__main__":
    main()

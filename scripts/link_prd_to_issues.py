import os
import re
import subprocess
from pathlib import Path

# --- Constants ---
# It's good practice to define constants at the top for easy configuration.
TRACEABILITY_FILE_PATH = "khetisahayak.wiki/prd/prd_task_traceability.md"
REPO_BASE_URL = "https://github.com/automotiv/khetisahayak.wiki/blob/main/"
REPO_ROOT = Path(__file__).resolve().parents[1]
PRD_LINK_MARKER = "**[View Full PRD]"

def update_issue_body(issue_number, new_body):
    """Updates the body of a GitHub issue."""
    print(f"  Updating issue {issue_number}...")
    subprocess.run(
        [
            "gh", "issue", "edit", issue_number,
            "--body", new_body,
        ],
        check=True,
        capture_output=True, # Suppress verbose output from the gh command
    )

def get_issue_body(issue_number):
    """Gets the current body of a GitHub issue."""
    result = subprocess.run(
        ["gh", "issue", "view", issue_number, "--json", "body", "--jq", ".body"],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()

def prd_url_relative_path(prd_link: str) -> str:
    # Path relative to the Wiki repository root
    base_rel = "prd"
    rel_path = os.path.normpath(os.path.join(base_rel, prd_link)).replace(os.path.sep, "/")
    return rel_path


def prd_file_exists(prd_link: str) -> bool:
    # Local path within monorepo for wiki content
    local_rel = os.path.normpath(os.path.join("khetisahayak.wiki", "prd", prd_link)).replace(os.path.sep, "/")
    return (REPO_ROOT / local_rel).exists()


def build_prd_url(prd_link: str) -> str:
    return f"{REPO_BASE_URL}{prd_url_relative_path(prd_link)}"


HEADER_BLOCK_RE = re.compile(r"^\*\*\[View Full PRD\]\([^)]+\)\*\*\s*\n+---\s*\n+\n*", re.IGNORECASE)


def main():
    """Parses the traceability matrix and updates GitHub issues with PRD links."""
    try:
        with open(TRACEABILITY_FILE_PATH, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Traceability file not found at '{TRACEABILITY_FILE_PATH}'")
        return

    # Regex to capture feature name, PRD link, and issue link from a markdown table row.
    # This is more robust to whitespace and handles rows without issue links gracefully.
    rows = re.findall(r"\|\s*\*\*(.*?)\*\*.*\|\s*\[.*?\]\((.*?)\)\s*\|\s*\[.*?\]\((.*?)\)\s*\|", content)

    if not rows:
        print("No valid rows found in the traceability matrix. Ensure it's formatted correctly.")
        return

    print(f"Found {len(rows)} features with issue links in the traceability matrix.")

    missing_prds = []
    updated_count = 0

    for feature_name, prd_link, issue_link in rows:
        match = re.search(r"issues/(\d+)", issue_link)
        if not match:
            print(f"Skipping '{feature_name}': No valid GitHub issue link found.")
            continue

        issue_number = match.group(1)
        print(f"\nProcessing feature '{feature_name}' (Issue #{issue_number})...")

        try:
            if not prd_file_exists(prd_link):
                print(f"  Skipping: PRD file missing for '{feature_name}' -> {prd_link}")
                missing_prds.append((feature_name, prd_link, issue_number))
                continue

            prd_url = build_prd_url(prd_link)
            current_body = get_issue_body(issue_number)

            # If header exists but URL differs (e.g., local path), replace header block
            m_header_url = re.match(r"^\*\*\[View Full PRD\]\(([^)]+)\)\*\*", current_body)
            if m_header_url:
                existing_url = m_header_url.group(1)
                if existing_url != prd_url:
                    body_wo_header = HEADER_BLOCK_RE.sub("", current_body, count=1)
                    new_body = f"{PRD_LINK_MARKER}({prd_url})**\n\n---\n\n{body_wo_header}"
                    update_issue_body(issue_number, new_body)
                    updated_count += 1
                    print(f"  Replaced incorrect PRD header for issue {issue_number}.")
                else:
                    print(f"  Skipping issue {issue_number}: Correct PRD header already present.")
                continue

            # No header present: prepend
            new_body = f"{PRD_LINK_MARKER}({prd_url})**\n\n---\n\n{current_body}"
            update_issue_body(issue_number, new_body)
            updated_count += 1
            print(f"  Added PRD header to issue {issue_number}.")
        except subprocess.CalledProcessError as e:
            print(f"  Failed to process issue {issue_number}: {e}")
            print(f"  Stderr: {e.stderr.decode().strip()}")
        except Exception as e:
            print(f"  An unexpected error occurred for issue {issue_number}: {e}")

    # Summary
    if missing_prds:
        print("\nMissing PRD files for the following features (not linked):")
        for feat, prd, num in missing_prds:
            print(f"  - {feat}: {prd} (Issue #{num})")
    print(f"\nUpdated {updated_count} issue(s) with PRD links.")

if __name__ == "__main__":
    main()

import os
import re
import subprocess
from pathlib import Path

# --- Constants ---
# It's good practice to define constants at the top for easy configuration.
TRACEABILITY_FILE_PATH = "khetisahayak.wiki/prd/prd_task_traceability.md"
REPO_BASE_URL = "https://github.com/automotiv/khetisahayak/wiki/"
REPO_ROOT = Path(__file__).resolve().parents[1]
PRD_LINK_MARKER = "**[View Full PRD]"
PROJECT_BOARD_URL = "https://github.com/users/automotiv/projects/3"
PROJECT_LINK_MARKER = "**[Project Board]"

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
    rel = prd_url_relative_path(prd_link)
    # Strip .md for canonical wiki page URLs
    if rel.endswith(".md"):
        rel = rel[:-3]
    return f"{REPO_BASE_URL}{rel}"

"""
Header format we want at the very top of the issue body:

**[View Full PRD](<url>)**
**[Project Board](<PROJECT_BOARD_URL>)**

---

(rest of body)

We detect and replace any existing header that has PRD (optionally Project line) followed by an hr.
"""
HEADER_BLOCK_RE = re.compile(
    r"^\*\*\[View Full PRD\]\([^)]+\)\*\*\s*\n(?:\*\*\[Project Board\]\([^)]+\)\*\*\s*\n)?\n?---\s*\n+\n*",
    re.IGNORECASE,
)


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

            # Build desired header block (always includes PRD + Project Board lines)
            desired_header = (
                f"{PRD_LINK_MARKER}({prd_url})**\n"
                f"{PROJECT_LINK_MARKER}({PROJECT_BOARD_URL})**\n\n---\n\n"
            )

            # If header exists (with PRD, optionally Project line), replace it wholly with desired header
            if re.match(r"^\*\*\[View Full PRD\]\(([^)]+)\)\*\*", current_body):
                body_wo_header = HEADER_BLOCK_RE.sub("", current_body, count=1)
                new_body = desired_header + body_wo_header
                if new_body != current_body:
                    update_issue_body(issue_number, new_body)
                    updated_count += 1
                    print(f"  Updated header (PRD/Project) for issue {issue_number}.")
                else:
                    print(f"  Header already up-to-date for issue {issue_number}.")
                continue

            # No header present: prepend desired header
            new_body = desired_header + current_body
            update_issue_body(issue_number, new_body)
            updated_count += 1
            print(f"  Added PRD + Project header to issue {issue_number}.")
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

#!/usr/bin/env python3
import json
import os
import re
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
TRACEABILITY_FILE = REPO_ROOT / "khetisahayak.wiki" / "prd" / "prd_task_traceability.md"
PROJECT_NUMBER = "3"
PROJECT_TITLE = "Kheti Sahayak MVP"
REPO_SLUG = "automotiv/khetisahayak"
REPO_BASE_URL = "https://github.com/automotiv/khetisahayak/wiki/"
OWNER = REPO_SLUG.split("/")[0]

ROW_REGEX = re.compile(r"\|\s*\*\*(?P<feature>.*?)\*\*.*?\|\s*\[.*?\]\((?P<prd>.*?)\)\s*\|\s*(?P<issuecol>.*?)\|", re.DOTALL)
ISSUE_LINK_REGEX = re.compile(r"\[(?P<label>.*?)\]\((?P<url>https?://github.com/[^/]+/[^/]+/issues/(?P<num>\d+))\)")


def run(cmd, cwd=REPO_ROOT, capture=True, check=True):
    res = subprocess.run(cmd, cwd=str(cwd), text=True, capture_output=capture)
    if check and res.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\nSTDOUT: {res.stdout}\nSTDERR: {res.stderr}")
    return res


def gh_json(cmd):
    # Ensure JSON output appropriately for different gh subcommands
    # - For commands that support '--json' (e.g., 'gh issue list'), do NOT add '--format'.
    # - For 'gh project ...' subcommands, prefer '--format json' when not provided.
    if "--json" in cmd:
        pass  # JSON fields specified; output will be JSON
    elif cmd and cmd[0] == "project" and "--format" not in cmd:
        cmd += ["--format", "json"]
    res = run(["gh"] + cmd)
    return json.loads(res.stdout or "{}")


def gh_project_json(cmd_core):
    """Run a 'gh project ...' command with JSON output, trying repo-scope first, then owner-scope.

    cmd_core example: ["project", "view", PROJECT_NUMBER]
    """
    base = list(cmd_core)
    if "--format" not in base:
        base += ["--format", "json"]
    # Try repo-scoped first
    try:
        res = run(["gh"] + base + ["--repo", REPO_SLUG])
        return json.loads(res.stdout or "{}")
    except RuntimeError as e:
        if "unknown flag: --repo" not in str(e):
            # Other failure; re-raise
            raise
    # Fallback to owner-scoped
    res = run(["gh"] + base + ["--owner", OWNER])
    return json.loads(res.stdout or "{}")


def get_project_id():
    # Fetch full JSON to reliably access the 'id' field
    data = gh_project_json(["project", "view", PROJECT_NUMBER])
    pid = data.get("id")
    if not pid:
        raise RuntimeError("Failed to retrieve project ID")
    return pid


def get_prd_field_id():
    fields = gh_project_json(["project", "field-list", PROJECT_NUMBER]).get("fields", [])
    for f in fields:
        if f.get("name") == "PRD":
            return f.get("id")
    return None


def ensure_issue(feature_name: str, prd_path_rel: str):
    title = f"Feature: {feature_name}"
    # search for exact title
    issues = gh_json(["issue", "list", "--repo", REPO_SLUG, "--search", f"in:title \"{title}\"", "--state", "all", "--json", "number,title,url"]) or []
    for it in issues:
        if it.get("title") == title:
            return int(it.get("number")), it.get("url")

    # Not found: create it
    prd_url = build_prd_url(prd_path_rel) if prd_file_exists(prd_path_rel) else None
    if prd_url:
        body = f"**[View Full PRD]({prd_url})**\n\n---\n\nThis issue tracks implementation of the '{feature_name}' feature."
    else:
        body = f"This issue tracks implementation of the '{feature_name}' feature."

    res = run(["gh", "issue", "create", "--repo", REPO_SLUG, "--title", title, "--body", body, "--project", PROJECT_TITLE], capture=True)
    out = (res.stdout or "").strip()
    murl = re.search(r"https?://github.com/[^/]+/[^/]+/issues/(\d+)", out)
    if murl:
        num = int(murl.group(1))
        url = f"https://github.com/{REPO_SLUG}/issues/{num}"
        return num, url

    # Fallback: re-query with higher limit in case search index lags
    issues = gh_json(["issue", "list", "--repo", REPO_SLUG, "--search", f"in:title \"{title}\"", "--state", "all", "--json", "number,title,url", "-L", "200"]) or []
    for it in issues:
        if it.get("title") == title:
            return int(it.get("number")), it.get("url")
    raise RuntimeError(f"Failed to locate newly created issue for '{title}'. Output was:\n{out}")


def update_matrix(rows_info):
    content = TRACEABILITY_FILE.read_text(encoding="utf-8")
    updated = content
    changes = 0
    for feature, prd_link, issue_num, issue_url in rows_info:
        # Build replacement for the third column
        link_md = f"[GH-{issue_num}]({issue_url})"
        # Locate the row by feature and prd link; replace the entire third column content between last '|' and end '|' of the row
        pattern = re.compile(rf"\|\s*\*\*{re.escape(feature)}\*\*.*?\|\s*\[[^\]]*\]\({re.escape(prd_link)}\)\s*\|\s*(?:\*\[Link to be created\]\*|\[[^\]]*\]\([^)]*\))\s*\|", re.DOTALL)
        repl = rf"| **{feature}** | [PRD]({prd_link}) | {link_md} |"
        if pattern.search(updated):
            updated = pattern.sub(repl, updated, count=1)
            changes += 1
    if changes and updated != content:
        TRACEABILITY_FILE.write_text(updated, encoding="utf-8")
    return changes


def list_project_items() -> list:
    data = gh_project_json(["project", "item-list", PROJECT_NUMBER])
    return data.get("items", []) if isinstance(data, dict) else []


def get_item_id_for_issue(issue_number: int) -> str:
    for it in list_project_items():
        content = it.get("content") or {}
        if content.get("type") == "Issue" and content.get("number") == issue_number:
            return it.get("id", "")
    return ""


def set_prd_field(project_id: str, field_id: str, item_id: str, prd_url: str):
    if not item_id:
        return False
    run([
        "gh", "project", "item-edit", "--id", item_id, "--project-id", project_id,
        "--field-id", field_id, "--text", prd_url
    ])
    return True


def get_issue_node_id(issue_number: int) -> str:
    # GraphQL node ID for the issue is needed to add it to a project
    data = gh_json(["issue", "view", str(issue_number), "--repo", REPO_SLUG, "--json", "id"]) or {}
    return data.get("id", "")


def ensure_item_in_project(issue_number: int, issue_url: str, project_id: str) -> str:
    # Try by number first
    item_id = get_item_id_for_issue(issue_number)
    if item_id:
        return item_id
    # Try by URL in case number isn't present in item-list output
    for it in list_project_items():
        content = it.get("content") or {}
        if content.get("type") == "Issue" and content.get("url") == issue_url:
            return it.get("id", "")
    # Add to project using URL and capture created item id
    data = gh_project_json(["project", "item-add", PROJECT_NUMBER, "--url", issue_url])
    try:
        if isinstance(data, dict) and data.get("id"):
            return data["id"]
    except json.JSONDecodeError:
        pass
    # Fallback: re-query
    item_id = get_item_id_for_issue(issue_number)
    if item_id:
        return item_id
    for it in list_project_items():
        content = it.get("content") or {}
        if content.get("type") == "Issue" and content.get("url") == issue_url:
            return it.get("id", "")
    # Re-run the link script to ensure issue bodies start with PRD link


def build_prd_url(prd_link: str) -> str:
    # Build canonical GitHub Wiki page URL (strip .md)
    rel_path = prd_url_relative_path(prd_link)
    if rel_path.endswith(".md"):
        rel_path = rel_path[:-3]
    return f"{REPO_BASE_URL}{rel_path}"


def prd_url_relative_path(prd_link: str) -> str:
    # Path relative to the Wiki repository root
    base_rel = "prd"
    rel_path = os.path.normpath(os.path.join(base_rel, prd_link)).replace(os.path.sep, "/")
    return rel_path


def prd_file_exists(prd_link: str) -> bool:
    # Local path within monorepo for wiki content
    local_rel = os.path.normpath(os.path.join("khetisahayak.wiki", "prd", prd_link)).replace(os.path.sep, "/")
    return (REPO_ROOT / local_rel).exists()


def main():
    if not TRACEABILITY_FILE.exists():
        raise SystemExit(f"Traceability file not found: {TRACEABILITY_FILE}")

    text = TRACEABILITY_FILE.read_text(encoding="utf-8")
    rows = ROW_REGEX.findall(text)
    if not rows:
        raise SystemExit("No rows found in traceability matrix")

    to_process = []
    for feature, prd_link, issue_col in rows:
        m = ISSUE_LINK_REGEX.search(issue_col)
        if m:
            # Already has issue link
            issue_num = int(m.group("num"))
            issue_url = m.group("url")
            to_process.append((feature, prd_link, issue_num, issue_url))
        else:
            # Missing link: create/reuse issue
            issue_num, issue_url = ensure_issue(feature, prd_link)
            to_process.append((feature, prd_link, issue_num, issue_url))

    # Update matrix with new links where missing
    changed = update_matrix(to_process)
    print(f"Updated matrix rows: {changed}")

    # Run the link script to ensure all issue bodies (new and old) have the PRD link.
    run(["python3", "scripts/link_prd_to_issues.py"])  # idempotent

    # Populate the "PRD" field in the GitHub Project board
    project_id = get_project_id()
    prd_field_id = get_prd_field_id()
    if not prd_field_id:
        raise SystemExit("PRD field not found on project; create it first.")

    updated_items = 0
    for feature, prd_link, issue_num, issue_url in to_process:
        if not prd_file_exists(prd_link):
            continue
        item_id = ensure_item_in_project(issue_num, issue_url, project_id)
        prd_url = build_prd_url(prd_link)
        if set_prd_field(project_id, prd_field_id, item_id, prd_url):
            updated_items += 1
    print(f"Updated PRD field for {updated_items} project items.")


if __name__ == "__main__":
    main()

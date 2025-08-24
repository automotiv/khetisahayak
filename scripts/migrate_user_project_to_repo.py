#!/usr/bin/env python3
"""
Migrate a Classic GitHub Project from a USER scope to a REPOSITORY scope.

- Copies columns in order
- Copies cards (notes as notes)
- For issue/PR cards:
  - If the item belongs to the destination repo, links it directly
  - Otherwise, creates a note card with a link back to the original item

Requirements:
  - Python 3.8+
  - requests (pip install requests)
  - Classic Projects API access (preview media type)
  - Personal Access Token (classic) with scopes: repo, project

Environment variables:
  - GITHUB_TOKEN: your PAT (classic) DO NOT COMMIT THIS
  - SOURCE_USER: e.g. "automotiv"
  - SOURCE_PROJECT_NUMBER: e.g. "3" (from https://github.com/users/<user>/projects/<number>)
  - DEST_OWNER: e.g. "automotiv"
  - DEST_REPO: e.g. "khetisahayak"

Example:
  export GITHUB_TOKEN=***
  export SOURCE_USER=automotiv
  export SOURCE_PROJECT_NUMBER=3
  export DEST_OWNER=automotiv
  export DEST_REPO=khetisahayak
  python3 scripts/migrate_user_project_to_repo.py
"""
import os
import sys
import time
from typing import Dict, List, Optional

import requests

API = "https://api.github.com"
HEADERS = {
    "Accept": "application/vnd.github.inertia-preview+json",
}


def _auth_headers() -> Dict[str, str]:
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        print("ERROR: GITHUB_TOKEN is not set.", file=sys.stderr)
        sys.exit(1)
    return {**HEADERS, "Authorization": f"token {token}"}


def _get(url: str, params: Optional[Dict] = None):
    r = requests.get(url, headers=_auth_headers(), params=params or {})
    if r.status_code >= 300:
        raise RuntimeError(f"GET {url} failed: {r.status_code} {r.text}")
    return r.json()


def _post(url: str, json: Dict):
    r = requests.post(url, headers=_auth_headers(), json=json)
    if r.status_code >= 300:
        raise RuntimeError(f"POST {url} failed: {r.status_code} {r.text}")
    return r.json()


def _paginate(url: str, params: Optional[Dict] = None) -> List[Dict]:
    results = []
    page = 1
    while True:
        q = dict(params or {})
        q.update({"per_page": 100, "page": page})
        r = requests.get(url, headers=_auth_headers(), params=q)
        if r.status_code >= 300:
            raise RuntimeError(f"GET {url} failed: {r.status_code} {r.text}")
        batch = r.json()
        results.extend(batch)
        # Simple pagination check
        if len(batch) < 100:
            break
        page += 1
        # Be kind to rate limits
        time.sleep(0.2)
    return results


def get_user_project_by_number(user: str, number: int) -> Dict:
    projects = _paginate(f"{API}/users/{user}/projects")
    for p in projects:
        if p.get("number") == number:
            return p
    raise RuntimeError(f"User project number {number} not found for user {user}")


def create_repo_project(owner: str, repo: str, name: str, body: Optional[str]) -> Dict:
    payload = {"name": name}
    if body:
        payload["body"] = body
    return _post(f"{API}/repos/{owner}/{repo}/projects", payload)


def create_column(project_id: int, name: str) -> Dict:
    return _post(f"{API}/projects/{project_id}/columns", {"name": name})


def create_note_card(column_id: int, note: str) -> Dict:
    # GitHub has note size limits; guard lightly
    if len(note) > 1000:
        note = note[:950] + "\n\n… (truncated)"
    return _post(f"{API}/projects/columns/{column_id}/cards", {"note": note})


def create_content_card(column_id: int, content_id: int, content_type: str) -> Dict:
    return _post(
        f"{API}/projects/columns/{column_id}/cards",
        {"content_id": content_id, "content_type": content_type},
    )


def main():
    user = os.getenv("SOURCE_USER")
    number = os.getenv("SOURCE_PROJECT_NUMBER")
    dest_owner = os.getenv("DEST_OWNER")
    dest_repo = os.getenv("DEST_REPO")

    if not all([user, number, dest_owner, dest_repo]):
        print("ERROR: SOURCE_USER, SOURCE_PROJECT_NUMBER, DEST_OWNER, DEST_REPO must be set.", file=sys.stderr)
        sys.exit(1)

    number = int(number)

    print(f"Locating user project {user}/projects/{number} …")
    src_project = get_user_project_by_number(user, number)
    print(f"Found source: id={src_project['id']}, name='{src_project['name']}'")

    print(f"Creating destination repo project at {dest_owner}/{dest_repo} …")
    dest_project = create_repo_project(dest_owner, dest_repo, src_project.get("name", f"Migrated from {user}/projects/{number}"), src_project.get("body"))
    print(f"Created destination project: id={dest_project['id']}")

    # Map columns
    print("Fetching source columns …")
    src_columns = _paginate(f"{API}/projects/{src_project['id']}/columns")
    dest_columns_map: Dict[int, int] = {}
    print(f"Creating {len(src_columns)} columns in destination …")
    for col in src_columns:
        new_col = create_column(dest_project['id'], col['name'])
        dest_columns_map[col['id']] = new_col['id']
        print(f"  Column: '{col['name']}' -> id {new_col['id']}")

    # Copy cards
    for col in src_columns:
        print(f"Copying cards for column '{col['name']}' …")
        cards = _paginate(f"{API}/projects/columns/{col['id']}/cards")
        for card in cards:
            dest_col_id = dest_columns_map[col['id']]
            content_url = card.get('content_url')
            if content_url:
                # Linked issue or PR
                item = _get(content_url)
                html_url = item.get('html_url')
                # repository_url like https://api.github.com/repos/<owner>/<repo>
                repo_url = item.get('repository_url', '')
                # Normalize and compare
                expected_repo_url = f"{API}/repos/{dest_owner}/{dest_repo}"
                if repo_url == expected_repo_url:
                    # same repo: link directly
                    content_type = 'Issue' if 'pull_request' not in item else 'PullRequest'
                    try:
                        create_content_card(dest_col_id, item['id'], content_type)
                        print(f"    Linked {content_type} {html_url}")
                    except Exception as e:
                        print(f"    WARN: Failed to link item, falling back to note: {e}")
                        create_note_card(dest_col_id, f"{item.get('title','')}\n{html_url}")
                else:
                    # different repo: create note with link
                    title = item.get('title', '(no title)')
                    note = f"{title}\n{html_url}\n\n(Migrated from {repo_url.replace(API + '/repos/', '')})"
                    create_note_card(dest_col_id, note)
                    print(f"    Note for external item {html_url}")
            else:
                # Note card
                note = card.get('note', '').strip()
                if not note:
                    note = "(empty note)"
                create_note_card(dest_col_id, note)
                print("    Note copied")
            # Gentle pacing
            time.sleep(0.15)

    print("\nDone. Review the destination project in the repository UI.")
    print(f"https://github.com/{dest_owner}/{dest_repo}/projects")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

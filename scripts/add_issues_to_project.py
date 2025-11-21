#!/usr/bin/env python3
"""
Add existing issues to GitHub Project
This script adds issues to a GitHub Project using the GraphQL API
"""

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
REPO_SLUG = "automotiv/khetisahayak"
OWNER = "automotiv"
PROJECT_NUMBER = 3

def run_command(cmd, capture=True, check=False):
    """Run a shell command and return the result"""
    result = subprocess.run(
        cmd,
        capture_output=capture,
        text=True,
        cwd=str(REPO_ROOT)
    )
    return result


def get_project_id():
    """Get the project ID using GraphQL"""
    query = """
    query($owner: String!, $number: Int!) {
      user(login: $owner) {
        projectV2(number: $number) {
          id
        }
      }
    }
    """
    
    result = run_command([
        "gh", "api", "graphql",
        "-f", f"query={query}",
        "-F", f"owner={OWNER}",
        "-F", f"number={PROJECT_NUMBER}"
    ])
    
    if result.returncode != 0:
        print(f"❌ Error getting project ID: {result.stderr}")
        return None
    
    try:
        data = json.loads(result.stdout)
        project_id = data.get("data", {}).get("user", {}).get("projectV2", {}).get("id")
        return project_id
    except Exception as e:
        print(f"❌ Error parsing project response: {e}")
        return None


def get_issue_node_id(issue_number):
    """Get the node ID for an issue"""
    result = run_command([
        "gh", "api", f"repos/{REPO_SLUG}/issues/{issue_number}",
        "--jq", ".node_id"
    ])
    
    if result.returncode != 0:
        return None
    
    return result.stdout.strip()


def add_issue_to_project_graphql(project_id, issue_node_id, issue_number):
    """Add an issue to a project using GraphQL API"""
    mutation = """
    mutation($projectId: ID!, $contentId: ID!) {
      addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
        item {
          id
        }
      }
    }
    """
    
    result = run_command([
        "gh", "api", "graphql",
        "-f", f"query={mutation}",
        "-f", f"projectId={project_id}",
        "-f", f"contentId={issue_node_id}"
    ])
    
    if result.returncode != 0:
        print(f"  ❌ Failed to add #{issue_number}: {result.stderr}")
        return False
    
    print(f"  ✅ Added #{issue_number} to project")
    return True


def get_recent_issues_with_labels(labels):
    """Get recent issues with specific labels"""
    label_query = ",".join(labels)
    
    result = run_command([
        "gh", "issue", "list",
        "--repo", REPO_SLUG,
        "--label", label_query,
        "--limit", "100",
        "--json", "number,title,labels",
        "--state", "open"
    ])
    
    if result.returncode != 0:
        print(f"❌ Error getting issues: {result.stderr}")
        return []
    
    try:
        issues = json.loads(result.stdout)
        return issues
    except Exception as e:
        print(f"❌ Error parsing issues: {e}")
        return []


def main():
    """Main execution"""
    print("=" * 60)
    print("📌 Adding Issues to GitHub Project")
    print("=" * 60)
    
    # Get project ID
    print("\n🔍 Getting project ID...")
    project_id = get_project_id()
    
    if not project_id:
        print("\n❌ Could not get project ID. Possible reasons:")
        print("  1. The PAT doesn't have 'project' scope")
        print("  2. The project number is incorrect")
        print("  3. The project is an organization project (not user project)")
        print("\n💡 To fix this:")
        print("  1. Go to https://github.com/settings/tokens")
        print("  2. Create a new token with these scopes:")
        print("     - repo (full control)")
        print("     - project (full control)")
        print("     - read:org")
        print("  3. Run: gh auth login --with-token < new_token.txt")
        return
    
    print(f"  ✅ Project ID: {project_id}")
    
    # Get issues created by the sync script (with specific labels)
    print("\n🔍 Finding issues to add...")
    target_labels = ["epic", "feature", "task"]
    all_issues = []
    
    for label in target_labels:
        issues = get_recent_issues_with_labels([label])
        all_issues.extend(issues)
    
    # Remove duplicates
    unique_issues = {issue['number']: issue for issue in all_issues}
    issues_to_add = list(unique_issues.values())
    
    print(f"  ✅ Found {len(issues_to_add)} issues to add")
    
    if not issues_to_add:
        print("\n⚠️ No issues found with labels: epic, feature, or task")
        return
    
    # Add each issue to the project
    print(f"\n📌 Adding issues to project...")
    success_count = 0
    fail_count = 0
    
    for issue in issues_to_add:
        issue_number = issue['number']
        issue_title = issue['title']
        
        # Get node ID
        node_id = get_issue_node_id(issue_number)
        
        if not node_id:
            print(f"  ⚠️ Could not get node ID for #{issue_number}")
            fail_count += 1
            continue
        
        # Add to project
        if add_issue_to_project_graphql(project_id, node_id, issue_number):
            success_count += 1
        else:
            fail_count += 1
    
    # Summary
    print("\n" + "=" * 60)
    print("✅ Process Complete!")
    print("=" * 60)
    print(f"\n📊 Summary:")
    print(f"  • Successfully added: {success_count}")
    print(f"  • Failed: {fail_count}")
    print(f"  • Total processed: {len(issues_to_add)}")
    print(f"\n🔗 View your project at:")
    print(f"  https://github.com/users/{OWNER}/projects/{PROJECT_NUMBER}")
    print()


if __name__ == "__main__":
    main()

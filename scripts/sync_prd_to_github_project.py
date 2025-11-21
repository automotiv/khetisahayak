#!/usr/bin/env python3
"""
Sync PRD documents to GitHub Project
Creates Epics, Features, User Stories, and Tasks from PRD and Agile planning documents
"""

import json
import os
import re
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Tuple

# Configuration
REPO_ROOT = Path(__file__).resolve().parents[1]
REPO_SLUG = "automotiv/khetisahayak"
PROJECT_NUMBER = "3"
OWNER = "automotiv"

# Document paths
PRD_PATH = REPO_ROOT / "wiki" / "prd" / "Detailed_PRD.md"
AGILE_PATH = REPO_ROOT / "wiki" / "agile" / "crop_health_plan.md"

# Label colors
LABEL_COLORS = {
    "epic": "8B0000",        # Dark red
    "feature": "0E8A16",     # Green
    "user-story": "0075CA",  # Blue
    "task": "FBCA04",        # Yellow
    "documentation": "D4C5F9", # Purple
    "enhancement": "A2EEEF",  # Light blue
}


def run_command(cmd: List[str], capture=True, check=True) -> subprocess.CompletedProcess:
    """Run a shell command and return the result"""
    result = subprocess.run(
        cmd,
        capture_output=capture,
        text=True,
        cwd=str(REPO_ROOT)
    )
    if check and result.returncode != 0:
        print(f"❌ Command failed: {' '.join(cmd)}")
        print(f"STDERR: {result.stderr}")
        raise RuntimeError(f"Command failed with exit code {result.returncode}")
    return result


def ensure_labels_exist():
    """Create necessary labels if they don't exist"""
    print("📋 Ensuring labels exist...")
    
    for label_name, color in LABEL_COLORS.items():
        try:
            # Check if label exists
            result = run_command([
                "gh", "label", "list",
                "--repo", REPO_SLUG,
                "--json", "name",
                "--jq", f'.[] | select(.name=="{label_name}") | .name'
            ])
            
            if result.stdout.strip() != label_name:
                # Create label
                run_command([
                    "gh", "label", "create", label_name,
                    "--color", color,
                    "--repo", REPO_SLUG
                ])
                print(f"  ✅ Created label: {label_name}")
            else:
                print(f"  ✓ Label exists: {label_name}")
        except Exception as e:
            print(f"  ⚠️ Warning: Could not create label {label_name}: {e}")


def create_issue(title: str, body: str, labels: List[str], assignee: str = None) -> str:
    """Create a GitHub issue and return its number"""
    
    cmd = [
        "gh", "issue", "create",
        "--repo", REPO_SLUG,
        "--title", title,
        "--body", body,
    ]
    
    # Add labels
    for label in labels:
        cmd.extend(["--label", label])
    
    # Add assignee if provided
    if assignee:
        cmd.extend(["--assignee", assignee])
    
    print(f"  Creating: {title}")
    result = run_command(cmd)
    
    # Extract issue number from URL
    issue_url = result.stdout.strip()
    issue_number = issue_url.split('/')[-1]
    
    print(f"    ✅ Created #{issue_number}")
    
    # Small delay to avoid rate limiting
    time.sleep(0.5)
    
    return issue_number


def add_issue_to_project(issue_number: str) -> bool:
    """Add an issue to the GitHub Project"""
    try:
        cmd = [
            "gh", "project", "item-add", PROJECT_NUMBER,
            "--owner", OWNER,
            "--url", f"https://github.com/{REPO_SLUG}/issues/{issue_number}"
        ]
        run_command(cmd)
        print(f"    ✅ Added to project")
        return True
    except Exception as e:
        print(f"    ⚠️ Warning: Could not add to project: {e}")
        return False


def parse_prd_features() -> List[Dict]:
    """Parse features from the main PRD document"""
    print("\n📖 Parsing PRD document...")
    
    if not PRD_PATH.exists():
        print(f"  ⚠️ PRD not found at {PRD_PATH}")
        return []
    
    with open(PRD_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    
    features = []
    
    # Pattern to match feature sections
    feature_pattern = r'### (\d+\.\d+)\.\s+([^\n]+)\n\*\*User Story:\*\*\s+([^\n]+)\n\n\*\*Acceptance Criteria:\*\*\n((?:\*[^\n]+\n?)+)'
    
    matches = re.finditer(feature_pattern, content, re.MULTILINE)
    
    for match in matches:
        section_num, feature_name, user_story, acceptance_criteria = match.groups()
        
        # Parse acceptance criteria
        criteria_items = re.findall(r'\*\s+(.+)', acceptance_criteria)
        
        features.append({
            'section': section_num,
            'name': feature_name,
            'user_story': user_story,
            'acceptance_criteria': criteria_items
        })
    
    print(f"  ✅ Found {len(features)} features")
    return features


def parse_agile_plan() -> Dict:
    """Parse the agile planning document"""
    print("\n📖 Parsing Agile Plan...")
    
    if not AGILE_PATH.exists():
        print(f"  ⚠️ Agile plan not found at {AGILE_PATH}")
        return {}
    
    with open(AGILE_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract epic
    epic_match = re.search(r'## Epic:\s+([^\n]+)\n\*\*Objective\*\*:\s+([^\n]+)', content)
    if not epic_match:
        print("  ⚠️ Could not find epic in agile plan")
        return {}
    
    epic_name = epic_match.group(1)
    epic_objective = epic_match.group(2)
    
    # Extract features with their tasks
    features = []
    feature_pattern = r'### Feature \d+:\s+([^\n]+)\n\*\*User Story\*\*:\s+([^\n]+)\n\n#### Tasks:\n((?:- \[ \][^\n]+\n?)+)'
    
    for match in re.finditer(feature_pattern, content):
        feature_name, user_story, tasks_block = match.groups()
        
        # Parse tasks
        tasks = re.findall(r'- \[ \]\s+(.+)', tasks_block)
        
        features.append({
            'name': feature_name,
            'user_story': user_story,
            'tasks': tasks
        })
    
    print(f"  ✅ Found 1 epic with {len(features)} features")
    
    return {
        'epic': {
            'name': epic_name,
            'objective': epic_objective
        },
        'features': features
    }


def create_epic_from_agile_plan(agile_data: Dict) -> str:
    """Create an epic issue from agile plan data"""
    if not agile_data or 'epic' not in agile_data:
        return None
    
    epic = agile_data['epic']
    
    body = f"""## Epic Overview

{epic['objective']}

## Features in this Epic

"""
    
    # List features
    for idx, feature in enumerate(agile_data['features'], 1):
        body += f"{idx}. {feature['name']}\n"
    
    body += f"""

## Success Criteria

- All features implemented and tested
- 85%+ accuracy for AI diagnostics
- Offline functionality working
- User acceptance testing completed

## Technical Approach

- Computer Vision AI/ML model integration
- Offline-first architecture
- Cloud sync for history
- Mobile-optimized UI/UX

---
*This epic was auto-generated from the PRD and Agile Planning documents*
"""
    
    issue_num = create_issue(
        title=f"Epic: {epic['name']}",
        body=body,
        labels=["epic", "enhancement"]
    )
    
    add_issue_to_project(issue_num)
    
    return issue_num


def create_feature_with_tasks(feature: Dict, epic_number: str = None) -> str:
    """Create a feature issue and its related tasks"""
    
    # Create feature body
    body = f"""## User Story

{feature['user_story']}

## Tasks

"""
    
    for idx, task in enumerate(feature['tasks'], 1):
        body += f"- [ ] {task}\n"
    
    if epic_number:
        body += f"\n## Related Epic\n\nPart of #{epic_number}\n"
    
    body += """

## Definition of Done

- All tasks completed
- Code reviewed and merged
- Unit tests written and passing
- Integration tests passing
- Documentation updated

---
*This feature was auto-generated from the PRD and Agile Planning documents*
"""
    
    # Create feature issue
    feature_num = create_issue(
        title=f"Feature: {feature['name']}",
        body=body,
        labels=["feature", "enhancement"]
    )
    
    add_issue_to_project(feature_num)
    
    # Create individual task issues
    print(f"\n  📝 Creating tasks for feature '{feature['name']}'...")
    for task_text in feature['tasks']:
        task_body = f"""## Task Description

{task_text}

## Parent Feature

This task is part of #{feature_num} - {feature['name']}
"""
        
        if epic_number:
            task_body += f"\n## Related Epic\n\n#{epic_number}\n"
        
        task_body += "\n---\n*This task was auto-generated from the PRD and Agile Planning documents*"
        
        task_num = create_issue(
            title=f"Task: {task_text[:60]}{'...' if len(task_text) > 60 else ''}",
            body=task_body,
            labels=["task"]
        )
        
        add_issue_to_project(task_num)
    
    return feature_num


def create_prd_features(prd_features: List[Dict]) -> List[str]:
    """Create feature issues from PRD features"""
    print("\n📝 Creating PRD features...")
    
    feature_numbers = []
    
    for feature in prd_features:
        # Create feature body
        body = f"""## User Story

{feature['user_story']}

## Acceptance Criteria

"""
        
        for criterion in feature['acceptance_criteria']:
            body += f"- {criterion}\n"
        
        body += """

## Implementation Notes

This feature needs:
- Technical design document
- API specification (if applicable)
- UI/UX mockups
- Test plan

## Definition of Done

- All acceptance criteria met
- Code reviewed and merged
- Unit and integration tests passing
- Documentation updated
- User acceptance testing completed

---
*This feature was auto-generated from the Product Requirements Document*
"""
        
        feature_num = create_issue(
            title=f"Feature: {feature['name']}",
            body=body,
            labels=["feature", "enhancement", "documentation"]
        )
        
        add_issue_to_project(feature_num)
        feature_numbers.append(feature_num)
    
    return feature_numbers


def main():
    """Main execution"""
    print("=" * 60)
    print("🚀 Kheti Sahayak - PRD to GitHub Project Sync")
    print("=" * 60)
    
    # Ensure labels exist
    ensure_labels_exist()
    
    # Parse documents
    agile_data = parse_agile_plan()
    prd_features = parse_prd_features()
    
    # Create epic and features from agile plan
    epic_number = None
    if agile_data:
        print("\n" + "=" * 60)
        print("📦 Creating Epic and Features from Agile Plan")
        print("=" * 60)
        
        epic_number = create_epic_from_agile_plan(agile_data)
        
        for feature in agile_data['features']:
            create_feature_with_tasks(feature, epic_number)
    
    # Create features from PRD
    if prd_features:
        print("\n" + "=" * 60)
        print("📦 Creating Features from PRD Document")
        print("=" * 60)
        
        create_prd_features(prd_features)
    
    # Summary
    print("\n" + "=" * 60)
    print("✅ Sync Complete!")
    print("=" * 60)
    print(f"\n📊 Summary:")
    print(f"  • Epics created: {1 if epic_number else 0}")
    print(f"  • Features created from Agile Plan: {len(agile_data.get('features', []))}")
    print(f"  • Features created from PRD: {len(prd_features)}")
    print(f"\n🔗 View your project at:")
    print(f"  https://github.com/users/{OWNER}/projects/{PROJECT_NUMBER}")
    print(f"\n🔗 View all issues at:")
    print(f"  https://github.com/{REPO_SLUG}/issues")
    print()


if __name__ == "__main__":
    main()

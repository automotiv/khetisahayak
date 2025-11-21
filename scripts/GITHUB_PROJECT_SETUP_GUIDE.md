# GitHub Project Issue Addition - Troubleshooting Guide

## Problem
The Personal Access Token (PAT) doesn't have sufficient permissions to add items to GitHub Projects v2.

## Error Message
```
GraphQL: Resource not accessible by personal access token (addProjectV2ItemById)
```

## Root Cause
The PAT is missing the `project` scope which is required to modify GitHub Projects (v2).

## Solution: Create a New PAT with Correct Permissions

### Step 1: Generate a New Personal Access Token

1. Go to GitHub Settings: https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Give it a descriptive name: `Kheti Sahayak Project Management`
4. Set expiration (recommend: 90 days or custom)
5. **Select the following scopes:**
   - ✅ `repo` (Full control of private repositories)
   - ✅ `write:project` or `project` (Access to GitHub Projects)
   - ✅ `read:org` (Read org and team membership)

### Step 2: Copy the Token
After clicking "Generate token", copy the token immediately (you won't see it again).

### Step 3: Authenticate with the New Token
```bash
echo "YOUR_NEW_TOKEN_HERE" | gh auth login --with-token
```

### Step 4: Run the Batch Add Script
```bash
python3 scripts/add_issues_to_project_batch.py
```

---

## Alternative: Manual Addition via GitHub UI

If you prefer to add issues manually or the PAT approach continues to fail:

### Option 1: Add Issues One by One
1. Go to your project: https://github.com/users/automotiv/projects/3
2. Click **"+ Add item"**
3. Search for the issue number (e.g., #305)
4. Click to add it

### Option 2: Bulk Add from Issue List
1. Go to issues: https://github.com/automotiv/khetisahayak/issues
2. Filter by labels: `label:epic`, `label:feature`, or `label:task`
3. Select multiple issues using checkboxes
4. Use the **"Add to project"** dropdown in the toolbar
5. Select your project: **"Kheti Sahayak MVP"**

### Option 3: Use GitHub CLI with Repo-Scoped Project
Try adding issues to a repository project instead of a user project:
```bash
gh project item-add PROJECT_NUMBER \
  --repo automotiv/khetisahayak \
  --url https://github.com/automotiv/khetisahayak/issues/305
```

---

## Created Issues Summary

The sync script successfully created **49 issues**:

### Epic (1 issue)
- #305: Epic: AI-Powered Crop Health Diagnostics

### Features from Agile Plan (5 issues + 35 tasks)
- #306: Feature: Image Capture & Upload
  - Tasks: #307-#314 (8 tasks)
- #315: Feature: AI-Powered Analysis
  - Tasks: #316-#322 (7 tasks)
- #323: Feature: Diagnostic Results & Recommendations
  - Tasks: #324-#330 (7 tasks)
- #331: Feature: History & Tracking
  - Tasks: #332-#338 (7 tasks)
- #339: Feature: Offline Functionality
  - Tasks: #340-#345 (6 tasks)

### Features from PRD (8 issues)
- #346: Feature: Localised Weather Forecast
- #347: Feature: Crop Health Diagnostics
- #348: Feature: Marketplace
- #349: Feature: Educational Content
- #350: Feature: Community Forum
- #351: Feature: Digital Logbook
- #352: Feature: Government Scheme Portal
- #353: Feature: Expert Connect

---

## Quick Filter Commands

View all created issues:
```bash
gh issue list --repo automotiv/khetisahayak --state open --limit 50
```

View by label:
```bash
gh issue list --repo automotiv/khetisahayak --label "epic"
gh issue list --repo automotiv/khetisahayak --label "feature"
gh issue list --repo automotiv/khetisahayak --label "task"
```

---

## Next Steps

1. **Fix PAT permissions** (recommended) - Follow Step 1-4 above
2. **Or manually add issues** using GitHub UI
3. **Organize in project board** with columns (Backlog, To Do, In Progress, Done)
4. **Add milestones** to track progress
5. **Assign team members** to issues

---

## PAT Permission Reference

For GitHub Projects (v2), the PAT needs:
- `project:read` - Read access to projects
- `project:write` - Write access to projects (required for adding items)
- `repo` - Access to repository issues

Classic tokens use:
- `project` scope for full project access
- `repo` scope for repository access

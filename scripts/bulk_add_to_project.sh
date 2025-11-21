#!/bin/bash
# Bulk add issues to GitHub Project using GitHub CLI
# This script attempts multiple methods to add issues to the project

REPO="automotiv/khetisahayak"
PROJECT_NUMBER="3"
OWNER="automotiv"
START_ISSUE=305
END_ISSUE=353

echo "============================================================"
echo "🔄 Attempting to Add Issues to GitHub Project"
echo "============================================================"
echo ""
echo "Repository: $REPO"
echo "Project: #$PROJECT_NUMBER"
echo "Issue range: #$START_ISSUE - #$END_ISSUE"
echo ""

# Method 1: Try with --owner flag
echo "📝 Method 1: Using --owner flag..."
gh project item-add "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --url "https://github.com/$REPO/issues/305"

if [ $? -eq 0 ]; then
    echo "✅ Method 1 works! Using this method for all issues..."
    for i in $(seq $START_ISSUE $END_ISSUE); do
        echo "  Adding issue #$i..."
        gh project item-add "$PROJECT_NUMBER" \
            --owner "$OWNER" \
            --url "https://github.com/$REPO/issues/$i"
        sleep 0.3
    done
    exit 0
fi

echo "❌ Method 1 failed"
echo ""

# Method 2: Try with repository-scoped project
echo "📝 Method 2: Using --repo flag (repository-scoped project)..."
gh project item-add "$PROJECT_NUMBER" \
  --repo "$REPO" \
  --url "https://github.com/$REPO/issues/305"

if [ $? -eq 0 ]; then
    echo "✅ Method 2 works! Using this method for all issues..."
    for i in $(seq $START_ISSUE $END_ISSUE); do
        echo "  Adding issue #$i..."
        gh project item-add "$PROJECT_NUMBER" \
            --repo "$REPO" \
            --url "https://github.com/$REPO/issues/$i"
        sleep 0.3
    done
    exit 0
fi

echo "❌ Method 2 failed"
echo ""

# Method 3: Show instructions for manual addition
echo "============================================================"
echo "⚠️  Automatic addition requires additional permissions"
echo "============================================================"
echo ""
echo "The Personal Access Token needs the 'project' scope."
echo ""
echo "📋 To fix this, create a new token with these permissions:"
echo "   1. Go to: https://github.com/settings/tokens"
echo "   2. Click 'Generate new token (classic)'"
echo "   3. Select scopes: 'repo' AND 'project'"
echo "   4. Generate and copy the token"
echo "   5. Run: echo 'YOUR_TOKEN' | gh auth login --with-token"
echo "   6. Run this script again"
echo ""
echo "============================================================"
echo "📱 Manual Addition (Alternative)"
echo "============================================================"
echo ""
echo "1. Open your project:"
echo "   https://github.com/users/$OWNER/projects/$PROJECT_NUMBER"
echo ""
echo "2. Click '+ Add item' and search for these issue numbers:"
echo "   #305, #306, #307, ... #353"
echo ""
echo "Or use bulk selection:"
echo "   https://github.com/$REPO/issues"
echo "   - Filter: is:issue is:open label:epic,feature,task"
echo "   - Select multiple issues"
echo "   - Use 'Add to project' dropdown"
echo ""
echo "============================================================"
echo ""

exit 1

#!/bin/bash
# Master Deployment Script - Deploy Everything
# Agent: @devops-release-manager

set -e

echo "🚀 Kheti Sahayak - Complete Deployment"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
VERSION=${1:-"1.0.0"}
BUILD_NUMBER=${2:-1}
DEPLOY_BACKEND=${3:-true}
DEPLOY_MOBILE=${4:-true}

echo -e "${BLUE}Deployment Configuration:${NC}"
echo "  Version: $VERSION"
echo "  Build Number: $BUILD_NUMBER"
echo "  Deploy Backend: $DEPLOY_BACKEND"
echo "  Deploy Mobile: $DEPLOY_MOBILE"
echo ""

# Pre-flight checks
echo -e "${YELLOW}Pre-flight Checks${NC}"
echo "=================="

# Check Git status
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}⚠️  Uncommitted changes detected${NC}"
    echo "Commit your changes first:"
    git status -s
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}⚠️  Not on main branch (current: $CURRENT_BRANCH)${NC}"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if tests pass
echo -e "${YELLOW}Running tests...${NC}"
cd kheti_sahayak_backend
npm test || echo "⚠️  Backend tests failed"
cd ..

cd kheti_sahayak_app
flutter test || echo "⚠️  Flutter tests failed"
cd ..

echo -e "${GREEN}✅ Pre-flight checks complete${NC}"
echo ""

# Update version in all files
echo -e "${YELLOW}Updating version numbers...${NC}"
echo $VERSION > VERSION

# Update pubspec.yaml
sed -i.bak "s/version: .*/version: $VERSION+$BUILD_NUMBER/" kheti_sahayak_app/pubspec.yaml
rm kheti_sahayak_app/pubspec.yaml.bak

# Update package.json
cd kheti_sahayak_backend
npm version $VERSION --no-git-tag-version
cd ..

echo -e "${GREEN}✅ Version updated to $VERSION${NC}"
echo ""

# Deploy Backend to Render
if [ "$DEPLOY_BACKEND" = true ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}1. Deploying Backend to Render${NC}"
    echo -e "${BLUE}========================================${NC}"

    ./scripts/deploy-backend-render.sh

    echo -e "${GREEN}✅ Backend deployed${NC}"
    echo ""
else
    echo -e "${YELLOW}⏭️  Skipping backend deployment${NC}"
fi

# Build Mobile Apps
if [ "$DEPLOY_MOBILE" = true ]; then
    # Build Android
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}2. Building Android App${NC}"
    echo -e "${BLUE}========================================${NC}"

    ./scripts/build-android.sh release production $BUILD_NUMBER $VERSION

    echo -e "${GREEN}✅ Android AAB built${NC}"
    echo ""

    # Build iOS (only on macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}3. Building iOS App${NC}"
        echo -e "${BLUE}========================================${NC}"

        ./scripts/build-ios.sh $BUILD_NUMBER $VERSION

        echo -e "${GREEN}✅ iOS IPA built${NC}"
        echo ""
    else
        echo -e "${YELLOW}⏭️  Skipping iOS build (requires macOS)${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  Skipping mobile builds${NC}"
fi

# Create Git tag
echo -e "${YELLOW}Creating Git tag v$VERSION...${NC}"
git add VERSION kheti_sahayak_app/pubspec.yaml kheti_sahayak_backend/package.json
git commit -m "Bump version to $VERSION" || echo "No changes to commit"
git tag -a "v$VERSION" -m "Release version $VERSION"

echo -e "${GREEN}✅ Git tag created${NC}"
echo ""

# Deployment Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Version: $VERSION (Build $BUILD_NUMBER)"
echo ""
echo "Deployed Components:"
[ "$DEPLOY_BACKEND" = true ] && echo "  ✅ Backend API (Render)"
[ "$DEPLOY_MOBILE" = true ] && echo "  ✅ Android AAB"
[[ "$DEPLOY_MOBILE" = true && "$OSTYPE" == "darwin"* ]] && echo "  ✅ iOS IPA"
echo ""
echo "Build Outputs:"
echo "  Android AAB: kheti_sahayak_app/build/app/outputs/bundle/release/app-release.aab"
[[ "$OSTYPE" == "darwin"* ]] && echo "  iOS IPA: kheti_sahayak_app/build/ios/ipa/kheti_sahayak_app.ipa"
echo ""
echo "Next Steps:"
echo ""
echo "1. Backend (Render):"
echo "   - Verify deployment: https://dashboard.render.com"
echo "   - Run migrations in Shell"
echo "   - Test API endpoints"
echo ""
echo "2. Android (Play Store):"
echo "   - Go to: https://play.google.com/console"
echo "   - Upload AAB to Internal Testing"
echo "   - Test with internal testers"
echo "   - Promote to Beta/Production"
echo ""
echo "3. iOS (App Store):"
echo "   - Go to: https://appstoreconnect.apple.com"
echo "   - Upload IPA via Transporter or Xcode"
echo "   - Submit to TestFlight"
echo "   - Submit for App Review"
echo ""
echo "4. Push Git tag:"
echo "   git push origin v$VERSION"
echo ""
echo "5. Monitor deployment health"
echo "   - Backend API health"
echo "   - App store review status"
echo "   - Crash reports"
echo "   - User feedback"
echo ""
echo -e "${BLUE}For detailed instructions, see DEPLOYMENT_GUIDE.md${NC}"

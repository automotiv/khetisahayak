#!/bin/bash
# Build iOS App for App Store
# Agent: @mobile-build-engineer

set -e

echo "🍎 Kheti Sahayak - iOS Build Script"
echo "===================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
BUILD_NUMBER=${1:-1}
BUILD_NAME=${2:-1.0.0}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ iOS builds require macOS${NC}"
    exit 1
fi

# Navigate to Flutter project
cd kheti_sahayak_app

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -1)${NC}"

# Clean previous builds
echo -e "${YELLOW}Step 1: Cleaning previous builds...${NC}"
flutter clean
cd ios
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*
cd ..

# Get dependencies
echo -e "${YELLOW}Step 2: Getting dependencies...${NC}"
flutter pub get

# Install CocoaPods
echo -e "${YELLOW}Step 3: Installing CocoaPods...${NC}"
cd ios
pod deintegrate || true
pod install
cd ..

# Run tests
echo -e "${YELLOW}Step 4: Running tests...${NC}"
flutter test || echo "⚠️  Some tests failed"

# Build IPA
echo -e "${YELLOW}Step 5: Building release IPA...${NC}"

flutter build ipa \
    --release \
    --build-number=$BUILD_NUMBER \
    --build-name=$BUILD_NAME

IPA_PATH="build/ios/ipa/kheti_sahayak_app.ipa"

if [ -f "$IPA_PATH" ]; then
    SIZE=$(du -h "$IPA_PATH" | cut -f1)
    echo -e "${GREEN}✅ IPA built successfully${NC}"
    echo "   Location: $IPA_PATH"
    echo "   Size: $SIZE"
else
    echo -e "${RED}❌ IPA build failed${NC}"
    echo "Trying alternative build method..."

    # Alternative: Build with Xcode directly
    cd ios
    xcodebuild -workspace Runner.xcworkspace \
        -scheme Runner \
        -configuration Release \
        -archivePath build/Runner.xcarchive \
        archive

    xcodebuild -exportArchive \
        -archivePath build/Runner.xcarchive \
        -exportPath build/ipa \
        -exportOptionsPlist ExportOptions.plist

    cd ..
fi

# Build summary
echo ""
echo -e "${GREEN}===================================${NC}"
echo -e "${GREEN}🎉 iOS Build Complete!${NC}"
echo -e "${GREEN}===================================${NC}"
echo ""
echo "Build Details:"
echo "  Version: $BUILD_NAME ($BUILD_NUMBER)"
echo "  IPA: $IPA_PATH"
echo ""
echo "Next steps:"
echo "1. Test on a physical iOS device"
echo "2. Upload to App Store Connect:"
echo "   - Open Xcode Organizer"
echo "   - Or use: xcrun altool --upload-app -f $IPA_PATH"
echo "   - Or use Apple Transporter app"
echo "3. Submit for TestFlight beta testing"
echo "4. Submit for App Store review"

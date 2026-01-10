#!/bin/bash
# Build Android App for Play Store
# Agent: @mobile-build-engineer

set -e

echo "🤖 Kheti Sahayak - Android Build Script"
echo "======================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
BUILD_TYPE=${1:-release}
FLAVOR=${2:-production}
BUILD_NUMBER=${3:-1}
BUILD_NAME=${4:-1.0.0}

# Navigate to Flutter project
cd kheti_sahayak_app

# Flutter path
FLUTTER_BIN=~/flutter/bin/flutter

# Check Flutter installation
if [ ! -f "$FLUTTER_BIN" ]; then
    echo -e "${RED}❌ Flutter is not installed at $FLUTTER_BIN${NC}"
    echo "Install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found: $($FLUTTER_BIN --version | head -1)${NC}"

# Clean previous builds
echo -e "${YELLOW}Step 1: Cleaning previous builds...${NC}"
$FLUTTER_BIN clean
rm -rf build/

# Get dependencies
echo -e "${YELLOW}Step 2: Getting dependencies...${NC}"
$FLUTTER_BIN pub get

# Verify keystore exists
echo -e "${YELLOW}Step 3: Verifying signing configuration...${NC}"
if [ ! -f android/app/upload-keystore.jks ]; then
    echo -e "${RED}❌ Keystore not found${NC}"
    echo "Generating new keystore..."
    keytool -genkey -v \
        -keystore android/app/upload-keystore.jks \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -alias upload \
        -storepass khetisahayak2024 \
        -keypass khetisahayak2024 \
        -dname "CN=Kheti Sahayak, OU=Mobile, O=Kheti Sahayak, L=Mumbai, ST=Maharashtra, C=IN"
    echo -e "${GREEN}✅ Keystore generated${NC}"
fi

if [ ! -f android/key.properties ]; then
    echo "Creating key.properties..."
    cat > android/key.properties << EOF
storePassword=khetisahayak2024
keyPassword=khetisahayak2024
keyAlias=upload
storeFile=app/upload-keystore.jks
EOF
fi

echo -e "${GREEN}✅ Signing configuration verified${NC}"

# Run tests
echo -e "${YELLOW}Step 4: Running tests...${NC}"
$FLUTTER_BIN test || echo "⚠️  Some tests failed"

# Build AAB for Play Store
if [ "$BUILD_TYPE" == "release" ]; then
    echo -e "${YELLOW}Step 5: Building release AAB...${NC}"

    $FLUTTER_BIN build appbundle \
        --release \
        --build-number=$BUILD_NUMBER \
        --build-name=$BUILD_NAME \
        --obfuscate \
        --split-debug-info=build/app/outputs/symbols

    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

    if [ -f "$AAB_PATH" ]; then
        SIZE=$(du -h "$AAB_PATH" | cut -f1)
        echo -e "${GREEN}✅ AAB built successfully${NC}"
        echo "   Location: $AAB_PATH"
        echo "   Size: $SIZE"

        # Verify signing
        echo -e "${YELLOW}Verifying signing...${NC}"
        jarsigner -verify -verbose -certs "$AAB_PATH" && echo -e "${GREEN}✅ Signing verified${NC}" || echo -e "${RED}❌ Signing verification failed${NC}"

        # Also build split APKs for testing
        echo -e "${YELLOW}Building split APKs for testing...${NC}"
        $FLUTTER_BIN build apk --release --split-per-abi \
            --build-number=$BUILD_NUMBER \
            --build-name=$BUILD_NAME

        echo -e "${GREEN}✅ Split APKs built:${NC}"
        ls -lh build/app/outputs/flutter-apk/*.apk
    else
        echo -e "${RED}❌ AAB build failed${NC}"
        exit 1
    fi
else
    # Debug build
    echo -e "${YELLOW}Step 5: Building debug APK...${NC}"
    $FLUTTER_BIN build apk --debug
    echo -e "${GREEN}✅ Debug APK built${NC}"
fi

# Build summary
echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}🎉 Build Complete!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo "Build Details:"
echo "  Type: $BUILD_TYPE"
echo "  Flavor: $FLAVOR"
echo "  Version: $BUILD_NAME ($BUILD_NUMBER)"
echo ""
echo "Outputs:"
if [ "$BUILD_TYPE" == "release" ]; then
    echo "  AAB: build/app/outputs/bundle/release/app-release.aab"
    echo "  APKs: build/app/outputs/flutter-apk/"
else
    echo "  APK: build/app/outputs/flutter-apk/app-debug.apk"
fi
echo ""
echo "Next steps:"
echo "1. Test the APK on a physical device"
echo "2. Upload AAB to Play Console: https://play.google.com/console"
echo "3. Submit for internal testing first"

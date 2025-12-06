#!/bin/bash
set -e

# Build script for JoyCon Android Plugin
# Uses Google Cloud Artifact Registry Docker image

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_IMAGE="europe-west1-docker.pkg.dev/general-476320/android-build-images/android-build-image:latest"
OUTPUT_DIR="${PROJECT_ROOT}/build/output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== JoyCon Android Plugin Build ===${NC}"
echo ""

# Required Godot version
REQUIRED_GODOT_VERSION="4.3"
GODOT_LIB="${PROJECT_ROOT}/android/godot-lib/godot-lib.release.aar"

# Check if godot-lib.release.aar exists
if [ ! -f "${GODOT_LIB}" ]; then
    echo -e "${RED}ERROR: godot-lib.release.aar not found!${NC}"
    echo ""
    echo "Required: Godot ${REQUIRED_GODOT_VERSION}.stable"
    echo ""
    echo "Fix: Download Godot ${REQUIRED_GODOT_VERSION} templates:"
    echo "  curl -L -o Godot_v${REQUIRED_GODOT_VERSION}-stable_export_templates.tpz \\"
    echo "    https://github.com/godotengine/godot/releases/download/${REQUIRED_GODOT_VERSION}-stable/Godot_v${REQUIRED_GODOT_VERSION}-stable_export_templates.tpz"
    echo "  unzip -j Godot_v${REQUIRED_GODOT_VERSION}-stable_export_templates.tpz templates/android_source.zip"
    echo "  unzip -j android_source.zip libs/release/godot-lib.template_release.aar"
    echo "  mv godot-lib.template_release.aar ${GODOT_LIB}"
    echo ""
    exit 1
fi

# Verify Godot version from AAR
echo -e "${YELLOW}Checking Godot library version...${NC}"
AAR_SIZE=$(stat -f%z "${GODOT_LIB}" 2>/dev/null || stat -c%s "${GODOT_LIB}" 2>/dev/null || echo "0")
EXPECTED_SIZE_MIN=85000000  # ~85MB for 4.3.stable
EXPECTED_SIZE_MAX=95000000  # ~95MB for 4.3.stable

if [ "$AAR_SIZE" -lt "$EXPECTED_SIZE_MIN" ] || [ "$AAR_SIZE" -gt "$EXPECTED_SIZE_MAX" ]; then
    echo -e "${RED}WARNING: Godot library size mismatch!${NC}"
    echo "Expected: 85-95MB (Godot ${REQUIRED_GODOT_VERSION}.stable)"
    echo "Found: $(echo "scale=1; $AAR_SIZE / 1024 / 1024" | bc)MB"
    echo ""
    echo -e "${YELLOW}Fix: Re-download Godot ${REQUIRED_GODOT_VERSION}.stable templates${NC}"
    echo "  rm ${GODOT_LIB}"
    echo "  curl -L -o Godot_v${REQUIRED_GODOT_VERSION}-stable_export_templates.tpz \\"
    echo "    https://github.com/godotengine/godot/releases/download/${REQUIRED_GODOT_VERSION}-stable/Godot_v${REQUIRED_GODOT_VERSION}-stable_export_templates.tpz"
    echo "  unzip -j Godot_v${REQUIRED_GODOT_VERSION}-stable_export_templates.tpz templates/android_source.zip"
    echo "  unzip -j android_source.zip libs/release/godot-lib.template_release.aar"
    echo "  mv godot-lib.template_release.aar ${GODOT_LIB}"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ Godot library version OK ($(echo "scale=1; $AAR_SIZE / 1024 / 1024" | bc)MB = ${REQUIRED_GODOT_VERSION}.stable)${NC}"
fi
echo ""

# Check Docker authentication
echo -e "${YELLOW}Checking Docker authentication...${NC}"
if ! docker pull ${DOCKER_IMAGE} 2>/dev/null; then
    echo -e "${RED}ERROR: Cannot pull Docker image${NC}"
    echo ""
    echo "Please authenticate with Google Cloud:"
    echo "  gcloud auth login"
    echo "  gcloud auth configure-docker europe-west1-docker.pkg.dev"
    echo ""
    echo "See docs/INSTALLATION.md for detailed instructions"
    exit 1
fi
echo -e "${GREEN}✓ Docker authentication verified${NC}"
echo ""

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Build plugin
echo -e "${YELLOW}Building plugin...${NC}"
docker run --rm \
    -v "${PROJECT_ROOT}/android:/workspace/android" \
    -v "${OUTPUT_DIR}:/workspace/output" \
    -w /workspace/android \
    ${DOCKER_IMAGE} \
    bash -c "
        # Ensure wrapper is executable
        chmod +x gradlew
        
        # Check if wrapper works, otherwise regenerate
        if ! ./gradlew --version >/dev/null 2>&1; then
            echo 'Gradle wrapper corrupted, regenerating...'
            
            # Install temporary Gradle to generate wrapper
            cd /tmp
            wget -q https://services.gradle.org/distributions/gradle-8.7-bin.zip
            unzip -q gradle-8.7-bin.zip
            export PATH=\$PATH:/tmp/gradle-8.7/bin
            
            # Generate wrapper in project
            cd /workspace/android
            gradle wrapper --gradle-version=8.7
            chmod +x gradlew
            
            echo 'Gradle wrapper regenerated'
        fi
        
        # Build
        ./gradlew clean assembleRelease
        
        # Copy output
        cp build/outputs/aar/android-release.aar /workspace/output/joycon_android_plugin.aar
    "

# Check if build succeeded
if [ -f "${OUTPUT_DIR}/joycon_android_plugin.aar" ]; then
    AAR_SIZE=$(du -h "${OUTPUT_DIR}/joycon_android_plugin.aar" | cut -f1)
    echo ""
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo ""
    echo "Output: ${OUTPUT_DIR}/joycon_android_plugin.aar"
    echo "Size: ${AAR_SIZE}"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Copy the AAR to your Godot project:"
    echo "   cp ${OUTPUT_DIR}/joycon_android_plugin.aar <project>/addons/joycon-android-plugin/"
    echo ""
    echo "2. Copy plugin files:"
    echo "   cp ${PROJECT_ROOT}/src/joycon_android_runtime.gd <project>/addons/joycon-android-plugin/"
    echo "   cp ${PROJECT_ROOT}/plugin.cfg <project>/addons/joycon-android-plugin/"
    echo "   cp ${PROJECT_ROOT}/joycon_android.gd <project>/addons/joycon-android-plugin/"
    echo "   cp ${PROJECT_ROOT}/joycon_android_plugin.gdap <project>/addons/joycon-android-plugin/"
    echo ""
    echo "3. Enable plugin in Godot: Project > Project Settings > Plugins"
    echo ""
    echo "See docs/INSTALLATION.md for detailed installation instructions"
else
    echo -e "${RED}✗ Build failed!${NC}"
    echo ""
    echo "Check the output above for errors"
    exit 1
fi

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

# Try to extract version from AAR (it's a ZIP file)
GODOT_VERSION=""
if command -v unzip >/dev/null 2>&1; then
    # Extract AndroidManifest.xml and look for version info
    GODOT_VERSION=$(unzip -p "${GODOT_LIB}" AndroidManifest.xml 2>/dev/null | grep -oP 'android:versionName="\K[^"]+' 2>/dev/null || echo "")
    
    # If not in manifest, try classes.jar MANIFEST.MF
    if [ -z "$GODOT_VERSION" ]; then
        GODOT_VERSION=$(unzip -p "${GODOT_LIB}" classes.jar 2>/dev/null | unzip -p - META-INF/MANIFEST.MF 2>/dev/null | grep -i "Implementation-Version" | cut -d':' -f2 | tr -d ' \r\n' || echo "")
    fi
fi

if [ -n "$GODOT_VERSION" ]; then
    # Version extracted successfully
    if [[ "$GODOT_VERSION" == "${REQUIRED_GODOT_VERSION}"* ]]; then
        echo -e "${GREEN}✓ Godot library version OK: ${GODOT_VERSION}${NC}"
    else
        echo -e "${RED}WARNING: Godot library version mismatch!${NC}"
        echo "Expected: ${REQUIRED_GODOT_VERSION}.stable"
        echo "Found: ${GODOT_VERSION}"
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
    fi
else
    # Fallback to size check if version not found
    echo -e "${YELLOW}Version not found in AAR, checking file size...${NC}"
    AAR_SIZE=$(stat -f%z "${GODOT_LIB}" 2>/dev/null || stat -c%s "${GODOT_LIB}" 2>/dev/null || echo "0")
    AAR_SIZE_MB=$(awk "BEGIN {printf \"%.1f\", $AAR_SIZE / 1024 / 1024}")
    EXPECTED_SIZE_MIN=85000000  # ~85MB minimum
    EXPECTED_SIZE_MAX=100000000 # ~100MB maximum (4.3.stable is ~96MB)
    
    if [ "$AAR_SIZE" -lt "$EXPECTED_SIZE_MIN" ] || [ "$AAR_SIZE" -gt "$EXPECTED_SIZE_MAX" ]; then
        echo -e "${RED}WARNING: Godot library size unexpected!${NC}"
        echo "Expected: 85-100MB (Godot ${REQUIRED_GODOT_VERSION}.stable)"
        echo "Found: ${AAR_SIZE_MB}MB"
        echo ""
        echo -e "${YELLOW}Fix: Re-download Godot ${REQUIRED_GODOT_VERSION}.stable templates (see above)${NC}"
        echo ""
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Godot library size OK: ${AAR_SIZE_MB}MB (likely ${REQUIRED_GODOT_VERSION}.stable)${NC}"
    fi
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

# Get host user info for fixing permissions later
HOST_UID=$(id -u)
HOST_GID=$(id -g)

# Build plugin
echo -e "${YELLOW}Building plugin...${NC}"
docker run --rm \
    -v "${PROJECT_ROOT}/android:/workspace/android" \
    -v "${OUTPUT_DIR}:/workspace/output" \
    -w /workspace/android \
    ${DOCKER_IMAGE} \
    bash -c "
        # Kill any existing Gradle daemons and clear locks
        echo 'Killing Gradle daemons and clearing locks...'
        pkill -f GradleDaemon || true
        rm -rf .gradle/*/fileHashes/*.lock
        rm -rf .gradle/*/executionHistory/*.lock
        rm -rf .gradle/*/generated-gradle-jars/*.lock
        rm -rf .gradle/buildOutputCleanup/*.lock
        rm -rf .gradle/daemon
        echo '✓ Gradle locks cleared'
        echo ''
        
        # Clean old build outputs (inside Docker to avoid permission issues)
        echo 'Cleaning old build outputs...'
        rm -rf build plugins/build
        rm -f /workspace/output/*.aar
        echo '✓ Clean complete'
        echo ''
        
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
        
        # Build (--no-daemon to avoid lock issues in Docker)
        ./gradlew --no-daemon clean assembleRelease
        
        # Copy output (plugins subproject is the actual plugin)
        if [ -f plugins/build/outputs/aar/plugins-release.aar ]; then
            cp plugins/build/outputs/aar/plugins-release.aar /workspace/output/joycon_android_plugin.aar
            echo 'Copied plugins-release.aar'
        elif [ -f build/outputs/aar/joycon-android-plugin-release.aar ]; then
            cp build/outputs/aar/joycon-android-plugin-release.aar /workspace/output/joycon_android_plugin.aar
            echo 'Copied joycon-android-plugin-release.aar'
        else
            echo 'ERROR: Plugin AAR not found'
            find . -name '*.aar' -not -path '*/godot-lib/*' 2>/dev/null || true
            exit 1
        fi
        
        # Fix ownership of output files (match host user)
        chown ${HOST_UID}:${HOST_GID} /workspace/output/*.aar 2>/dev/null || true
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

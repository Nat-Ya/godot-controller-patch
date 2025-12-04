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

# Check if godot-lib.release.aar exists
if [ ! -f "${PROJECT_ROOT}/android/godot-lib/godot-lib.release.aar" ]; then
    echo -e "${RED}ERROR: godot-lib.release.aar not found!${NC}"
    echo ""
    echo "Please download the Godot AAR library:"
    echo "1. Download from https://godotengine.org/download/4.x/linux"
    echo "   OR build from source: https://github.com/godotengine/godot"
    echo ""
    echo "2. Extract godot-lib.release.aar from the templates"
    echo ""
    echo "3. Copy to: ${PROJECT_ROOT}/android/godot-lib/"
    echo ""
    exit 1
fi

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
        # Setup Gradle wrapper if not present
        if [ ! -f gradlew ]; then
            echo 'Setting up Gradle wrapper...'
            
            # Install temporary Gradle to generate wrapper
            cd /tmp
            wget -q https://services.gradle.org/distributions/gradle-8.10-bin.zip
            unzip -q gradle-8.10-bin.zip
            export PATH=\$PATH:/tmp/gradle-8.10/bin
            
            # Generate wrapper in project
            cd /workspace/android
            gradle wrapper --gradle-version=8.10
            
            echo 'Gradle wrapper created'
        fi
        
        # Build with wrapper
        cd /workspace/android
        chmod +x gradlew
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

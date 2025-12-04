#!/bin/bash
set -e

# Script to download Godot library AAR for building the plugin
# This is useful for local development

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GODOT_LIB_DIR="${PROJECT_ROOT}/android/godot-lib"
GODOT_VERSION="${1:-4.3-stable}"

echo "====================================="
echo "Godot Library Downloader"
echo "====================================="
echo ""
echo "Godot Version: ${GODOT_VERSION}"
echo "Target Directory: ${GODOT_LIB_DIR}"
echo ""

# Check if already exists
if [ -f "${GODOT_LIB_DIR}/godot-lib.release.aar" ]; then
    echo "✓ godot-lib.release.aar already exists"
    ls -lh "${GODOT_LIB_DIR}/godot-lib.release.aar"
    echo ""
    read -p "Do you want to re-download? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing file. Exiting."
        exit 0
    fi
fi

# Create directory if it doesn't exist
mkdir -p "${GODOT_LIB_DIR}"

# Download Godot export templates
GODOT_TEMPLATES_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz"

echo "Downloading Godot export templates..."
echo "URL: ${GODOT_TEMPLATES_URL}"
echo ""

if ! wget -q --show-progress "${GODOT_TEMPLATES_URL}" -O /tmp/godot-templates.tpz; then
    echo "❌ Failed to download Godot templates"
    echo ""
    echo "Please check:"
    echo "  1. Internet connectivity"
    echo "  2. Godot version is correct (e.g., 4.3-stable)"
    echo "  3. URL is accessible: ${GODOT_TEMPLATES_URL}"
    exit 1
fi

echo ""
echo "✓ Download complete"
echo ""

# Extract the AAR from the templates
echo "Extracting godot-lib.release.aar..."

if ! unzip -q /tmp/godot-templates.tpz "templates/android_source.zip" -d /tmp/; then
    echo "❌ Failed to extract android_source.zip from templates"
    rm -f /tmp/godot-templates.tpz
    exit 1
fi

if ! unzip -q /tmp/templates/android_source.zip "libs/release/*.aar" -d /tmp/; then
    echo "❌ Failed to extract AAR from android_source.zip"
    rm -f /tmp/godot-templates.tpz /tmp/templates/android_source.zip
    exit 1
fi

# Copy the AAR to the expected location
cp /tmp/libs/release/*.aar "${GODOT_LIB_DIR}/godot-lib.release.aar"

# Cleanup
rm -f /tmp/godot-templates.tpz
rm -rf /tmp/templates /tmp/libs

echo "✓ Extraction complete"
echo ""
echo "====================================="
echo "Success!"
echo "====================================="
echo ""
echo "Godot library downloaded to:"
ls -lh "${GODOT_LIB_DIR}/godot-lib.release.aar"
echo ""
echo "You can now build the plugin with:"
echo "  cd android && ./gradlew assembleRelease"
echo ""

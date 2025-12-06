#!/bin/bash
# Pre-flight test validator for Joy-Con L plugin

set -e

echo "========================================"
echo "Joy-Con L Plugin - Pre-flight Check"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

check_file() {
    local file="$1"
    local name="$2"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $name exists"
        return 0
    else
        echo -e "${RED}✗${NC} $name NOT FOUND: $file"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

check_device() {
    if adb devices | grep -q "RFCNB0CQ4ZX"; then
        echo -e "${GREEN}✓${NC} Device RFCNB0CQ4ZX connected"
        return 0
    else
        echo -e "${RED}✗${NC} Device RFCNB0CQ4ZX not connected"
        echo "  Run: adb devices"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

check_plugin_built() {
    local plugin_aar="$1"
    if [ -f "$plugin_aar" ]; then
        local size=$(stat -f%z "$plugin_aar" 2>/dev/null || stat -c%s "$plugin_aar" 2>/dev/null || echo "0")
        if [ "$size" -gt 1000 ]; then
            echo -e "${GREEN}✓${NC} Plugin AAR exists (${size} bytes)"
            return 0
        else
            echo -e "${RED}✗${NC} Plugin AAR too small: ${size} bytes"
            ERRORS=$((ERRORS + 1))
            return 1
        fi
    else
        echo -e "${YELLOW}⚠${NC} Plugin AAR not found (needs build)"
        WARNINGS=$((WARNINGS + 1))
        return 1
    fi
}

echo "Checking build environment..."
echo ""

# Check Godot project
PROJECT_DIR="/c/Users/ygall/Documents/repos/a-treasure-for-Lora"
PLUGIN_PROJECT="/c/Users/ygall/Documents/repos/godot-controller-patch"

check_file "$PROJECT_DIR/project.godot" "Game project"
check_file "$PROJECT_DIR/export_presets.cfg" "Export config"
check_file "$PLUGIN_PROJECT/android/plugins/src/main/kotlin/fr/natnya/joycon/JoyConAndroidPlugin.kt" "Plugin source"
check_file "$PLUGIN_PROJECT/android/godot-lib/godot-lib.release.aar" "Godot library"

echo ""
echo "Checking plugin status..."
echo ""

PLUGIN_AAR="$PLUGIN_PROJECT/android/build/outputs/aar/plugins-release.aar"
if ! check_plugin_built "$PLUGIN_AAR"; then
    echo "  Build command: cd $PLUGIN_PROJECT/android && ./gradlew assembleRelease"
fi

echo ""
echo "Checking game plugin installation..."
echo ""

GAME_PLUGIN_AAR="$PROJECT_DIR/android/plugins/joycon_android_plugin.aar"
check_plugin_built "$GAME_PLUGIN_AAR"

echo ""
echo "Checking device connection..."
echo ""

if check_device; then
    echo ""
    echo "Device info:"
    adb -s RFCNB0CQ4ZX shell getprop ro.product.model
fi

echo ""
echo "========================================"
echo "Summary"
echo "========================================"

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ ALL CHECKS PASSED${NC}"
        echo ""
        echo "Ready to test! Commands:"
        echo ""
        echo "  # Build and install"
        echo "  cd $PROJECT_DIR"
        echo "  make clean && make install-apk"
        echo ""
        echo "  # Watch logs"
        echo "  adb logcat -c && adb logcat -s JoyConPlugin:I JoyConAndroid:I"
    else
        echo -e "${YELLOW}⚠ ${WARNINGS} WARNING(S)${NC}"
        echo ""
        echo "Can proceed but some features may not work."
    fi
else
    echo -e "${RED}✗ ${ERRORS} ERROR(S)${NC}"
    echo ""
    echo "Fix errors before testing."
    exit 1
fi

echo ""

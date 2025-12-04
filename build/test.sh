#!/bin/bash
set -e

# Test script for JoyCon Android Plugin
# Requires connected Android device with Joy-Con L paired

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_APK="${1:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== JoyCon Android Plugin Test ===${NC}"
echo ""

# Check ADB
if ! command -v adb &> /dev/null; then
    echo -e "${RED}ERROR: adb not found in PATH${NC}"
    echo "Install Android SDK Platform Tools"
    exit 1
fi

# Check device connection
echo -e "${YELLOW}Checking device connection...${NC}"
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${RED}ERROR: No Android devices connected${NC}"
    echo "Connect device via USB and enable USB debugging"
    exit 1
fi
DEVICE_NAME=$(adb shell getprop ro.product.model | tr -d '\r')
echo -e "${GREEN}✓ Device connected: ${DEVICE_NAME}${NC}"
echo ""

# Check Joy-Con connection
echo -e "${YELLOW}Checking Joy-Con L connection...${NC}"
JOYCON_EVENTS=$(adb shell getevent -S 2>&1 | grep -i "joy-con" | grep -i "left\|L" || true)
if [ -z "$JOYCON_EVENTS" ]; then
    echo -e "${RED}WARNING: Joy-Con L not detected${NC}"
    echo "Please pair Joy-Con L via Bluetooth before testing"
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ Joy-Con L detected${NC}"
    echo "$JOYCON_EVENTS"
fi
echo ""

# Install APK if provided
if [ -n "$TEST_APK" ]; then
    if [ ! -f "$TEST_APK" ]; then
        echo -e "${RED}ERROR: APK not found: $TEST_APK${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Installing APK...${NC}"
    adb install -r "$TEST_APK"
    echo -e "${GREEN}✓ APK installed${NC}"
    echo ""
fi

# Monitor logs
echo -e "${BLUE}Monitoring Godot logs...${NC}"
echo "Press Joy-Con L buttons to test (Ctrl+C to stop)"
echo ""
echo -e "${YELLOW}Expected logs:${NC}"
echo "  [JoyConAndroid] Plugin connected"
echo "  [JoyConAndroid] Button X pressed on device Y"
echo ""

# Clear old logs
adb logcat -c

# Monitor with filters
adb logcat -s godot:I godot:D godot:W godot:E \
    | grep --line-buffered -E "JoyCon|Button|Input|Joy" \
    | while read -r line; do
        if [[ "$line" =~ "pressed" ]]; then
            echo -e "${GREEN}${line}${NC}"
        elif [[ "$line" =~ "released" ]]; then
            echo -e "${BLUE}${line}${NC}"
        elif [[ "$line" =~ "ERROR" ]]; then
            echo -e "${RED}${line}${NC}"
        elif [[ "$line" =~ "WARN" ]]; then
            echo -e "${YELLOW}${line}${NC}"
        else
            echo "$line"
        fi
    done

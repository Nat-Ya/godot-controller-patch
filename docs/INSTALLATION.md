# Installation Guide

## Prerequisites

### Required Software

1. **Docker** (20.10+)
   ```bash
   docker --version
   ```

2. **Google Cloud SDK**
   ```bash
   gcloud --version
   ```

3. **Git**
   ```bash
   git --version
   ```

4. **Godot 4.3.stable** (for testing)
   - Download from: https://godotengine.org/download

## Google Cloud Authentication

### Step 1: Login to GCloud

```bash
gcloud auth login
```

This will open a browser for you to authenticate with your Google account.

### Step 2: Configure Docker Authentication

```bash
gcloud auth configure-docker europe-west1-docker.pkg.dev
```

This configures Docker to use your GCloud credentials when pulling from the artifact registry.

### Step 3: Verify Access

```bash
gcloud auth list
```

You should see your account marked as ACTIVE.

## Pull Build Container

### Download the Android Build Image

```bash
docker pull europe-west1-docker.pkg.dev/general-476320/android-build-images/android-build-image:latest
```

**Note:** This image is ~2-3GB and contains:
- Android SDK 34
- Build Tools 34.0.0
- Gradle 8.x
- Kotlin compiler
- JDK 17

### Verify Image

```bash
docker images | grep android-build-image
```

## Clone Repository

```bash
git clone https://github.com/Nat-Ya/godot-controller-patch.git
cd godot-controller-patch
```

## Download Godot AAR Library

### Option A: Official Release

1. Go to https://godotengine.org/download
2. Download "Godot 4.3.stable - Android library"
3. Extract `godot-lib.release.aar`
4. Copy to `android/godot-lib/`

```bash
mkdir -p android/godot-lib
cp ~/Downloads/godot-lib.release.aar android/godot-lib/
```

### Option B: Build from Source (Advanced)

```bash
git clone https://github.com/godotengine/godot.git --branch 4.3-stable
cd godot
scons platform=android target=template_release arch=arm64
# Output: bin/godot-lib.release.aar
```

## Build Plugin

### Using Docker (Recommended)

```bash
./build/build.sh
```

This script:
1. Mounts project directory into container
2. Runs Gradle build
3. Copies AAR to project root

### Manual Build (Without Docker)

**Prerequisites:**
- Android SDK installed
- `ANDROID_HOME` environment variable set
- Gradle 8.x

```bash
cd android
./gradlew assembleRelease
cp build/outputs/aar/android-release.aar ../joycon_android_plugin.aar
```

## Verify Build

```bash
ls -lh joycon_android_plugin.aar
```

Expected output: ~50KB AAR file

## Install in Godot Project

### Step 1: Copy Plugin Files

```bash
cp -r . <your-godot-project>/addons/joycon-android-plugin/
```

**Files to copy:**
- `plugin.cfg`
- `joycon_android.gd`
- `joycon_android_plugin.gdap`
- `joycon_android_plugin.aar`
- `src/joycon_android_runtime.gd`

### Step 2: Enable Plugin

1. Open Godot project
2. Go to **Project → Project Settings → Plugins**
3. Enable "JoyCon Android Plugin"

### Step 3: Add Autoload

1. Go to **Project → Project Settings → Autoload**
2. Add:
   - **Name:** `JoyConAndroid`
   - **Path:** `res://addons/joycon-android-plugin/src/joycon_android_runtime.gd`
   - **Enable:** ✓

### Step 4: Configure Android Export

1. **Project → Export → Android**
2. Check **Use Custom Build**: ✓
3. Under **Plugins**, enable: **JoyConAndroidPlugin**

## Test Plugin

### Create Test Scene

```gdscript
extends Node

func _ready() -> void:
    if JoyConAndroid:
        JoyConAndroid.button_pressed.connect(_on_button)
        print("JoyCon plugin ready!")
    else:
        print("JoyCon plugin not available")

func _on_button(device_id: int, button_index: int) -> void:
    print("Button %d pressed on device %d" % [button_index, device_id])
```

### Export and Install

```bash
# In Godot
# Project → Export → Android → Export Project
# Save as: test-joycon.apk

# Install
adb install -r test-joycon.apk

# Monitor logs
adb logcat -s godot:I
```

### Test Buttons

Connect Joy-Con L and press:
- D-pad (should log indices 11-14)
- L button (index 4)
- ZL button (index 6)
- Screenshot button (index 16)

## Troubleshooting

### GCloud Auth Issues

```bash
# Clear cached credentials
gcloud auth revoke
gcloud auth login
```

### Docker Pull Fails

```bash
# Check authentication
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin europe-west1-docker.pkg.dev

# Or use application default credentials
gcloud auth application-default login
```

### Build Fails - Missing Godot AAR

```
Error: Could not find godot-lib.release.aar
```

**Solution:** Copy Godot AAR to `android/godot-lib/` directory.

### Plugin Not Detected in Godot

1. Verify `joycon_android_plugin.gdap` exists
2. Check `plugin.cfg` syntax
3. Restart Godot editor
4. Check **Output** panel for errors

### Buttons Not Working on Device

1. Check ADB logs: `adb logcat -s godot:I`
2. Verify plugin connected: Should see "[JoyConAndroid] Plugin connected"
3. Test with `getevent`: `adb shell getevent /dev/input/event11`
4. Ensure custom Android build is used (not template)

## Development Workflow

### Quick Rebuild

```bash
cd android
./gradlew clean assembleRelease && cp build/outputs/aar/android-release.aar ../joycon_android_plugin.aar
```

### Hot Reload (Without Re-export)

Not possible - native plugins require full APK rebuild and reinstall.

### Debugging Native Code

```bash
# Enable verbose logging in plugin
# Edit JoyConAndroidPlugin.kt, add:
android.util.Log.d("JoyConPlugin", "Button pressed: $keyCode")

# Monitor logs
adb logcat | grep JoyConPlugin
```

## Next Steps

- Read [SPECIFICATION.md](SPECIFICATION.md) for technical details
- Read [AGENTS.md](../AGENTS.md) for development guidelines
- See [README.md](../README.md) for usage examples

---

**Last Updated:** December 4, 2025

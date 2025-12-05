# Build Instructions

This document describes how to build the JoyCon Android Plugin AAR.

## Automated Build (GitHub Actions)

The easiest way to get a built AAR is through GitHub Actions:

1. Go to the [Actions tab](https://github.com/Nat-Ya/godot-controller-patch/actions)
2. Select the "Build Android Plugin" workflow
3. Click "Run workflow" (or it runs automatically on push)
4. Download the artifact once the build completes

The workflow automatically:
- Downloads the Godot library from official releases
- Sets up the Android SDK
- Builds the plugin AAR
- Uploads the artifact

## Local Build

### Prerequisites

- **JDK 17** or newer
- **Android SDK** with:
  - Platform: `android-34`
  - Build Tools: `34.0.0`
- **Gradle** 8.7 or newer (or use the wrapper)

### Option 1: Using Gradle Wrapper (Recommended)

```bash
# Download Godot library (if not already present)
./scripts/download-godot-lib.sh

# Navigate to android directory
cd android

# Build the plugin
./gradlew assembleRelease

# Output will be at:
# android/plugins/build/outputs/aar/plugins-release.aar
```

### Option 2: Using Docker (Original Method)

If you have access to the Google Cloud Artifact Registry:

```bash
# Authenticate with Google Cloud
gcloud auth login
gcloud auth configure-docker europe-west1-docker.pkg.dev

# Download Godot library to android/godot-lib/

# Run build script
./build/build.sh

# Output will be at:
# build/output/joycon_android_plugin.aar
```

## Build Output

The build produces:
- **AAR file**: `plugins-release.aar` (renamed to `joycon_android_plugin.aar`)
- **Size**: ~50KB
- **Contents**:
  - Compiled Kotlin classes
  - AndroidManifest.xml
  - Plugin metadata

## Troubleshooting

### Gradle Build Fails

**Issue**: `Could not resolve com.android.tools.build:gradle`

**Solution**: Ensure you have internet connectivity and the Google Maven repository is accessible.

**Issue**: `JAVA_HOME is not set`

**Solution**: 
```bash
export JAVA_HOME=/path/to/jdk17
export PATH=$JAVA_HOME/bin:$PATH
```

### Missing Godot Library

**Issue**: `Could not find godot-lib.*.aar`

**Solution**: Download the Godot library as described in `android/godot-lib/README.md`

### Android SDK Not Found

**Issue**: `Android SDK location not found`

**Solution**:
```bash
export ANDROID_HOME=/path/to/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
```

Or create `android/local.properties`:
```properties
sdk.dir=/path/to/android-sdk
```

## Verification

After building, verify the AAR:

```bash
# Check file size
ls -lh android/plugins/build/outputs/aar/plugins-release.aar

# List contents
unzip -l android/plugins/build/outputs/aar/plugins-release.aar

# Verify manifest
unzip -p android/plugins/build/outputs/aar/plugins-release.aar AndroidManifest.xml | xmllint --format -
```

## Clean Build

To start fresh:

```bash
cd android
./gradlew clean
# or
rm -rf plugins/build .gradle
```

## CI/CD Integration

The GitHub Actions workflow (`.github/workflows/build-plugin.yml`) handles:
- Downloading dependencies
- Building the plugin
- Creating checksums
- Uploading artifacts with 30-day retention
- Build info generation

Artifacts are available under:
- **joycon-android-plugin**: Contains the AAR and SHA256 checksum
- **build-info**: Contains build metadata

## Known Issues in Code

Note: These are pre-existing issues in the plugin logic (not build-related):

1. **Button Mapping Conflict**: Both `KEYCODE_BUTTON_L2` (ZL) and `KEYCODE_BUTTON_SELECT` (Minus) are mapped to Godot index 6, which may cause conflicts
2. **pollJoyConButtons Implementation**: Uses `hasKeys()` which checks device capability, not current button state

These issues do not affect the build process but may impact runtime functionality.

## Next Steps

After building:
1. Copy the AAR to your Godot project's `addons/` directory
2. Copy the GDScript files from `src/`
3. Enable the plugin in Godot Project Settings
4. See [INSTALLATION.md](INSTALLATION.md) for detailed setup instructions

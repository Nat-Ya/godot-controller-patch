# Godot Library Directory

This directory should contain the Godot library AAR file (`godot-lib.release.aar`) required to build the plugin.

## For GitHub Actions (CI/CD)

The GitHub Actions workflow automatically downloads this file from the official Godot releases.

## For Local Development

If you want to build locally, you need to manually place the Godot library here:

1. Download Godot 4.3 export templates from: https://godotengine.org/download/4.x/linux
2. Extract the downloaded `.tpz` file
3. Navigate to `templates/android_source.zip` and extract it
4. Copy `libs/release/*.aar` to this directory as `godot-lib.release.aar`

Or use the build script which handles this automatically:
```bash
./build/build.sh
```

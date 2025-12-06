#!/bin/bash

# Build Godot AAR library from source using Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/android/godot-lib"

echo "=== Building Godot AAR Library from Source ==="
echo ""
echo "This will:"
echo "  1. Build a Docker image with Godot build environment"
echo "  2. Compile Godot 4.3-stable Android templates"
echo "  3. Extract godot-lib.release.aar to: $OUTPUT_DIR"
echo ""
echo "⚠️  WARNING: This takes 30-60 minutes and requires ~10GB disk space!"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Build Docker image
echo ""
echo "📦 Building Docker image..."
docker build -f "$SCRIPT_DIR/Dockerfile.godot-lib" -t godot-lib-builder "$SCRIPT_DIR"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run container and copy output
echo ""
echo "🚀 Extracting godot-lib.release.aar..."
CONTAINER_ID=$(docker create godot-lib-builder)
docker cp "$CONTAINER_ID:/output/godot-lib.release.aar" "$OUTPUT_DIR/godot-lib.release.aar"
docker rm "$CONTAINER_ID"

# Verify
if [ -f "$OUTPUT_DIR/godot-lib.release.aar" ]; then
    SIZE=$(ls -lh "$OUTPUT_DIR/godot-lib.release.aar" | awk '{print $5}')
    echo ""
    echo "✅ Success! godot-lib.release.aar ($SIZE) is ready at:"
    echo "   $OUTPUT_DIR/godot-lib.release.aar"
    echo ""
    echo "You can now run: ./build/build.sh"
else
    echo ""
    echo "❌ Error: Failed to extract godot-lib.release.aar"
    exit 1
fi

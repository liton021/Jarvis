#!/bin/bash
# Release build script for Gemini Chat
# Usage: ./build_release.sh <version>
# Example: ./build_release.sh 1.0.0

set -e

VERSION=${1:-"1.0.0"}
BUILD_NUMBER=$(date +%Y%m%d%H%M)

echo "==================================="
echo "Building Gemini Chat v$VERSION"
echo "Build number: $BUILD_NUMBER"
echo "==================================="

# Update version in pubspec.yaml
echo "Updating pubspec.yaml version..."
sed -i "s/^version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Generate code
echo "Generating code..."
dart run build_runner build --delete-conflicting-outputs

# Build APKs (split per ABI)
echo "Building APKs (split per ABI)..."
flutter build apk --release --split-per-abi

# Build App Bundle
echo "Building App Bundle..."
flutter build appbundle --release

# Build universal APK (for direct install)
echo "Building universal APK..."
flutter build apk --release

echo ""
echo "==================================="
echo "Build complete! Output files:"
echo "==================================="
echo ""
echo "Split APKs:"
ls -lh build/app/outputs/flutter-apk/app-*-release.apk 2>/dev/null || true
echo ""
echo "Universal APK:"
ls -lh build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || true
echo ""
echo "App Bundle:"
ls -lh build/app/outputs/bundle/release/app-release.aab 2>/dev/null || true
echo ""
echo "==================================="
echo "To create GitHub release:"
echo "  gh release create v$VERSION \\"
echo "    build/app/outputs/flutter-apk/*.apk \\"
echo "    build/app/outputs/bundle/release/*.aab \\"
echo "    --title \"Gemini Chat v$VERSION\" \\"
echo "    --notes \"Release v$VERSION\""
echo "==================================="
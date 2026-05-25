#!/bin/bash

# build_android_release.sh
# Script to build a signed Android App Bundle for Room Booker.

# Exit on error
set -e

# Configuration - Ensure these match your local environment
export ANDROID_KEYSTORE_PATH="/home/parkeroth/RoomBooker/android/app/upload-keystore.jks"
export ANDROID_KEYSTORE_PASSWORD="roombooker123"
export ANDROID_KEY_ALIAS="upload"
export ANDROID_KEY_PASSWORD="roombooker123"

echo "----------------------------------------------------"
echo "Building Room Booker Android Release (Signed)"
echo "----------------------------------------------------"
echo "Keystore: $ANDROID_KEYSTORE_PATH"
echo "Alias:    $ANDROID_KEY_ALIAS"
echo "----------------------------------------------------"

# Clean build artifacts to ensure a fresh build
flutter clean

# Get dependencies
flutter pub get

# Build the app bundle
# Using --android-skip-build-dependency-validation to skip the Gradle/NDK warnings we saw earlier
flutter build appbundle --release --android-skip-build-dependency-validation

echo ""
echo "----------------------------------------------------"
echo "SUCCESS: Signed bundle created at:"
echo "build/app/outputs/bundle/release/app-release.aab"
echo "----------------------------------------------------"
echo "You can now download this file via SCP or VS Code."

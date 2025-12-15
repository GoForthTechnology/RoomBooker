#!/bin/bash

# Default values
COMMIT=false
PUSH=false
PART=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -c)
      COMMIT=true
      shift # past argument
      ;;
    -p)
      PUSH=true
      shift # past argument
      ;;
    -cp)
      COMMIT=true
      PUSH=true
      shift # past argument
      ;;
    major|minor|patch)
      PART=$1
      shift # past argument
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [-c] [-p] [-cp] {major|minor|patch}"
      exit 1
      ;;
  esac
done

# Check if version part is provided
if [ -z "$PART" ]; then
  echo "Usage: $0 [-c] [-p] [-cp] {major|minor|patch}"
  exit 1
fi

PUBSPEC="pubspec.yaml"

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC" ]; then
  echo "Error: $PUBSPEC not found."
  exit 1
fi

# Extract the current version line
VERSION_LINE=$(grep '^version: ' $PUBSPEC)
CURRENT_VERSION=$(echo $VERSION_LINE | sed 's/version: //')

# Split version into semantic part and build number
# Assuming format x.y.z+n
SEMANTIC_PART=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

# Split semantic part into major, minor, patch
MAJOR=$(echo $SEMANTIC_PART | cut -d'.' -f1)
MINOR=$(echo $SEMANTIC_PART | cut -d'.' -f2)
PATCH=$(echo $SEMANTIC_PART | cut -d'.' -f3)

# Increment based on argument
if [ "$PART" == "major" ]; then
  MAJOR=$((MAJOR + 1))
  MINOR=0
  PATCH=0
elif [ "$PART" == "minor" ]; then
  MINOR=$((MINOR + 1))
  PATCH=0
elif [ "$PART" == "patch" ]; then
  PATCH=$((PATCH + 1))
else
  echo "Invalid argument. Usage: $0 {major|minor|patch}"
  exit 1
fi

# Increment build number
BUILD_NUMBER=$((BUILD_NUMBER + 1))

# Construct new version
NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD_NUMBER"

echo "Bumping version from $CURRENT_VERSION to $NEW_VERSION"

# Update pubspec.yaml
# Using sed to replace the version line. 
# We use a temporary file to ensure compatibility with both GNU and BSD sed (macOS)
sed "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC > "${PUBSPEC}.tmp" && mv "${PUBSPEC}.tmp" $PUBSPEC

# Git operations
if [ "$COMMIT" = true ]; then
  git add $PUBSPEC
  git commit -m "Cut $NEW_VERSION"
fi

if [ "$PUSH" = true ]; then
  # Ensure we have committed before pushing if only -p was passed but changes were made
  # However, typically -p implies pushing existing commits. 
  # If the user wants to push THIS change, they should probably use -c as well or -cp.
  # But following the request strictly:
  git push origin HEAD
fi

echo "Done."

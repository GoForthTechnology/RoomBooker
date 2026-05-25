#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Parse arguments
RUN_CI=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --ci)
      RUN_CI=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--ci]"
      exit 1
      ;;
  esac
done

echo "🔵 Running Flutter tests..."
flutter test

echo -e "\n🔵 Running Cloud Functions tests..."
if [ -d "functions" ]; then
  cd functions
  if [ -d "node_modules" ]; then
    # We pass --watchAll=false to ensure Jest runs once and exits, 
    # overriding the default "jest --watchAll" in package.json
    npm test -- --watchAll=false
  else
    echo "⚠️  Skipping Functions tests: node_modules not found. Run 'npm install' in functions/."
  fi
  cd ..
else
  echo "⚠️  Skipping Functions tests: functions/ directory not found."
fi

if [ "$RUN_CI" = true ]; then
  echo -e "\n🔵 Running Local CI Workflow tests (act)..."
  
  if ! command -v act &> /dev/null; then
    echo "❌ Error: 'act' is not installed. Please install it to run CI tests locally."
    exit 1
  fi

  if [ ! -f ".secrets" ]; then
    echo "❌ Error: '.secrets' file not found. Create it from '.secrets.example' to run CI tests."
    exit 1
  fi

  # Simulate the tag trigger that the release workflows expect
  # We use the current version from pubspec.yaml to simulate the tag
  VERSION=$(grep '^version: ' pubspec.yaml | sed 's/version: //')
  TAG="v$VERSION"
  
  echo "Testing workflow for tag: $TAG"
  act push -s GITHUB_TOKEN=$(gh auth token 2>/dev/null || echo "dummy_token") \
    --secret-file .secrets \
    -g "$TAG"
fi

echo -e "\n✅ All requested tests passed!"

#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "🔵 Running Flutter tests..."
flutter test

echo "\n🔵 Running Cloud Functions tests..."
cd functions
# We pass --watchAll=false to ensure Jest runs once and exits, 
# overriding the default "jest --watchAll" in package.json
npm test -- --watchAll=false

echo "\n✅ All tests passed!"

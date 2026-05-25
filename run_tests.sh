#!/bin/bash
set -e

# Default behavior: run all if no flags are provided
RUN_FLUTTER=false
RUN_FUNCTIONS=false
RUN_CI=false
ANY_FLAG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --flutter)
      RUN_FLUTTER=true
      ANY_FLAG=true
      shift
      ;;
    --functions)
      RUN_FUNCTIONS=true
      ANY_FLAG=true
      shift
      ;;
    --ci)
      RUN_CI=true
      ANY_FLAG=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--flutter] [--functions] [--ci]"
      exit 1
      ;;
  esac
done

# If no flags provided, run all
if [ "$ANY_FLAG" = false ]; then
  RUN_FLUTTER=true
  RUN_FUNCTIONS=true
  RUN_CI=true
fi

# Function to run Flutter tests
run_flutter() {
  echo "🔵 Starting Flutter tests..."
  if ! flutter test; then
    echo "❌ Flutter tests failed!"
    return 1
  fi
  echo "✅ Flutter tests passed!"
}

# Function to run Functions tests
run_functions() {
  echo "🔵 Starting Cloud Functions tests..."
  if [ -d "functions" ]; then
    if nc -z localhost 8081 2>/dev/null; then
      cd functions
      if [ -d "node_modules" ]; then
        if ! npm test -- --watchAll=false; then
          echo "❌ Functions tests failed!"
          cd ..
          return 1
        fi
      else
        echo "⚠️  Skipping Functions tests: node_modules not found."
      fi
      cd ..
    else
      echo "⚠️  Skipping Functions tests: Firebase Emulators not detected on port 8081."
    fi
  else
    echo "⚠️  Skipping Functions tests: functions/ directory not found."
  fi
  echo "✅ Functions tests complete!"
}

# Function to run CI tests
run_ci() {
  echo "🔵 Starting Local CI Workflow tests (act)..."
  
  ACT_BIN="./bin/act"
  if ! command -v act &> /dev/null && [ ! -f "$ACT_BIN" ]; then
    echo "❌ Error: 'act' is not installed."
    return 1
  fi

  ACT_CMD=$(command -v act || echo "$ACT_BIN")

  if [ ! -f ".secrets" ]; then
    echo "❌ Error: '.secrets' file not found."
    return 1
  fi

  VERSION=$(grep '^version: ' pubspec.yaml | sed 's/version: //')
  TAG="v$VERSION"
  EVENT_FILE="act_event.json"
  
  cat <<EOF > "$EVENT_FILE"
{
  "ref": "refs/tags/$TAG",
  "ref_type": "tag"
}
EOF

  echo "Testing workflow for tag: $TAG"
  if ! $ACT_CMD push \
    -s GITHUB_TOKEN=$(gh auth token 2>/dev/null || echo "dummy_token") \
    --secret-file .secrets \
    -e "$EVENT_FILE" \
    --container-architecture linux/amd64; then
    echo "❌ CI tests failed!"
    rm "$EVENT_FILE"
    return 1
  fi

  rm "$EVENT_FILE"
  echo "✅ CI tests passed!"
}

# Execution Logic
if [ "$RUN_FLUTTER" = true ] && [ "$RUN_FUNCTIONS" = true ] && [ "$RUN_CI" = false ]; then
  # Parallelize Flutter and Functions if both are requested without CI
  echo "🚀 Running Flutter and Functions in parallel..."
  run_flutter & FLUTTER_PID=$!
  run_functions & FUNCTIONS_PID=$!
  
  wait $FLUTTER_PID || exit 1
  wait $FUNCTIONS_PID || exit 1
elif [ "$RUN_FLUTTER" = true ] && [ "$RUN_FUNCTIONS" = true ] && [ "$RUN_CI" = true ] && [ "$ANY_FLAG" = false ]; then
    # Parallelize fast tests first, then run CI sequentially
    echo "🚀 Running fast tests in parallel before CI..."
    run_flutter & FLUTTER_PID=$!
    run_functions & FUNCTIONS_PID=$!
    
    wait $FLUTTER_PID || exit 1
    wait $FUNCTIONS_PID || exit 1
    run_ci || exit 1
else
  # Individual or specific combinations run sequentially for clarity
  [ "$RUN_FLUTTER" = true ] && (run_flutter || exit 1)
  [ "$RUN_FUNCTIONS" = true ] && (run_functions || exit 1)
  [ "$RUN_CI" = true ] && (run_ci || exit 1)
fi

echo -e "\n🎉 All requested tests passed!"

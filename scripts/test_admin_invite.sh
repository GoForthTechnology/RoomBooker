#!/usr/bin/env bash
# Run Firestore security-rules tests for the direct-admin-invite feature.
#
# Usage:
#   scripts/test_admin_invite.sh
#
# Requires: firebase CLI, Node.js, and the emulator installed
#   firebase setup:emulators:firestore   (first time only)
#
# What it does:
#   1. Starts the Firestore emulator on port 8082
#   2. Runs rules.test.js with Jest
#   3. Stops the emulator automatically on exit

set -euo pipefail
cd "$(dirname "$0")/.."

echo "Starting Firestore emulator and running admin-invite rules tests..."

firebase emulators:exec \
  --only firestore \
  "cd functions && npx jest rules.test.js --runInBand --forceExit --testTimeout=15000"

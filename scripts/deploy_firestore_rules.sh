#!/usr/bin/env bash
# Deploy Firestore security rules (required for register/login to work).
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Deploying Firestore rules to Firebase project..."
firebase deploy --only firestore:rules
echo "Done."

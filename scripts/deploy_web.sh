#!/usr/bin/env bash
# Build Flutter web and deploy to Firebase Hosting.
# Others can open: https://smartcampusapp-bf9af.web.app (after first deploy)
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v firebase >/dev/null 2>&1; then
  echo "Install Firebase CLI: npm install -g firebase-tools"
  echo "Then: firebase login && firebase use smartcampusapp-bf9af"
  exit 1
fi

echo "==> Flutter pub get"
flutter pub get

echo "==> Building web (release)"
flutter build web --release --no-web-resources-cdn

echo "==> Deploying to Firebase Hosting"
firebase deploy --only hosting

echo ""
echo "Done. Share your Hosting URL from the output above (e.g. smartcampusapp-bf9af.web.app)"

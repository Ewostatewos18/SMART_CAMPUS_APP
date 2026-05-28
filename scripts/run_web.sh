#!/usr/bin/env bash
# Primary dev target: Flutter Web (Chrome/Chromium) — Firebase Auth + Firestore work here.
set -euo pipefail
cd "$(dirname "$0")/.."

if command -v chromium-browser >/dev/null 2>&1; then
  export CHROME_EXECUTABLE=/usr/bin/chromium-browser
elif command -v chromium >/dev/null 2>&1; then
  export CHROME_EXECUTABLE="$(command -v chromium)"
elif command -v google-chrome >/dev/null 2>&1; then
  export CHROME_EXECUTABLE="$(command -v google-chrome)"
else
  echo "Install Chromium: sudo apt install chromium-browser"
  exit 1
fi

echo "Smart Campus — running on Web (recommended for Ubuntu dev)"
echo "CHROME_EXECUTABLE=$CHROME_EXECUTABLE"
flutter pub get
exec flutter run -d chrome --no-web-resources-cdn "$@"

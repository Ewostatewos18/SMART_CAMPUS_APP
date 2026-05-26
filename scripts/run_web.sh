#!/usr/bin/env bash
# Run Smart Campus on Chromium (required on Linux — Firebase has no Linux desktop SDK).
set -euo pipefail
cd "$(dirname "$0")/.."

if command -v chromium-browser >/dev/null 2>&1; then
  export CHROME_EXECUTABLE=/usr/bin/chromium-browser
elif command -v chromium >/dev/null 2>&1; then
  export CHROME_EXECUTABLE="$(command -v chromium)"
elif command -v google-chrome >/dev/null 2>&1; then
  export CHROME_EXECUTABLE="$(command -v google-chrome)"
else
  echo "No Chromium/Chrome found. Install: sudo apt install chromium-browser"
  exit 1
fi

echo "Using CHROME_EXECUTABLE=$CHROME_EXECUTABLE"
flutter pub get
exec flutter run -d chrome "$@"

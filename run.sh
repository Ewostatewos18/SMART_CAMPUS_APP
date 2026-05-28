#!/usr/bin/env bash
# Smart Campus — run on Web (required on Ubuntu; Firebase does not support Linux desktop).
set -euo pipefail
cd "$(dirname "$0")"

if command -v chromium-browser >/dev/null 2>&1; then
  export CHROME_EXECUTABLE=/usr/bin/chromium-browser
elif command -v chromium >/dev/null 2>&1; then
  export CHROME_EXECUTABLE="$(command -v chromium)"
elif command -v google-chrome >/dev/null 2>&1; then
  export CHROME_EXECUTABLE="$(command -v google-chrome)"
else
  echo "Chromium not found. Install it:"
  echo "  sudo apt update && sudo apt install -y chromium-browser"
  exit 1
fi

echo "============================================"
echo " Smart Campus — starting in Chromium (Web)"
echo " CHROME_EXECUTABLE=$CHROME_EXECUTABLE"
echo "============================================"
echo ""
echo "Do NOT use: flutter run          (uses Linux — Firebase will fail)"
echo "Use this script or: flutter run -d chrome"
echo ""

flutter pub get
# Avoid loading CanvasKit from gstatic.com (fails when CDN is blocked / offline).
exec flutter run -d chrome --no-web-resources-cdn "$@"

#!/usr/bin/env bash
# Push to YOUR fork: https://github.com/Ewostatewos18/SMART_CAMPUS_APP
# (You cannot push to afom12/SMART_CAMPUS_APP unless afom12 adds you as collaborator.)
#
#   export GITHUB_TOKEN='ghp_your_Ewostatewos18_token'
#   ./scripts/push_to_github.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Create a token: https://github.com/settings/tokens (logged in as Ewostatewos18)"
  echo "Check scope: repo"
  echo ""
  echo "  export GITHUB_TOKEN='ghp_xxxxxxxx'"
  echo "  ./scripts/push_to_github.sh"
  exit 1
fi

git push "https://Ewostatewos18:${GITHUB_TOKEN}@github.com/Ewostatewos18/SMART_CAMPUS_APP.git" main

echo ""
echo "Fork: https://github.com/Ewostatewos18/SMART_CAMPUS_APP"
echo "Open a PR to official repo: https://github.com/afom12/SMART_CAMPUS_APP/compare"
unset GITHUB_TOKEN 2>/dev/null || true

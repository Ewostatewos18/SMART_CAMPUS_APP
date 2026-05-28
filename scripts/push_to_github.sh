#!/usr/bin/env bash
# Push to https://github.com/afom12/SMART_CAMPUS_APP
# Usage (run in your terminal — do NOT paste token in chat):
#   export GITHUB_TOKEN='ghp_your_token_here'
#   ./scripts/push_to_github.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Set your token first:"
  echo "  export GITHUB_TOKEN='ghp_xxxxxxxx'"
  echo "  ./scripts/push_to_github.sh"
  exit 1
fi

git remote set-url origin https://github.com/afom12/SMART_CAMPUS_APP.git
git push "https://afom12:${GITHUB_TOKEN}@github.com/afom12/SMART_CAMPUS_APP.git" main
echo ""
echo "Done. Check: https://github.com/afom12/SMART_CAMPUS_APP"
unset GITHUB_TOKEN 2>/dev/null || true

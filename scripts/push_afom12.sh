#!/usr/bin/env bash
# Push to official repo: https://github.com/afom12/SMART_CAMPUS_APP
# Run as afom12 (use afom12's token, not fikertekiflu's).
#
#   export GITHUB_TOKEN='ghp_your_afom12_token'
#   ./scripts/push_afom12.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Create a token at https://github.com/settings/tokens (logged in as afom12)"
  echo "Check scope: repo"
  echo ""
  echo "Then run:"
  echo "  export GITHUB_TOKEN='ghp_xxxxxxxx'"
  echo "  ./scripts/push_afom12.sh"
  exit 1
fi

git remote set-url origin https://github.com/afom12/SMART_CAMPUS_APP.git

# Commit optional staged files
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -m "Add push helper scripts" || true
fi

git push "https://afom12:${GITHUB_TOKEN}@github.com/afom12/SMART_CAMPUS_APP.git" main

echo ""
echo "Done: https://github.com/afom12/SMART_CAMPUS_APP"
unset GITHUB_TOKEN 2>/dev/null || true

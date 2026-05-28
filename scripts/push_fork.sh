#!/usr/bin/env bash
# Push to YOUR fork (Ewostatewos18) when you don't have write access to afom12 repo.
#
#   export GITHUB_TOKEN='ghp_your_Ewostatewos18_token'
#   ./scripts/push_fork.sh
set -euo pipefail
cd "$(dirname "$0")/.."

FORK_URL="${FORK_URL:-https://github.com/Ewostatewos18/SMART_CAMPUS_APP.git}"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Create a token: https://github.com/settings/tokens (repo scope)"
  echo "  export GITHUB_TOKEN='ghp_xxxxxxxx'"
  echo "  ./scripts/push_fork.sh"
  exit 1
fi

git push "https://Ewostatewos18:${GITHUB_TOKEN}@github.com/Ewostatewos18/SMART_CAMPUS_APP.git" main

echo ""
echo "Done: https://github.com/Ewostatewos18/SMART_CAMPUS_APP"

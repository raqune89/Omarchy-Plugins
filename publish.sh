#!/usr/bin/env bash
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! gh auth status >/dev/null 2>&1; then
  echo "==> GitHub CLI is not authenticated yet. Starting 'gh auth login'..."
  gh auth login -h github.com -p https -w
fi

echo "==> Creating public GitHub repository 'Omarchy-Plugins' and pushing..."
if git remote get-url origin >/dev/null 2>&1; then
  git push -u origin main
else
  gh repo create "Omarchy-Plugins" \
    --public \
    --description "Custom Omarchy status bar tools, tactical CAD-themed bar widgets, live theme sync hook, and one-step installer" \
    --source="." \
    --remote="origin" \
    --push
fi

echo ""
echo "==> Successfully published to GitHub!"
gh repo view --web || true

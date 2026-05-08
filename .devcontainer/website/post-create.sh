#!/bin/bash
set -euo pipefail

# Install Docusaurus website dependencies. Runs as `onCreateCommand` so
# the install is captured by Codespaces prebuilds.

echo "==> Installing website dependencies..."
if [ -f website/package-lock.json ]; then
  (cd website && npm ci --no-audit --no-fund)
  echo "==> Website dependencies installed (npm ci)"
elif [ -f website/package.json ]; then
  (cd website && npm install --no-audit --no-fund)
  echo "==> Website dependencies installed (npm install — no lockfile)"
else
  echo "==> website/package.json not found, skipping" >&2
  exit 1
fi

echo "==> Website dev environment ready"

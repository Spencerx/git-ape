#!/bin/bash
set -euo pipefail

# Install Docusaurus website dependencies. Runs as `onCreateCommand` so
# the install is captured by Codespaces prebuilds.

echo "==> Installing website dependencies..."
if [ -f website/package.json ]; then
  (cd website && npm install --no-audit --no-fund)
  echo "==> Website dependencies installed"
else
  echo "==> website/package.json not found, skipping" >&2
  exit 1
fi

echo "==> Website dev environment ready"

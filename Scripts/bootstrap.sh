#!/usr/bin/env bash
# Mac-only. Installs XcodeGen via Homebrew, then generates the Xcode projects.
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Install from https://brew.sh first." >&2
    exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "Installing xcodegen…"
    brew install xcodegen
fi

"$(dirname "$0")/generate-xcode.sh"

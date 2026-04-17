#!/usr/bin/env bash
set -euo pipefail
# Run PIKAPIKA scheme tests on iOS Simulator. Requires Xcode + a bootable simulator.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-platform=iOS Simulator,name=iPhone 17}"

echo "Booting simulator (if needed) and running tests: $DEST"
xcrun simctl list devices available | head -5 || true

xcodebuild -project "$ROOT/PIKAPIKA.xcodeproj" \
  -scheme PIKAPIKA \
  -destination "$DEST" \
  test

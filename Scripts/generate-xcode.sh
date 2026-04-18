#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for app in iOS macOS; do
    echo "== Generating Pika ($app) =="
    (cd "$ROOT/Apps/$app" && xcodegen generate)
done

echo "Done. Open Apps/iOS/Pika.xcodeproj or Apps/macOS/Pika.xcodeproj."

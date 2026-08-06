#!/bin/bash
# Build and launch the BorderBeamKit macOS demo — a native replica of the
# playground at beam.jakubantalik.com.
#
#   ./run.sh
#
# Requires: Xcode (the .metal shader needs Xcode's build system; SwiftPM alone
# leaves it uncompiled) and xcodegen (brew install xcodegen).
set -euo pipefail

XCODE="${XCODE_APP:-/Applications/Xcode.app}"
export DEVELOPER_DIR="$XCODE/Contents/Developer"

cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null; then
  echo "error: xcodegen not found — run: brew install xcodegen" >&2
  exit 1
fi

echo "▸ Generating project…"
xcodegen generate --quiet

echo "▸ Building…"
xcodebuild \
  -project BorderBeamDemo.xcodeproj \
  -scheme BorderBeamDemo \
  -configuration Debug \
  -derivedDataPath build \
  build > /tmp/borderbeam-demo-build.log 2>&1 \
  || { grep -E "error:" /tmp/borderbeam-demo-build.log | head -20; \
       echo "BUILD FAILED (full log: /tmp/borderbeam-demo-build.log)"; exit 1; }

APP="build/Build/Products/Debug/BorderBeamDemo.app"

echo "▸ Launching…"
open "$APP"
echo "✓ Running"

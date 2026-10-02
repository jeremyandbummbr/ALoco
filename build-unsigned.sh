#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
if ! xcodebuild -version >/dev/null 2>&1; then
    echo "Full Xcode is required. Install it, open it once, and install iOS platform support." >&2
    exit 1
fi

xcodebuild -project TLocation.xcodeproj -scheme TLocation \
    -configuration Debug -destination 'generic/platform=iOS' \
    -derivedDataPath build/DerivedData \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build

echo "Unsigned app: build/DerivedData/Build/Products/Debug-iphoneos/TLocation.app"
echo "For iPhone installation, open the Xcode project and select your own signing team."

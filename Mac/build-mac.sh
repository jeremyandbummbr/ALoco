#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
output_dir="/tmp/aloco-mac-preview-build/ALoco.app"
archive_path="${script_dir:h}/ALoco-Mac-Preview.zip"
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
mkdir -p "$output_dir/Contents/MacOS" "$output_dir/Contents/Resources"
cp "$script_dir/Info.plist" "$output_dir/Contents/Info.plist"
cp "$script_dir/../TLocation/Assets.xcassets/LaunchLogo.imageset/LaunchLogo.png" "$output_dir/Contents/Resources/LaunchLogo.png"
xcrun swiftc "$script_dir/ALocoMac.swift" \
  -parse-as-library -target arm64-apple-macos15.0 -sdk "$sdk_path" \
  -framework AppKit -framework CoreLocation -framework MapKit -framework SwiftUI \
  -o "$output_dir/Contents/MacOS/ALocoMac"
codesign --force --deep --sign - "$output_dir"
ditto -c -k --sequesterRsrc --keepParent "$output_dir" "$archive_path"
echo "Built $output_dir and $archive_path"

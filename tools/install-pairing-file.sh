#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID="${ALoco_BUNDLE_ID:-local.aloco.prototype}"
DEVICE_ID="${ALoco_DEVICE_ID:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONVERTER="$SCRIPT_DIR/convert-pymobiledevice3-pairing.py"
PAIRING_DIR="$HOME/.pymobiledevice3"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/aloco-pairing.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

say_line() { printf '%s\n' "$*"; }
fail() { printf '\nALoco setup stopped: %s\n' "$*" >&2; exit 1; }

say_line "ALoco Pairing Setup"
say_line "This adds this iPhone's private pairing file to the ALoco app."
say_line "The file stays on this Mac and this iPhone. It is not uploaded."
say_line ""

command -v xcrun >/dev/null 2>&1 || fail "Xcode command line tools were not found. Open Xcode once, then try again."
command -v python3 >/dev/null 2>&1 || fail "Python 3 was not found on this Mac."
[ -f "$CONVERTER" ] || fail "The pairing converter is missing from tools/."

if [ -z "$DEVICE_ID" ]; then
    DEVICE_ID="$(xcrun devicectl list devices 2>/dev/null | awk '/physical/ && /connected/ {print $3; exit}')"
fi

[ -n "$DEVICE_ID" ] || fail "No connected physical iPhone was found. Plug in and unlock the iPhone, then tap Trust if prompted."

say_line "Found iPhone: $DEVICE_ID"

RAW_PAIRING="$PAIRING_DIR/remote_${DEVICE_ID}.plist"
if [ ! -f "$RAW_PAIRING" ]; then
    RAW_PAIRING="$(find "$PAIRING_DIR" -maxdepth 1 -name 'remote_*.plist' -type f -print 2>/dev/null | sort -r | head -n 1 || true)"
fi

[ -n "$RAW_PAIRING" ] && [ -f "$RAW_PAIRING" ] || fail "No Mac pairing record was found. Open ALoco's pairing guide once for this iPhone, then run this setup again."

CONVERTED_PAIRING="$TEMP_DIR/pairingFile.plist"
python3 "$CONVERTER" "$RAW_PAIRING" "$CONVERTED_PAIRING" >/dev/null
chmod 600 "$CONVERTED_PAIRING"

say_line "Prepared the pairing file for ALoco."

if ! xcrun devicectl device info apps --device "$DEVICE_ID" 2>/dev/null | grep -q "$BUNDLE_ID"; then
    fail "ALoco is not installed on this iPhone yet. Install it from Xcode first, open it once, then run this setup again."
fi

xcrun devicectl device copy to \
    --device "$DEVICE_ID" \
    --domain-type appDataContainer \
    --domain-identifier "$BUNDLE_ID" \
    --source "$CONVERTED_PAIRING" \
    --destination Documents/pairingFile.plist >/dev/null

# If the app already created its support folder, put a second copy there too. If not,
# ALoco will migrate the Documents copy on launch.
xcrun devicectl device copy to \
    --device "$DEVICE_ID" \
    --domain-type appDataContainer \
    --domain-identifier "$BUNDLE_ID" \
    --source "$CONVERTED_PAIRING" \
    --destination "Library/Application Support/Pairing/pairingFile.plist" >/dev/null 2>&1 || true

say_line "Added the pairing file to ALoco."

if xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1; then
    say_line "Opened ALoco on the iPhone."
else
    say_line "Pairing file added. If ALoco does not open, trust your developer profile in iPhone Settings, then open ALoco manually."
fi

say_line ""
say_line "Done. Open LocalDevVPN, make sure it is connected, then tap Connect in ALoco."

#!/usr/bin/env bash
# Capture real Play Store screenshots from a connected Android device running
# NetCarve. Falls back gracefully if no device is attached.
#
# Usage:  bash tool/capture_screenshots.sh [serial]
# Output: store_assets/screenshots/device_XX_<name>.png
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/store_assets/screenshots"
PKG="com.acrosscloud.netcarve"
ACTIVITY="$PKG/.MainActivity"
SERIAL="${1:-}"

mkdir -p "$OUT"

ADB=(adb)
if [[ -n "$SERIAL" ]]; then
  ADB=(adb -s "$SERIAL")
fi

if ! "${ADB[@]}" get-state >/dev/null 2>&1; then
  echo "No device connected. Connect the phone with USB debugging on."
  exit 1
fi

echo "Launching NetCarve..."
"${ADB[@]}" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || \
  "${ADB[@]}" shell am start -n "$ACTIVITY" >/dev/null 2>&1
sleep 3

capture() {
  local name="$1"
  "${ADB[@]}" shell screencap -p "/sdcard/nc_$name.png"
  "${ADB[@]}" pull "/sdcard/nc_$name.png" "$OUT/device_$name.png" >/dev/null
  "${ADB[@]}" shell rm "/sdcard/nc_$name.png"
  echo "  saved device_$name.png"
}

# Screen 1: Calculator (default state)
capture "01_calculator"

# Screen 2: VLSM tab  (tap bottom nav ~40% width)
SIZE="$("${ADB[@]}" shell wm size | sed 's/.*: //')"
W="${SIZE%%x*}"
H="${SIZE##*x}"
x() { echo $(( W * $1 / 100 )); }
y() { echo $(( H * $2 / 100 )); }

"${ADB[@]}" shell input tap "$(x 30)" "$(y 96)"
sleep 2
capture "02_vlsm"

"${ADB[@]}" shell input tap "$(x 50)" "$(y 96)"
sleep 2
capture "03_ipv6"

"${ADB[@]}" shell input tap "$(x 70)" "$(y 96)"
sleep 2
capture "04_history"

"${ADB[@]}" shell input tap "$(x 90)" "$(y 96)"
sleep 2
capture "05_about"

echo "Done. Screenshots in $OUT"
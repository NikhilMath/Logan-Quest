#!/bin/bash
# Takes the App Store screenshots and saves them in AppStore/Screenshots.
#
# Builds a Debug copy for the simulator, opens each screen on the biggest "Pro Max" iPhone
# simulator (App Store Connect's 6.9-inch size) and saves a PNG of each. The status bar is left
# alone: it already shows full battery and the real time, which matches the ticking clock on the
# complete and prize screens (and overriding it makes the simulator draw the Dynamic Island).
# Needs no Apple account. Run it from anywhere in the repo:
#
#   Tools/screenshots.sh                       # picks the newest "iPhone NN Pro Max" simulator
#   Tools/screenshots.sh "iPhone 16 Pro Max"   # or name one
#
# Then upload them in App Store Connect → Logan Quests → Distribution → iOS App Version →
# App Previews and Screenshots (drag them in, in order).
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cd "$(dirname "$0")/.."

BUNDLE=com.nikhilmath.loganquest
OUT=AppStore/Screenshots
DD=/tmp/LoganQuest-DD
APP="$DD/Build/Products/Debug-iphonesimulator/LoganQuest.app"

devices=$(xcrun simctl list devices available)
name="${1:-$(grep -oE 'iPhone [0-9]+ Pro Max' <<<"$devices" | sort -V | tail -1)}"
udid=$(grep -F "    $name (" <<<"$devices" | head -1 | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' || true)
if [[ -z "$udid" ]]; then
  echo "No simulator called \"$name\". Pick one from: xcrun simctl list devices available" >&2
  exit 1
fi
echo "Using $name ($udid)"

echo "Building…"
xcodebuild -project LoganQuest.xcodeproj -scheme LoganQuest -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD" build -quiet

booted_here=false
if ! grep -F "$udid" <<<"$devices" | grep -q Booted; then
  xcrun simctl boot "$udid"
  booted_here=true
fi
xcrun simctl bootstatus "$udid" -b >/dev/null
xcrun simctl ui "$udid" appearance light
xcrun simctl status_bar "$udid" clear  # drops any leftover override, which also survives a reboot
xcrun simctl install "$udid" "$APP"

mkdir -p "$OUT"
rm -f "$OUT"/*.png

# shot <file name> <stops found> <seconds to wait> [screen]
# The screen is one of the app's -LQScreen debug screens; none means the home screen.
# Always Easy, so a difficulty picked earlier on this simulator doesn't change the pictures.
shot() {
  local file=$1 found=$2 wait=$3 screen=${4:-}
  xcrun simctl launch --terminate-running-process "$udid" "$BUNDLE" \
    -LQDifficulty easy -LQFound "$found" ${screen:+-LQScreen "$screen"} >/dev/null
  sleep "$wait"
  xcrun simctl io "$udid" screenshot --type=png "$OUT/$file.png" >/dev/null 2>&1
  echo "  $OUT/$file.png"
}

echo "Taking screenshots…"
shot 1-quest-map 3 8 quest     # map tiles take a moment to load
shot 2-question  3 5 stop
shot 3-complete  5 5 complete
shot 4-prize     5 6 prizeOpen # the box opens by itself after a second
shot 5-quests    3 5

xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null || true
if $booted_here; then xcrun simctl shutdown "$udid"; fi

size=$(sips -g pixelWidth -g pixelHeight "$OUT/1-quest-map.png" | awk '/pixel/ {print $2}' | paste -sd x -)
echo "Done: $size pixels each, in $OUT."

#!/bin/zsh
# Archives Logan Quest and uploads it to App Store Connect for TestFlight.
#
#   Tools/release.sh 1.7
#
# The argument is the version: .1 above the newest build in TestFlight, the same
# way Xcode Cloud raises it on every build (ci_scripts/ci_pre_xcodebuild.sh).
# Signs with the Apple account that's signed in to Xcode (Settings → Accounts).
# Xcode picks the next free build number on upload (manageAppVersionAndBuildNumber
# in Config/ExportOptions.plist).
set -euo pipefail
cd "${0:A:h}/.."

version=${1:-}
if [[ ! $version =~ '^[0-9]+\.[0-9]+$' ]]; then
  echo "Usage: Tools/release.sh <version>, like 1.7: .1 above the newest build in TestFlight." >&2
  exit 1
fi

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

# Build outside ~/Documents: iCloud Drive can tag build products with Finder
# metadata that breaks code signing.
work=$(mktemp -d -t loganquest-release)
trap 'rm -rf "$work"' EXIT

echo "Archiving version $version…"
xcodebuild archive -project LoganQuest.xcodeproj -scheme LoganQuest \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$work/LoganQuest.xcarchive" -derivedDataPath "$work/DerivedData" \
  -allowProvisioningUpdates -quiet MARKETING_VERSION="$version"

echo "Uploading to App Store Connect…"
xcodebuild -exportArchive -archivePath "$work/LoganQuest.xcarchive" \
  -exportOptionsPlist Config/ExportOptions.plist -exportPath "$work/export" \
  -allowProvisioningUpdates

echo "Uploaded. It shows up in TestFlight once Apple finishes processing it (usually 5–15 minutes)."

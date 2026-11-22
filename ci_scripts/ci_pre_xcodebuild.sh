#!/bin/sh
# Xcode Cloud runs this before every build. It raises the version by .1 each
# build: Xcode Cloud build 21 is version 1.1, build 22 is 1.2, and so on
# (1.9 is followed by 1.10). Builds up to 20 all shipped as 1.0.
#
# The version comes from Xcode Cloud's build number, so nothing is committed
# and two people pushing never clash over it. A build that gets cancelled still
# uses up its number, so TestFlight can skip a version now and then.
set -eu

first_build=21   # the Xcode Cloud build that became 1.1

if [ -z "${CI_BUILD_NUMBER:-}" ]; then
  echo "CI_BUILD_NUMBER isn't set; leaving the version as it is."
  exit 0
fi

minor=$((CI_BUILD_NUMBER - first_build + 1))
if [ "$minor" -lt 1 ]; then
  echo "error: build $CI_BUILD_NUMBER is older than build $first_build, which became 1.1." >&2
  echo "error: fix first_build in ci_scripts/ci_pre_xcodebuild.sh." >&2
  exit 1
fi
version="1.$minor"

project="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}/LoganQuest.xcodeproj/project.pbxproj"
sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = $version;/" "$project"
echo "Build $CI_BUILD_NUMBER is version $version."

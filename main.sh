#!/usr/bin/env bash
# shellcheck disable=SC2086

# build-xcframework.sh
# Usage (workspace):
#   bash build-xcframework.sh -w YourApp.xcworkspace -s YourFramework -n YourFramework
# Usage (project):
#   bash build-xcframework.sh -p YourProj.xcodeproj -s YourFramework -n YourFramework
# Extra:
#   --config Release|Debug (default Release)
#   --platforms ios,sim (default ios,sim)
#   --out ./XCFramework (default)
#
# Example (curl without cloning):
#   bash <(curl -fsSL https://raw.githubusercontent.com/<you>/<repo>/<tag>/build-xcframework.sh) \
#     -w YourApp.xcworkspace -s YourFramework -n YourFramework

set -euo pipefail
IFS=$'\n\t'

error() { echo "❌ $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

if ! have xcodebuild; then
  error "xcodebuild not found. Install Xcode / CLT."
fi

WORKSPACE=""
PROJECT=""
SCHEME=""
FRAMEWORK_NAME=""
CONFIG="Release"
PLATFORMS="ios,sim"
OUT_DIR="XCFramework"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--workspace) WORKSPACE="$2"; shift 2 ;;
    -p|--project)   PROJECT="$2"; shift 2 ;;
    -s|--scheme)    SCHEME="$2"; shift 2 ;;
    -n|--name)      FRAMEWORK_NAME="$2"; shift 2 ;;
    --config)       CONFIG="$2"; shift 2 ;;
    --platforms)    PLATFORMS="$2"; shift 2 ;;
    --out)          OUT_DIR="$2"; shift 2 ;;
    -h|--help)
      sed -n '1,60p' "$0"; exit 0 ;;
    *) error "Unknown arg: $1" ;;
  esac
done

[[ -z "$SCHEME" ]] && error "Missing --scheme"
[[ -z "$FRAMEWORK_NAME" ]] && FRAMEWORK_NAME="$SCHEME"
if [[ -z "$WORKSPACE" && -z "$PROJECT" ]]; then
  error "Provide either --workspace or --project"
fi

BUILD_DIR="$(pwd)/.build-xcframework"
IOS_ARCHIVE="$BUILD_DIR/iphoneos.xcarchive"
SIM_ARCHIVE="$BUILD_DIR/iphonesimulator.xcarchive"

echo "🔨 Cleaning..."
rm -rf "$BUILD_DIR" "$OUT_DIR"
mkdir -p "$BUILD_DIR" "$OUT_DIR"

COMMON_FLAGS=( -scheme "$SCHEME" CONFIGURATION_BUILD_DIR="$BUILD_DIR/tmp" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES )
if [[ -n "$WORKSPACE" ]]; then
  COMMON_OPEN=( -workspace "$WORKSPACE" )
else
  COMMON_OPEN=( -project "$PROJECT" )
fi

# Parse platforms
DO_IOS=false; DO_SIM=false
IFS=',' read -r -a PLAT_ARR <<< "$PLATFORMS"
for p in "${PLAT_ARR[@]}"; do
  case "$(echo "$p" | tr '[:upper:]' '[:lower:]')" in
    ios) DO_IOS=true ;;
    sim|simulator|iossimulator|iphonesimulator) DO_SIM=true ;;
    *) error "Unsupported platform: $p (use ios, sim)" ;;
  esac
done

build_archive() {
  local sdk="$1"
  local path="$2"
  echo "🏗️  Archiving for $sdk -> $path"
  xcodebuild archive \
    "${COMMON_OPEN[@]}" \
    "${COMMON_FLAGS[@]}" \
    -configuration "$CONFIG" \
    -sdk "$sdk" \
    -archivePath "$path" \
    # Let the consuming app sign; ad-hoc here is unnecessary for XCFrameworks
    CODE_SIGNING_ALLOWED=NO \
    | xcbeautify || true
}

# xcbeautify is optional; fall back to raw logs
if ! have xcbeautify; then
  xcbeautify() { cat; }
fi

$DO_IOS && build_archive iphoneos "$IOS_ARCHIVE"
$DO_SIM && build_archive iphonesimulator "$SIM_ARCHIVE"

# Find built .framework(s) robustly inside archives (handles SPM/CocoaPods/Manual)
find_framework() {
  local archive="$1"
  local name="$2"
  # Prioritize Products/Library/Frameworks, then search all
  if [[ -d "$archive/Products/Library/Frameworks" ]]; then
    local candidate="$archive/Products/Library/Frameworks/$name.framework"
    [[ -d "$candidate" ]] && { echo "$candidate"; return 0; }
  fi
  # Fallback search
  local found
  found="$(/usr/bin/find "$archive" -type d -name "$name.framework" -maxdepth 6 | head -n 1 || true)"
  [[ -n "${found:-}" ]] && { echo "$found"; return 0; }
  return 1
}

INPUTS=()
$DO_IOS && {
  FW=$(find_framework "$IOS_ARCHIVE" "$FRAMEWORK_NAME") || error "Framework $FRAMEWORK_NAME not found in $IOS_ARCHIVE"
  INPUTS+=( -framework "$FW" )
}
$DO_SIM && {
  FW=$(find_framework "$SIM_ARCHIVE" "$FRAMEWORK_NAME") || error "Framework $FRAMEWORK_NAME not found in $SIM_ARCHIVE"
  INPUTS+=( -framework "$FW" )
}

OUT_PATH="$OUT_DIR/$FRAMEWORK_NAME.xcframework"
echo "📦 Creating $OUT_PATH"
xcodebuild -create-xcframework "${INPUTS[@]}" -output "$OUT_PATH"

# Optional dSYM + BCSymbolMap collection (ignored if missing)
collect_symbols() {
  local archive="$1"
  local dest="$2"
  /usr/bin/find "$archive" -name "*.dSYM" -maxdepth 6 -exec cp -R {} "$dest" \; || true
  /usr/bin/find "$archive" -name "*.bcsymbolmap" -maxdepth 6 -exec cp {} "$dest" \; || true
}
mkdir -p "$OUT_DIR/Symbols"
$DO_IOS && collect_symbols "$IOS_ARCHIVE" "$OUT_DIR/Symbols"
$DO_SIM && collect_symbols "$SIM_ARCHIVE" "$OUT_DIR/Symbols"

echo "✅ Done:"
echo " - XCFramework: $OUT_PATH"
[[ -d "$OUT_DIR/Symbols" ]] && echo " - Symbols:    $OUT_DIR/Symbols"
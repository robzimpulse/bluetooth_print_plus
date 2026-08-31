#!/bin/bash
#
# build_xcframework.sh — regenerate ios/Frameworks/GSDK.xcframework
#
# Produces an xcframework with two slices:
#
#   ios-arm64                     the real GSDK, untouched (device builds)
#   ios-arm64_x86_64-simulator    the no-op stub from GSDKStubs.m
#
# Run from this directory with no arguments. By default the real device library
# is taken from the existing xcframework, so the script is idempotent:
#
#   ./build_xcframework.sh
#
# The first time (when there is no xcframework yet, only the original fat
# GSDK.framework) point it at that framework instead:
#
#   ./build_xcframework.sh ../../ios/Frameworks/GSDK.framework
#
# The original fat binary is not kept in the working tree — it is preserved in
# git history at commit ec5d39b as ios/Frameworks/GSDK.framework, with the
# provenance recorded in README.md.
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="$ROOT/ios/Frameworks/GSDK.xcframework"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# iOS 12.0 matches what Flutter assigns to plugin pods; the app's own minimum is
# higher, and a lower stub minimum never constrains it.
DEPLOYMENT_TARGET=12.0

# --- locate the real device library -----------------------------------------
SOURCE_FRAMEWORK="${1:-$OUT/ios-arm64/GSDK.framework}"
if [ ! -d "$SOURCE_FRAMEWORK" ]; then
  echo "error: no source framework at $SOURCE_FRAMEWORK" >&2
  echo "       pass the original fat GSDK.framework as the first argument" >&2
  exit 1
fi
SOURCE_BINARY="$SOURCE_FRAMEWORK/GSDK"
HEADERS="$SOURCE_FRAMEWORK/Headers"
echo "==> source: $SOURCE_FRAMEWORK"
echo "    slices: $(lipo -archs "$SOURCE_BINARY")"

# --- device slice: real code, arm64 only ------------------------------------
# i386/armv7 are dropped deliberately: they are 32-bit, and every iOS release
# this plugin supports is 64-bit only.
DEVICE_FW="$WORK/device/GSDK.framework"
mkdir -p "$DEVICE_FW"
lipo "$SOURCE_BINARY" -thin arm64 -output "$DEVICE_FW/GSDK"
cp -R "$HEADERS" "$DEVICE_FW/Headers"
cp "$SOURCE_FRAMEWORK/Info.plist" "$DEVICE_FW/Info.plist"
echo "==> device slice: $(lipo -archs "$DEVICE_FW/GSDK")"

# --- simulator slice: stub ---------------------------------------------------
SIM_FW="$WORK/simulator/GSDK.framework"
mkdir -p "$SIM_FW"
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
for ARCH in arm64 x86_64; do
  xcrun clang -c "$HERE/GSDKStubs.m" \
    -target "${ARCH}-apple-ios${DEPLOYMENT_TARGET}-simulator" \
    -isysroot "$SDK" \
    -I "$HEADERS" \
    -fobjc-arc -fmodules -Os -Wall \
    -o "$WORK/stub_${ARCH}.o"
  xcrun libtool -static -o "$WORK/libGSDK_${ARCH}.a" "$WORK/stub_${ARCH}.o"
done
lipo -create "$WORK/libGSDK_arm64.a" "$WORK/libGSDK_x86_64.a" -output "$SIM_FW/GSDK"
cp -R "$HEADERS" "$SIM_FW/Headers"
cp "$SOURCE_FRAMEWORK/Info.plist" "$SIM_FW/Info.plist"
echo "==> simulator slice: $(lipo -archs "$SIM_FW/GSDK")"

# --- assemble ----------------------------------------------------------------
rm -rf "$OUT"
xcodebuild -create-xcframework \
  -framework "$DEVICE_FW" \
  -framework "$SIM_FW" \
  -output "$OUT" >/dev/null

echo "==> wrote $OUT"
find "$OUT" -name GSDK -type f | while read -r bin; do
  echo "    $(basename "$(dirname "$(dirname "$bin")")"): $(lipo -archs "$bin")"
done

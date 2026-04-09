#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_DIR="$ROOT_DIR/release"
APP_ID="rtal-dynamic-distortion"
PACKAGE_ROOT="$RELEASE_DIR/rtal-dynamic-distortion-1.0.0-linux"
BUILD_LV2="${BUILD_LV2:-1}"
BUILD_STANDALONE="${BUILD_STANDALONE:-1}"
BUILD_VST2="${BUILD_VST2:-1}"

mkdir -p "$RELEASE_DIR"
rm -rf "$PACKAGE_ROOT"
mkdir -p "$PACKAGE_ROOT"

packaged_any=0

if [ "$BUILD_LV2" = "1" ]; then
    if [ ! -d "$DIST_DIR/lv2/$APP_ID.lv2" ]; then
        echo "[$APP_ID] Missing LV2 artifact in $DIST_DIR. Run cmake --build build first." >&2
        exit 1
    fi
    mkdir -p "$PACKAGE_ROOT/lv2"
    cp -R "$DIST_DIR/lv2/$APP_ID.lv2" "$PACKAGE_ROOT/lv2/$APP_ID.lv2"
    packaged_any=1
fi

if [ "$BUILD_VST2" = "1" ]; then
    if [ ! -f "$DIST_DIR/vst2/$APP_ID.so" ]; then
        echo "[$APP_ID] Missing VST2 artifact in $DIST_DIR. Run cmake --build build first." >&2
        exit 1
    fi
    mkdir -p "$PACKAGE_ROOT/vst2"
    cp "$DIST_DIR/vst2/$APP_ID.so" "$PACKAGE_ROOT/vst2/$APP_ID.so"
    packaged_any=1
fi

if [ "$BUILD_STANDALONE" = "1" ]; then
    if [ ! -f "$DIST_DIR/standalone/$APP_ID" ]; then
        echo "[$APP_ID] Missing standalone artifact in $DIST_DIR. Run cmake --build build first." >&2
        exit 1
    fi
    mkdir -p "$PACKAGE_ROOT/bin"
    cp "$DIST_DIR/standalone/$APP_ID" "$PACKAGE_ROOT/bin/$APP_ID"
    chmod 755 "$PACKAGE_ROOT/bin/$APP_ID"
    packaged_any=1
fi

if [ "$packaged_any" -ne 1 ]; then
    echo "[$APP_ID] No targets are enabled for packaging." >&2
    exit 1
fi

cp "$ROOT_DIR/README.md" "$PACKAGE_ROOT/README.md"
cp "$ROOT_DIR/LICENSE" "$PACKAGE_ROOT/LICENSE"
cp "$ROOT_DIR/BINARY_LICENSE_NOTICE.txt" "$PACKAGE_ROOT/BINARY_LICENSE_NOTICE.txt"
cp "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$PACKAGE_ROOT/THIRD_PARTY_NOTICES.md"
cp "$ROOT_DIR/scripts/install.sh" "$PACKAGE_ROOT/install.sh"
chmod 755 "$PACKAGE_ROOT/install.sh"

(
    cd "$RELEASE_DIR"
    tar -czf "rtal-dynamic-distortion-1.0.0-linux.tar.gz" "rtal-dynamic-distortion-1.0.0-linux"
)

echo "[$APP_ID] Packaged release at $RELEASE_DIR/rtal-dynamic-distortion-1.0.0-linux.tar.gz"

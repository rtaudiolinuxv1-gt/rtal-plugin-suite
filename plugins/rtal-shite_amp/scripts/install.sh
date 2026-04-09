#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_ID="rtal-shite_amp"
BUILD_LV2="${BUILD_LV2:-1}"
BUILD_STANDALONE="${BUILD_STANDALONE:-1}"
BUILD_VST2="${BUILD_VST2:-1}"

TARGET_SCOPE="${1:-user}"
INSTALL_LV2_DIR="${LV2_INSTALL_DIR:-$HOME/.lv2}"
INSTALL_VST2_DIR="${VST2_INSTALL_DIR:-$HOME/.vst}"
INSTALL_BIN_DIR="${BIN_INSTALL_DIR:-$HOME/.local/bin}"

if [ "$TARGET_SCOPE" != "user" ]; then
    echo "Usage: $0 [user]" >&2
    exit 1
fi

installed_any=0

if [ "$BUILD_LV2" = "1" ]; then
    if [ ! -d "$DIST_DIR/lv2/$APP_ID.lv2" ]; then
        echo "[$APP_ID] Missing LV2 artifact in $DIST_DIR. Run cmake --build build first." >&2
        exit 1
    fi
    mkdir -p "$INSTALL_LV2_DIR"
    rm -rf "$INSTALL_LV2_DIR/$APP_ID.lv2"
    cp -R "$DIST_DIR/lv2/$APP_ID.lv2" "$INSTALL_LV2_DIR/$APP_ID.lv2"
    echo "[$APP_ID] Installed LV2 to $INSTALL_LV2_DIR/$APP_ID.lv2"
    installed_any=1
fi

if [ "$BUILD_VST2" = "1" ]; then
    if [ ! -f "$DIST_DIR/vst2/$APP_ID.so" ]; then
        echo "[$APP_ID] Missing VST2 artifact in $DIST_DIR. Run cmake --build build first." >&2
        exit 1
    fi
    mkdir -p "$INSTALL_VST2_DIR"
    cp "$DIST_DIR/vst2/$APP_ID.so" "$INSTALL_VST2_DIR/$APP_ID.so"
    echo "[$APP_ID] Installed VST2 to $INSTALL_VST2_DIR/$APP_ID.so"
    installed_any=1
fi

if [ "$BUILD_STANDALONE" = "1" ]; then
    if [ ! -f "$DIST_DIR/standalone/$APP_ID" ]; then
        echo "[$APP_ID] Missing standalone artifact in $DIST_DIR. Run cmake --build build first." >&2
        exit 1
    fi
    mkdir -p "$INSTALL_BIN_DIR"
    cp "$DIST_DIR/standalone/$APP_ID" "$INSTALL_BIN_DIR/$APP_ID"
    chmod 755 "$INSTALL_BIN_DIR/$APP_ID"
    echo "[$APP_ID] Installed standalone to $INSTALL_BIN_DIR/$APP_ID"
    installed_any=1
fi

if [ "$installed_any" -ne 1 ]; then
    echo "[$APP_ID] No targets are enabled for installation." >&2
    exit 1
fi

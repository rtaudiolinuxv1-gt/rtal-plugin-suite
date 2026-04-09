#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
BUILD_ROOT="$RELEASE_DIR/rtal-plugin-suite-1.0.0-${RTAL_BUILD_MODE,,}"
GOOD_PLUGINS="${GOOD_PLUGINS:-}"
PRERELEASE_PLUGINS="${PRERELEASE_PLUGINS:-}"
BUILD_LV2="${BUILD_LV2:-1}"
BUILD_STANDALONE="${BUILD_STANDALONE:-1}"
BUILD_VST2="${BUILD_VST2:-1}"

copy_plugin() {
    local plugin_id="$1"
    local lane="$2"
    local plugin_root="$ROOT_DIR/plugins/$plugin_id"
    local dist_dir="$plugin_root/dist"
    local target_root="$BUILD_ROOT/$lane/$plugin_id"

    mkdir -p "$target_root"

    if [ "$BUILD_LV2" = "1" ]; then
        if [ ! -d "$dist_dir/lv2/$plugin_id.lv2" ]; then
            echo "[$plugin_id] Missing LV2 artifact in $dist_dir" >&2
            exit 1
        fi
        mkdir -p "$target_root/lv2"
        cp -R "$dist_dir/lv2/$plugin_id.lv2" "$target_root/lv2/$plugin_id.lv2"
    fi

    if [ "$BUILD_VST2" = "1" ]; then
        if [ ! -f "$dist_dir/vst2/$plugin_id.so" ]; then
            echo "[$plugin_id] Missing VST2 artifact in $dist_dir" >&2
            exit 1
        fi
        mkdir -p "$target_root/vst2"
        cp "$dist_dir/vst2/$plugin_id.so" "$target_root/vst2/$plugin_id.so"
    fi

    if [ "$BUILD_STANDALONE" = "1" ]; then
        if [ ! -f "$dist_dir/standalone/$plugin_id" ]; then
            echo "[$plugin_id] Missing standalone artifact in $dist_dir" >&2
            exit 1
        fi
        mkdir -p "$target_root/bin"
        cp "$dist_dir/standalone/$plugin_id" "$target_root/bin/$plugin_id"
        chmod 755 "$target_root/bin/$plugin_id"
    fi

    cp "$plugin_root/README.md" "$target_root/README.md"
    cp "$plugin_root/LICENSE" "$target_root/LICENSE"
    cp "$plugin_root/BINARY_LICENSE_NOTICE.txt" "$target_root/BINARY_LICENSE_NOTICE.txt"
    cp "$plugin_root/THIRD_PARTY_NOTICES.md" "$target_root/THIRD_PARTY_NOTICES.md"
}

mkdir -p "$RELEASE_DIR"
rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT"

manifest="$BUILD_ROOT/manifest.txt"
{
    echo "RTAL Plugin Suite"
    echo "Build mode: ${RTAL_BUILD_MODE:-RELEASE}"
    echo "Portable x86_64: ${PORTABLE_X86_64:-0}"
    echo "LV2: $BUILD_LV2"
    echo "Standalone: $BUILD_STANDALONE"
    echo "VST2: $BUILD_VST2"
    echo
    echo "[good]"
    if [ -n "$GOOD_PLUGINS" ]; then
        IFS=',' read -r -a good_items <<< "$GOOD_PLUGINS"
        for plugin in "${good_items[@]}"; do
            [ -n "$plugin" ] && echo "$plugin"
        done
    fi
    echo
    echo "[prerelease]"
    if [ -n "$PRERELEASE_PLUGINS" ]; then
        IFS=',' read -r -a pre_items <<< "$PRERELEASE_PLUGINS"
        for plugin in "${pre_items[@]}"; do
            [ -n "$plugin" ] && echo "$plugin"
        done
    fi
} > "$manifest"

packaged_any=0

if [ -n "$GOOD_PLUGINS" ]; then
    IFS=',' read -r -a good_items <<< "$GOOD_PLUGINS"
    for plugin in "${good_items[@]}"; do
        [ -z "$plugin" ] && continue
        copy_plugin "$plugin" "good"
        packaged_any=1
    done
fi

if [ -n "$PRERELEASE_PLUGINS" ]; then
    IFS=',' read -r -a pre_items <<< "$PRERELEASE_PLUGINS"
    for plugin in "${pre_items[@]}"; do
        [ -z "$plugin" ] && continue
        copy_plugin "$plugin" "prerelease"
        packaged_any=1
    done
fi

if [ "$packaged_any" -ne 1 ]; then
    echo "[rtal-plugin-suite] No plugins are enabled for packaging." >&2
    exit 1
fi

tarball="$RELEASE_DIR/rtal-plugin-suite-1.0.0-${RTAL_BUILD_MODE,,}.tar.gz"
(
    cd "$RELEASE_DIR"
    tar -czf "$(basename "$tarball")" "$(basename "$BUILD_ROOT")"
)

echo "[rtal-plugin-suite] Packaged release at $tarball"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DSP_FILE="$ROOT_DIR/src/rtal_dynamic_distortion.dsp"
DIST_DIR="$ROOT_DIR/dist"
SDK_DIR="${SDK:-$ROOT_DIR/../vstsdk2.4}"
VERSION="1.0.0"
APP_ID="rtal-dynamic-distortion"
STEM="rtal_dynamic_distortion"
LICENSE_AUDITOR="$ROOT_DIR/scripts/license_audit.sh"
BUILD_LV2="${BUILD_LV2:-1}"
BUILD_STANDALONE="${BUILD_STANDALONE:-1}"
BUILD_VST2="${BUILD_VST2:-1}"
EXPORT_CFLAGS="${CFLAGS:-}"
EXPORT_CXXFLAGS="${CXXFLAGS:-${CFLAGS:-}}"
EXPORT_LDFLAGS="${LDFLAGS:-}"

export FAUSTINC="${FAUSTINC:-/usr/include/faust}"
export FAUSTLIB="${FAUSTLIB:-/usr/share/faust}"

export CFLAGS="$(echo "$EXPORT_CFLAGS" | xargs)"
export CXXFLAGS="$(echo "$EXPORT_CXXFLAGS" | xargs)"
export LDFLAGS="$(echo "$EXPORT_LDFLAGS" | xargs)"

mkdir -p "$DIST_DIR/meta" "$DIST_DIR/lv2" "$DIST_DIR/standalone" "$DIST_DIR/vst2"

echo "[$APP_ID] Generating Faust metadata"
faust -json -o "$DIST_DIR/meta/$APP_ID.json" "$DSP_FILE"
"$LICENSE_AUDITOR" "$DIST_DIR/meta/$APP_ID.json"

rename_output() {
    local old_path="$1"
    local new_path="$2"
    if [ -e "$old_path" ]; then
        mv "$old_path" "$new_path"
    fi
}

ensure_enabled() {
    local label="$1"
    local enabled="$2"
    if [ "$enabled" != "1" ]; then
        echo "[$APP_ID] $label export is disabled by the current CMake configuration" >&2
        exit 1
    fi
}

build_lv2() {
    ensure_enabled "LV2" "$BUILD_LV2"
    rm -rf "$DIST_DIR/lv2/$STEM" "$DIST_DIR/lv2/${STEM}.lv2" "$DIST_DIR/lv2/${APP_ID}.lv2" "$DIST_DIR/lv2/${APP_ID}"
    echo "[$APP_ID] Exporting LV2"
    (
        cd "$DIST_DIR/lv2"
        cp "$DSP_FILE" "${STEM}.dsp"
        faust2lv2 -keep "${STEM}.dsp"
        rename_output "${STEM}.lv2/${STEM}.so" "${STEM}.lv2/${APP_ID}.so"
        rename_output "${STEM}.lv2/${STEM}.ttl" "${STEM}.lv2/${APP_ID}.ttl"
        sed -i "s/${STEM}/${APP_ID}/g" "${STEM}.lv2/manifest.ttl" "${STEM}.lv2/${APP_ID}.ttl"
        mv "${STEM}.lv2" "${APP_ID}.lv2"
        rm -rf "${STEM}"
    )
}

build_standalone() {
    ensure_enabled "standalone" "$BUILD_STANDALONE"
    rm -rf "$DIST_DIR/standalone/$STEM"            "$DIST_DIR/standalone/${STEM}.dsp"            "$DIST_DIR/standalone/${STEM}.cpp"            "$DIST_DIR/standalone/${APP_ID}"
    echo "[$APP_ID] Exporting JACK standalone"
    (
        cd "$DIST_DIR/standalone"
        cp "$DSP_FILE" "${STEM}.dsp"
        faust2jack "${STEM}.dsp"
        mv "$STEM" "${APP_ID}"
        chmod 755 "${APP_ID}"
        rm -f "${STEM}.dsp" "${STEM}.cpp"
    )
}

build_vst2() {
    ensure_enabled "VST2" "$BUILD_VST2"
    if [ ! -d "$SDK_DIR" ]; then
        echo "[$APP_ID] Skipping VST2: SDK not found at $SDK_DIR" >&2
        return 0
    fi

    rm -rf "$DIST_DIR/vst2/$STEM" "$DIST_DIR/vst2/${STEM}.so" "$DIST_DIR/vst2/${APP_ID}.so" "$DIST_DIR/vst2/$APP_ID"
    echo "[$APP_ID] Exporting VST2 with SDK at $SDK_DIR"
    (
        cd "$DIST_DIR/vst2"
        cp "$DSP_FILE" "${STEM}.dsp"
        export SDK="$SDK_DIR"
        export SDKSRC="$SDK_DIR/public.sdk/source/vst2.x"
        faust2faustvst -keep "${STEM}.dsp"
        rename_output "${STEM}.so" "${APP_ID}.so"
        if [ -d "${STEM}" ]; then
            mv "${STEM}" "${APP_ID}"
        fi
    )
}

case "${1:-all}" in
    all)
        if [ "$BUILD_LV2" = "1" ]; then build_lv2; fi
        if [ "$BUILD_STANDALONE" = "1" ]; then build_standalone; fi
        if [ "$BUILD_VST2" = "1" ]; then build_vst2; fi
        ;;
    meta)
        ;;
    lv2)
        build_lv2
        ;;
    standalone)
        build_standalone
        ;;
    vst2)
        build_vst2
        ;;
    version)
        echo "$VERSION"
        ;;
    *)
        echo "Usage: $0 [all|meta|lv2|standalone|vst2|version]" >&2
        exit 1
        ;;
esac

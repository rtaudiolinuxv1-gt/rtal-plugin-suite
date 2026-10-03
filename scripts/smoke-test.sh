#!/usr/bin/env bash
# Offline smoke test for RTAL Faust plugins.
#
#   scripts/smoke-test.sh                    # every plugin under plugins/
#   scripts/smoke-test.sh rtal-tape-ghost    # selected plugins
#   WAV_DIR=renders scripts/smoke-test.sh    # also write default/preset renders
#
# For each plugin: compiles the DSP, runs the license audit on the Faust
# metadata, builds the offline harness and renders a synthetic guitar
# performance through every preset, the parameter corners and random states.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/build-smoke}"
HARNESS="$ROOT_DIR/scripts/dsp_smoke_harness.cpp"
CXX="${CXX:-g++}"
WAV_DIR="${WAV_DIR:-}"

mkdir -p "$WORK_DIR"
if [ -n "$WAV_DIR" ]; then
    mkdir -p "$WAV_DIR"
    WAV_DIR="$(cd "$WAV_DIR" && pwd)"
fi

if [ "$#" -gt 0 ]; then
    plugins=("$@")
else
    plugins=()
    for dir in "$ROOT_DIR"/plugins/*/; do
        plugins+=("$(basename "$dir")")
    done
fi

failed=()
for plugin in "${plugins[@]}"; do
    plugin="$(basename "$plugin")"
    dsp_file="$(ls "$ROOT_DIR/plugins/$plugin/src/"*.dsp 2>/dev/null | head -n 1 || true)"
    if [ -z "$dsp_file" ]; then
        echo "[$plugin] no DSP source found" >&2
        failed+=("$plugin")
        continue
    fi
    echo "[$plugin]"
    out="$WORK_DIR/$plugin"
    mkdir -p "$out"
    if ! faust -json -o "$out/meta.cpp" "$dsp_file" > "$out/faust.log" 2>&1; then
        cat "$out/faust.log" >&2
        failed+=("$plugin")
        continue
    fi
    if ! bash "$ROOT_DIR/plugins/$plugin/scripts/license_audit.sh" "$out/meta.cpp" 2>/dev/null | sed 's/^/  /'; then
        failed+=("$plugin")
        continue
    fi
    if ! faust -a "$HARNESS" -o "$out/harness.cpp" "$dsp_file" > "$out/faust.log" 2>&1 \
        || ! "$CXX" -O2 -std=c++17 -I/usr/include -I"$(dirname "$dsp_file")" "$out/harness.cpp" -o "$out/harness" > "$out/cxx.log" 2>&1; then
        cat "$out/faust.log" "$out/cxx.log" >&2 2>/dev/null || true
        failed+=("$plugin")
        continue
    fi
    args=()
    if [ -n "$WAV_DIR" ]; then
        args=(--wav "$WAV_DIR/$plugin")
    fi
    if ! "$out/harness" "${args[@]}"; then
        failed+=("$plugin")
    fi
done

if [ "${#failed[@]}" -gt 0 ]; then
    echo "Smoke test failed for: ${failed[*]}" >&2
    exit 1
fi
echo "Smoke test passed for ${#plugins[@]} plugin(s)"

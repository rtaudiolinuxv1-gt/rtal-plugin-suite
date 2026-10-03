#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <faust-metadata-json>" >&2
    exit 1
fi

METADATA_FILE="$1"

if [ ! -f "$METADATA_FILE" ]; then
    echo "[license-audit] Metadata file not found: $METADATA_FILE" >&2
    exit 1
fi

if grep -Eqi 'license[^"]*"[^"]*(AGPL|GPL)' "$METADATA_FILE"; then
    echo "[license-audit] Rejected: GPL/AGPL-tagged Faust dependency detected in $METADATA_FILE" >&2
    grep -Ein 'license[^"]*"[^"]*(AGPL|GPL)' "$METADATA_FILE" >&2 || true
    exit 1
fi

if grep -Eqi 'license[^"]*"[^"]*LGPL(?! with exception)' "$METADATA_FILE"; then
    echo "[license-audit] Rejected: plain LGPL-tagged Faust dependency detected in $METADATA_FILE" >&2
    grep -Ein 'license[^"]*"[^"]*LGPL(?! with exception)' "$METADATA_FILE" >&2 || true
    exit 1
fi

echo "[license-audit] Passed: no GPL/AGPL or plain LGPL Faust dependencies detected"

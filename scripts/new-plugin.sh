#!/usr/bin/env bash
# Scaffold a new RTAL plugin from the rtal-crystal-pluck build/packaging template.
#
#   scripts/new-plugin.sh rtal-tape-ghost
#
# Creates plugins/<app-id>/ with CMakeLists.txt, scripts/, LICENSE and notices,
# renamed for the new plugin. The DSP source (src/<stem>.dsp) and README.md are
# left for the author to write.
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <app-id, e.g. rtal-tape-ghost>" >&2
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/plugins/rtal-crystal-pluck"
APP_ID="$1"
STEM="$(echo "$APP_ID" | tr '[:upper:]-' '[:lower:]_')"
DEST_DIR="$ROOT_DIR/plugins/$APP_ID"

if [ -e "$DEST_DIR" ]; then
    echo "$DEST_DIR already exists" >&2
    exit 1
fi

mkdir -p "$DEST_DIR/scripts" "$DEST_DIR/src"
for file in CMakeLists.txt LICENSE THIRD_PARTY_NOTICES.md BINARY_LICENSE_NOTICE.txt \
    scripts/export.sh scripts/install.sh scripts/package.sh scripts/license_audit.sh; do
    sed -e "s/rtal-crystal-pluck/$APP_ID/g" -e "s/rtal_crystal_pluck/$STEM/g" \
        "$TEMPLATE_DIR/$file" > "$DEST_DIR/$file"
done
chmod 755 "$DEST_DIR"/scripts/*.sh

echo "Scaffolded $DEST_DIR (write src/$STEM.dsp and README.md next)"

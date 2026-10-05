#!/usr/bin/env bash

set -euo pipefail

ARTIFACT_DIR="${1:?Missing artifact directory}"
OUTPUT="${2:?Missing output file}"

RPM="$(find \
    "$ARTIFACT_DIR/rpm" \
    -type f \
    -name "*.rpm" \
    | head -1)"

if [ -z "$RPM" ]; then
    echo "ERROR: RPM not found"
    exit 1
fi

cd "$ARTIFACT_DIR"

tar \
    --sort=name \
    --mtime='UTC 1970-01-01' \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    -czf "$OUTPUT" \
    rpm \
    evidence

echo
echo "Evidence bundle:"
echo "$OUTPUT"

echo
echo "Evidence bundle SHA256:"

sha256sum "$OUTPUT"
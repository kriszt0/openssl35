#!/usr/bin/env bash

set -euo pipefail

RPM="${1:?Missing RPM}"
OUTPUT_DIR="${2:?Missing output directory}"

mkdir -p "$OUTPUT_DIR"

if ! command -v syft >/dev/null 2>&1; then
    echo "ERROR: syft is not installed."
    exit 1
fi

syft \
    "file:${RPM}" \
    -o cyclonedx-json \
    > "$OUTPUT_DIR/SBOM.cyclonedx.json"

echo "SBOM created:"
echo "$OUTPUT_DIR/SBOM.cyclonedx.json"
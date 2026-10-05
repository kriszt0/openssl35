#!/usr/bin/env bash

set -euo pipefail

RPM_DIR="${1:?Missing RPM directory}"
EVIDENCE_DIR="${2:?Missing evidence directory}"

mkdir -p "$EVIDENCE_DIR"

RPM="$(find \
    "$RPM_DIR" \
    -type f \
    -name "*.rpm" \
    | head -1)"

if [ -z "$RPM" ]; then
    echo "ERROR: RPM not found"
    exit 1
fi

RPM_NAME="$(basename "$RPM")"

SHA1="$(sha1sum "$RPM" | awk '{print $1}')"
SHA256="$(sha256sum "$RPM" | awk '{print $1}')"

echo "${SHA1}  ${RPM_NAME}" \
    > "$EVIDENCE_DIR/SHA1SUM"

echo "${SHA256}  ${RPM_NAME}" \
    > "$EVIDENCE_DIR/SHA256SUM"

echo
echo "SHA1:"
cat "$EVIDENCE_DIR/SHA1SUM"

echo
echo "SHA256:"
cat "$EVIDENCE_DIR/SHA256SUM"
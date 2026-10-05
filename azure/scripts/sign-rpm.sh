#!/usr/bin/env bash

set -euo pipefail

RPM="${1:?Missing RPM}"
KEY_ID="${2:?Missing GPG key ID}"

if [ -z "${GNUPGHOME:-}" ]; then
    echo "ERROR: GNUPGHOME is not set"
    exit 1
fi

export GNUPGHOME

chmod 700 "$GNUPGHOME"

echo "=========================================="
echo "RPM SIGNING"
echo "=========================================="

echo
echo "RPM:"
echo "$RPM"

echo
echo "Signing key:"
gpg \
    --batch \
    --list-keys \
    "$KEY_ID"

echo
echo "Signing RPM..."

rpmsign \
    --define "_signature gpg" \
    --define "_gpg_name $KEY_ID" \
    --addsign \
    "$RPM"

echo
echo "RPM signing completed."
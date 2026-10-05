#!/usr/bin/env bash

set -euo pipefail

OPENSSL="/opt/openssl35/bin/openssl"

echo "=========================================="
echo "OPENSSL FUNCTIONAL TEST"
echo "=========================================="

if [ ! -x "$OPENSSL" ]; then
    echo "ERROR: OpenSSL executable not found:"
    echo "$OPENSSL"
    exit 1
fi

echo
echo "OpenSSL version:"
"$OPENSSL" version -a

VERSION="$("$OPENSSL" version)"

if [[ "$VERSION" != OpenSSL\ 3.5.* ]]; then
    echo "ERROR: Unexpected OpenSSL version:"
    echo "$VERSION"
    exit 1
fi

TMPDIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMPDIR"
}

trap cleanup EXIT

echo
echo "Generating test certificate..."

"$OPENSSL" req \
    -x509 \
    -newkey rsa:2048 \
    -keyout "$TMPDIR/key.pem" \
    -out "$TMPDIR/cert.pem" \
    -nodes \
    -days 1 \
    -subj "/CN=openssl35-test" \
    >/dev/null 2>&1

echo
echo "Inspecting certificate..."

"$OPENSSL" x509 \
    -in "$TMPDIR/cert.pem" \
    -noout \
    -subject \
    -issuer \
    -dates

echo
echo "OpenSSL functional tests successful."
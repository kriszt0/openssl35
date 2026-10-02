#!/usr/bin/env bash
# Clean-room ellenőrzés tiszta, nem előkészített RHEL 7 userlanden (ubi7), hálózat nélkül.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG="${PKG:-openssl35}"
set -a; . "$ROOT/packaging/pkgs/$PKG.env"; set +a

VERIFY_IMAGE="${VERIFY_IMAGE:-registry.access.redhat.com/ubi7/ubi}"
OUT="$ROOT/out"
PUB="$ROOT/packaging/RPM-GPG-KEY-$NAME.pub"

V="$(mktemp -d)"; trap 'rm -rf "$V"' EXIT
cp "$OUT"/*.rpm "$OUT/SHA256SUMS" "$ROOT/packaging/bin/verify-inside.sh" "$V/"
export EXPECT_SIGNED=0
if [[ -f "$PUB" ]]; then cp "$PUB" "$V/RPM-GPG-KEY.pub"; EXPECT_SIGNED=1; fi
chmod -R a+rX "$V"

podman run --rm --network=none --security-opt=no-new-privileges \
    -v "$V:/rpms:ro,Z" \
    -e NAME -e VERSION -e PREFIX -e EXPECT_SIGNED \
    "$VERIFY_IMAGE" bash /rpms/verify-inside.sh

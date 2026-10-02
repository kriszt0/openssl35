#!/usr/bin/env bash
# Egy parancs: forrás ellenőrzés -> offline build konténerben -> clean-room teszt -> out/*.rpm
# Követelmény: podman, internet a builder image első felépítéséhez (yum.oracle.com) és az image-ek letöltéséhez.
# Opcionális aláírás:  RPM_SIGNING_KEY_FILE=titkos.asc RPM_PUBKEY_FILE=publikus.asc ./build.sh
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./pkg.env; set +a

command -v podman >/dev/null || { echo "HIBA: podman nincs telepítve" >&2; exit 1; }

echo "== 1/4 forrás ellenőrzése"
echo "$SHA256  $TARBALL" | sha256sum -c -

BASE_IMAGE="${BUILD_BASE_IMAGE:-docker.io/library/oraclelinux:7}"
VERIFY_IMAGE="${VERIFY_IMAGE:-registry.access.redhat.com/ubi7/ubi}"
TAG="localhost/rpm-builder-el7:$(sha256sum Containerfile.builder | cut -c1-12)"
OUT="$PWD/out"

echo "== 2/4 builder image"
if ! podman image exists "$TAG"; then
    CTX="$(mktemp -d)"
    podman build --build-arg "BASE_IMAGE=$BASE_IMAGE" -f Containerfile.builder -t "$TAG" "$CTX"
    rm -rf "$CTX"
fi

[[ -n "${RPM_SIGNING_KEY_FILE:-}" ]] && export RPM_SIGNING_KEY="$(cat "$RPM_SIGNING_KEY_FILE")"

echo "== 3/4 RPM build (hálózat nélküli konténer)"
STAGE="$(mktemp -d)"; CID=""
cleanup() { [[ -n "$CID" ]] && podman rm -f "$CID" >/dev/null 2>&1 || true; rm -rf "$STAGE"; }
trap cleanup EXIT
mkdir -p "$STAGE/SOURCES" "$STAGE/SPECS"
cp "$TARBALL" "$STAGE/SOURCES/"
cp "$NAME.spec" "$STAGE/SPECS/"
cp container-build.sh "$STAGE/"

CID="$(podman create --network=none --security-opt=no-new-privileges \
    --cap-drop=ALL --cap-add=CHOWN --cap-add=DAC_OVERRIDE --cap-add=FOWNER --cap-add=SETUID --cap-add=SETGID \
    -e NAME -e VERSION -e RELEASE -e PREFIX -e RPM_SIGNING_KEY \
    "$TAG" bash /root/rpmbuild/container-build.sh)"
podman cp "$STAGE/." "$CID:/root/rpmbuild/"
podman start -a "$CID"

rm -rf "$OUT"; mkdir -p "$OUT"
podman cp "$CID:/root/rpmbuild/RPMS/x86_64/." "$OUT/"
podman cp "$CID:/root/rpmbuild/SRPMS/."       "$OUT/"
( cd "$OUT" && sha256sum ./*.rpm | sed 's|\./||' > SHA256SUMS )

echo "== 4/4 clean-room teszt (ubi7, hálózat nélkül)"
V="$(mktemp -d)"; trap 'cleanup; rm -rf "$V"' EXIT
cp "$OUT"/*.rpm "$OUT/SHA256SUMS" verify-inside.sh "$V/"
export EXPECT_SIGNED=0
if [[ -n "${RPM_PUBKEY_FILE:-}" ]]; then cp "$RPM_PUBKEY_FILE" "$V/RPM-GPG-KEY.pub"; EXPECT_SIGNED=1; fi
chmod -R a+rX "$V"
podman run --rm --network=none --security-opt=no-new-privileges \
    -v "$V:/rpms:ro,Z" -e NAME -e VERSION -e PREFIX -e EXPECT_SIGNED \
    "$VERIFY_IMAGE" bash /rpms/verify-inside.sh

echo
echo "KÉSZ. Eredmény:"; ls -l "$OUT"

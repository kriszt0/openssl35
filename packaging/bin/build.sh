#!/usr/bin/env bash
# Host oldal: builder image (cache-elve) -> izolált, hálózat nélküli build konténer -> out/
# Bind mount nincs: podman create/cp/start/cp, így nincs uid/SELinux gond és a konténer semmit nem ír a hostra.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG="${PKG:-openssl35}"
set -a; . "$ROOT/packaging/pkgs/$PKG.env"; set +a

BASE_IMAGE="${BUILD_BASE_IMAGE:-docker.io/library/oraclelinux:7}"
TAG="localhost/rpm-builder-el7:$(sha256sum "$ROOT/packaging/Containerfile.builder" | cut -c1-12)"
OUT="$ROOT/out"
SRC="$ROOT/work/SOURCES/$TARBALL"
[[ -f "$SRC" ]] || { echo "HIBA: előbb futtasd a fetch-source.sh-t" >&2; exit 1; }

if ! podman image exists "$TAG"; then
    podman build --build-arg "BASE_IMAGE=$BASE_IMAGE" \
        -f "$ROOT/packaging/Containerfile.builder" -t "$TAG" "$ROOT/packaging"
fi

STAGE="$(mktemp -d)"
CID=""
cleanup() { [[ -n "$CID" ]] && podman rm -f "$CID" >/dev/null 2>&1 || true; rm -rf "$STAGE"; }
trap cleanup EXIT

mkdir -p "$STAGE/SOURCES" "$STAGE/SPECS"
cp "$SRC" "$STAGE/SOURCES/"
cp "$ROOT/packaging/$NAME.spec" "$STAGE/SPECS/"
cp "$ROOT/packaging/bin/container-build.sh" "$STAGE/"

# -e VAR érték nélkül: a titok nem kerül a parancssorba (ps), csak a konténer env-jébe, amit az rm töröl.
CID="$(podman create \
    --network=none \
    --security-opt=no-new-privileges \
    --cap-drop=ALL --cap-add=CHOWN --cap-add=DAC_OVERRIDE --cap-add=FOWNER --cap-add=SETUID --cap-add=SETGID \
    -e NAME -e VERSION -e RELEASE -e PREFIX -e RPM_SIGNING_KEY \
    "$TAG" bash /root/rpmbuild/container-build.sh)"

podman cp "$STAGE/." "$CID:/root/rpmbuild/"
podman start -a "$CID"

rm -rf "$OUT"; mkdir -p "$OUT"
podman cp "$CID:/root/rpmbuild/RPMS/x86_64/." "$OUT/"
podman cp "$CID:/root/rpmbuild/SRPMS/."       "$OUT/"
( cd "$OUT" && sha256sum ./*.rpm | sed 's|\./||' > SHA256SUMS && cat SHA256SUMS )

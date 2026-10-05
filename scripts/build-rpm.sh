#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"
load_config

mkdir -p "$ROOT/artifacts"
mkdir -p "$ROOT/work/logs"

podman build \
    --pull=never \
    --build-arg "BASE_IMAGE=$BUILD_IMAGE" \
    -t "localhost/openssl35-builder:${VERSION}" \
    -f "$ROOT/container/Containerfile.build" \
    "$ROOT" \
    | tee "$ROOT/work/logs/container-build.log"

podman run --rm \
    -v "$ROOT/work/source/openssl-${VERSION}.tar.gz:/input/openssl-${VERSION}.tar.gz:ro,Z" \
    -v "$ROOT/rpm/openssl35.spec:/input/openssl35.spec:ro,Z" \
    -v "$ROOT/artifacts:/output:Z" \
    "localhost/openssl35-builder:${VERSION}" \
    bash -euxo pipefail -c '

        RPMBUILD=/tmp/rpmbuild

        mkdir -p \
            ${RPMBUILD}/BUILD \
            ${RPMBUILD}/BUILDROOT \
            ${RPMBUILD}/RPMS \
            ${RPMBUILD}/SOURCES \
            ${RPMBUILD}/SPECS \
            ${RPMBUILD}/SRPMS

        cp /input/openssl-'"$VERSION"'.tar.gz \
           ${RPMBUILD}/SOURCES/

        cp /input/openssl35.spec \
           ${RPMBUILD}/SPECS/

        rpmbuild -ba \
            ${RPMBUILD}/SPECS/openssl35.spec \
            --define "_topdir ${RPMBUILD}" \
            --define "openssl_version '"$VERSION"'"

        find ${RPMBUILD}/RPMS \
            -type f \
            -name "*.rpm" \
            -exec cp {} /output/ \;

        find ${RPMBUILD}/SRPMS \
            -type f \
            -name "*.rpm" \
            -exec cp {} /output/ \;

        echo "===== RESULT ====="
        ls -lh /output/
    ' 2>&1 | tee "$ROOT/work/logs/rpmbuild.log"

find "$ROOT/artifacts" \
    -maxdepth 1 \
    -type f \
    -name 'openssl35-*.rpm' \
    | grep -q . || die "no binary RPM produced"

log "RPM build PASS"
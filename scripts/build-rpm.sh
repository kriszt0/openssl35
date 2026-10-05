#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

mkdir_secure "$ROOT/artifacts"
mkdir_secure "$ROOT/work/logs"

podman build --pull=never \
  --build-arg "BASE_IMAGE=$BUILD_IMAGE" \
  -t "localhost/openssl35-builder:${VERSION}" \
  -f "$ROOT/container/Containerfile.build" "$ROOT" \
  | tee "$ROOT/work/logs/container-build.log"

podman run --rm \
  -v "$ROOT:/workspace:Z" \
  -w /workspace \
  "localhost/openssl35-builder:${VERSION}" \
  bash -euxo pipefail -c '
    rm -rf work/rpmbuild
    mkdir -p work/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
    cp "work/source/openssl-'"$VERSION"'.tar.gz" work/rpmbuild/SOURCES/
    cp rpm/openssl35.spec work/rpmbuild/SPECS/
    rpmbuild -ba work/rpmbuild/SPECS/openssl35.spec \
      --define "_topdir /workspace/work/rpmbuild" \
      --define "openssl_version '"$VERSION"'"
    find work/rpmbuild/RPMS -type f -name "*.rpm" -exec cp -f {} artifacts/ \;
    find work/rpmbuild/SRPMS -type f -name "*.rpm" -exec cp -f {} artifacts/ \;
  ' 2>&1 | tee "$ROOT/work/logs/rpmbuild.log"

find "$ROOT/artifacts" -type f -name 'openssl35-*.rpm' | grep -q . || die "no binary RPM produced"
log "RPM build PASS"

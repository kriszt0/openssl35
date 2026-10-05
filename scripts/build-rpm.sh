#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
mkdir -p "$ROOT/work/rpmbuild"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
cp "$ROOT/work/source/${SOURCE_BASENAME}.tar.gz" "$ROOT/work/rpmbuild/SOURCES/"
cp "$ROOT/rpm/openssl35.spec" "$ROOT/work/rpmbuild/SPECS/"
podman run --rm -v "$ROOT:/src:Z" company/openssl35-builder:ol7 bash -lc "rpmbuild -ba /src/work/rpmbuild/SPECS/openssl35.spec --define '_topdir /src/work/rpmbuild' --define 'openssl_version ${OPENSSL_VERSION}' --define 'rpm_release ${RPM_RELEASE}'"
find "$ROOT/work/rpmbuild" -type f -name '*.rpm' -exec cp -f {} "$ROOT/out/" \;

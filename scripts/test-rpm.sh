#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config
mkdir_secure "$ROOT/work/logs"

RPM="$(find "$ROOT/artifacts" -maxdepth 1 -type f -name 'openssl35-*.x86_64.rpm' | head -1)"
[[ -n "$RPM" ]] || die "binary RPM missing"

podman build --pull=never \
  --build-arg "BASE_IMAGE=$TEST_IMAGE" \
  -t "localhost/openssl35-test:${VERSION}" \
  -f "$ROOT/container/Containerfile.test" "$ROOT" \
  | tee "$ROOT/work/logs/test-container-build.log"

podman run --rm \
  -v "$ROOT/artifacts:/rpms:ro,Z" \
  "localhost/openssl35-test:${VERSION}" \
  bash -euxo pipefail -c '
    rpm -qpi /rpms/'"$(basename "$RPM")"'
    rpm -qpl /rpms/'"$(basename "$RPM")"' | grep "/opt/company/openssl/'"$VERSION"'/bin/openssl"
    yum localinstall -y /rpms/'"$(basename "$RPM")"'
    /opt/company/openssl/'"$VERSION"'/bin/openssl version -a
    /opt/company/openssl/'"$VERSION"'/bin/openssl list -providers
    printf "audit-test\n" >/tmp/plain
    /opt/company/openssl/'"$VERSION"'/bin/openssl dgst -sha256 /tmp/plain
    /opt/company/openssl/'"$VERSION"'/bin/openssl dgst -sha1 /tmp/plain
    test -L /opt/company/openssl/current
  ' 2>&1 | tee "$ROOT/work/logs/rpm-test.log"

echo "RPM_TEST=PASS" > "$ROOT/work/logs/test-result.env"
log "clean OL7 RPM test PASS"

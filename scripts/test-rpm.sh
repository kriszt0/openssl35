#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"
load_config

mkdir_secure "$ROOT/work/logs"

RPM="$ROOT/artifacts/openssl35-${VERSION}-1.el7.x86_64.rpm"
[[ -f "$RPM" ]] || die "binary RPM missing: $RPM"

RPM_BASENAME="$(basename "$RPM")"

log "testing RPM: $RPM_BASENAME"

podman build --pull=never \
  --build-arg "BASE_IMAGE=$TEST_IMAGE" \
  -t "localhost/openssl35-test:${VERSION}" \
  -f "$ROOT/container/Containerfile.test" "$ROOT" \
  | tee "$ROOT/work/logs/test-container-build.log"

podman run --rm \
  -v "$ROOT/artifacts:/rpms:ro,Z" \
  "localhost/openssl35-test:${VERSION}" \
  bash -euxo pipefail -c '

    RPM="/rpms/'"$RPM_BASENAME"'"

    echo "===== RPM METADATA ====="
    rpm -qpi "$RPM"

    echo "===== INSTALL PREFIX CHECK ====="
    rpm -qpl "$RPM" | grep "^/opt/openssl35/bin/openssl$"

    echo "===== OLD PREFIX CHECK ====="
    if rpm -qpl "$RPM" | grep -q "^/opt/company/openssl"; then
        echo "ERROR: old /opt/company/openssl prefix found in RPM"
        exit 1
    fi

    echo "===== RPM INSTALL ====="
    yum localinstall -y "$RPM"

    echo "===== OPENSSL VERSION ====="
    /opt/openssl35/bin/openssl version -a

    echo "===== PROVIDERS ====="
    /opt/openssl35/bin/openssl list -providers

    echo "===== CRYPTO SMOKE TEST ====="
    printf "audit-test\n" >/tmp/plain

    /opt/openssl35/bin/openssl dgst -sha256 /tmp/plain
    /opt/openssl35/bin/openssl dgst -sha1 /tmp/plain

    echo "===== SYSTEM OPENSSL ====="
    /usr/bin/openssl version

    echo "===== TEST PASS ====="
  ' 2>&1 | tee "$ROOT/work/logs/rpm-test.log"

echo "RPM_TEST=PASS" > "$ROOT/work/logs/test-result.env"

log "clean OL7 RPM test PASS"
#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
RPM="$(find "$ROOT/out" -maxdepth 1 -name 'openssl35-*.x86_64.rpm' | head -1)"
[[ -s "$RPM" ]] || exit 30
podman run --rm -v "$ROOT:/src:Z" company/openssl35-builder:ol7 bash -lc "set -e; yum -y localinstall /src/out/$(basename "$RPM"); /opt/company/openssl/current/bin/openssl version -a; echo test | /opt/company/openssl/current/bin/openssl dgst -sha256; /opt/company/openssl/current/bin/openssl list -providers; rpm -V openssl35"
echo RPM_TEST=PASS | tee "$ROOT/out/test-result.txt"

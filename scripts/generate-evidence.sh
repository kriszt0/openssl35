#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

mkdir_secure "$ROOT/artifacts/evidence"
E="$ROOT/artifacts/evidence"

find "$ROOT/artifacts" -maxdepth 1 -type f -name '*.rpm' -print0 | sort -z | xargs -0 -r sha256sum > "$E/RPM-SHA256SUMS"
find "$ROOT/artifacts" -maxdepth 1 -type f -name '*.rpm' -print0 | sort -z | xargs -0 -r sha1sum > "$E/RPM-SHA1SUMS"

cp "$ROOT/work/source/fetch.env" "$E/source-fetch.env"
cp "$ROOT/work/source/verification.env" "$E/source-verification.env"
cp "$ROOT/work/logs/"*.log "$E/" 2>/dev/null || true
cp "$ROOT/work/logs/test-result.env" "$E/" 2>/dev/null || true

builder_id="$(podman image inspect "localhost/openssl35-builder:${VERSION}" --format '{{.Id}}' 2>/dev/null || echo unknown)"
test_id="$(podman image inspect "localhost/openssl35-test:${VERSION}" --format '{{.Id}}' 2>/dev/null || echo unknown)"
git_commit="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo not-a-git-checkout)"
spec_sha="$(sha256_file "$ROOT/rpm/openssl35.spec")"

cat > "$E/manifest.json" <<EOF
{
  "schema": "company-openssl-rpm-artifact-v1",
  "product": "openssl35",
  "openssl_version": "$VERSION",
  "target_os": "Oracle Linux 7",
  "target_arch": "x86_64",
  "install_prefix": "/opt/openssl35",
  "git_commit": "$git_commit",
  "spec_sha256": "$spec_sha",
  "builder_image_id": "$builder_id",
  "test_image_id": "$test_id",
  "build_timestamp_utc": "$(date -u +%FT%TZ)",
  "rpm_signing_fingerprint": "${RPM_GPG_FINGERPRINT:-not-recorded}",
  "sha1_purpose": "legacy audit evidence only"
}
EOF

sha256sum "$E/manifest.json" > "$E/manifest.json.sha256"
sha1sum "$E/manifest.json" > "$E/manifest.json.sha1"

{
  echo "OpenSSL RPM provenance"
  echo "version=$VERSION"
  echo "git_commit=$git_commit"
  echo "spec_sha256=$spec_sha"
  echo "builder_image_id=$builder_id"
  echo "test_image_id=$test_id"
  echo "timestamp_utc=$(date -u +%FT%TZ)"
  echo
  cat "$ROOT/work/source/fetch.env"
  cat "$ROOT/work/source/verification.env"
  echo
  cat "$E/RPM-SHA256SUMS"
  cat "$E/RPM-SHA1SUMS"
} > "$E/provenance.txt"

sha256sum "$E/provenance.txt" > "$E/provenance.txt.sha256"
sha1sum "$E/provenance.txt" > "$E/provenance.txt.sha1"

log "audit evidence generated"

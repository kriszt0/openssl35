#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

for cmd in podman curl sha256sum sha1sum gpg rpm make awk sed grep tar; do
  command -v "$cmd" >/dev/null 2>&1 || die "missing host command: $cmd"
done

CHECKSUM_FILE="$ROOT/config/checksums/${VERSION}.env"
[[ -f "$CHECKSUM_FILE" ]] || die "missing $CHECKSUM_FILE (copy the .example and insert approved digest)"

# shellcheck disable=SC1090
source "$CHECKSUM_FILE"
if [[ "${REQUIRE_PINNED_SHA256}" == "1" ]]; then
  [[ "${SOURCE_SHA256:-}" =~ ^[A-Fa-f0-9]{64}$ ]] || die "valid pinned SOURCE_SHA256 is mandatory"
fi

if [[ "${REQUIRE_UPSTREAM_SIGNATURE}" == "1" ]]; then
  [[ "$OPENSSL_UPSTREAM_GPG_FINGERPRINT" != REPLACE_* ]] || die "set approved upstream GPG fingerprint"
  [[ -d "$OPENSSL_UPSTREAM_GNUPGHOME" ]] || die "approved upstream GNUPGHOME missing"
fi

if [[ "${REQUIRE_PINNED_CONTAINER_DIGEST}" == "1" ]]; then
  [[ "$BUILD_IMAGE" == *@sha256:* ]] || die "BUILD_IMAGE is not digest-pinned"
  [[ "$TEST_IMAGE" == *@sha256:* ]] || die "TEST_IMAGE is not digest-pinned"
fi

log "preflight PASS for OpenSSL $VERSION"

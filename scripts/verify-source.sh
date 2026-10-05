#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

CHECKSUM_FILE="$ROOT/config/checksums/${VERSION}.env"
# shellcheck disable=SC1090
source "$CHECKSUM_FILE"

TARBALL="$ROOT/work/source/openssl-${VERSION}.tar.gz"
SIG="$TARBALL.asc"
[[ -s "$TARBALL" ]] || die "build source missing"

ACTUAL256="$(sha256_file "$TARBALL")"
ACTUAL1="$(sha1_file "$TARBALL")"

# The pinned checksum applies to the canonical tarball. Offline ZIP is permitted
# only when its normalized build tarball is separately approved/pinned.
[[ "$ACTUAL256" == "${SOURCE_SHA256,,}" ]] || die "SHA256 mismatch"
if [[ -n "${SOURCE_SHA1:-}" ]]; then
  [[ "$ACTUAL1" == "${SOURCE_SHA1,,}" ]] || die "SHA1 reference mismatch"
fi

tar -tzf "$TARBALL" >/dev/null

sig_status="NOT_REQUIRED"
if [[ "${REQUIRE_UPSTREAM_SIGNATURE}" == "1" ]]; then
  [[ -s "$SIG" ]] || die "upstream detached signature missing"
  status="$(
    GNUPGHOME="$OPENSSL_UPSTREAM_GNUPGHOME" \
      gpg --batch --status-fd=1 --verify "$SIG" "$TARBALL" 2>/dev/null || true
  )"
  echo "$status" | grep -q '^\[GNUPG:\] VALIDSIG ' || die "OpenPGP signature invalid"
  fp="$(echo "$status" | awk '/^\[GNUPG:\] VALIDSIG / {print $3; exit}')"
  [[ "${fp^^}" == "${OPENSSL_UPSTREAM_GPG_FINGERPRINT^^}" ]] || die "unexpected upstream signing fingerprint"
  sig_status="PASS:$fp"
fi

{
  echo "VERIFIED_SOURCE_SHA256=$ACTUAL256"
  echo "AUDIT_SOURCE_SHA1=$ACTUAL1"
  echo "UPSTREAM_SIGNATURE=$sig_status"
} > "$ROOT/work/source/verification.env"

log "source verification PASS"

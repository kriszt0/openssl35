#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
F="$ROOT/work/source/${SOURCE_BASENAME}.tar.gz"
[[ -s "$F" ]] || { echo missing source >&2; exit 21; }
sha256sum "$F" | tee "$ROOT/out/source.sha256"
sha1sum "$F" | tee "$ROOT/out/source.sha1"
tar -tzf "$F" >/dev/null
if [[ "${CI:-false}" == true && ! -f "$ROOT/config/checksums.env" ]]; then echo 'Production CI requires pinned checksums.env' >&2; exit 22; fi
if [[ -f "$ROOT/config/checksums.env" ]]; then
 source "$ROOT/config/checksums.env"
 ACT256="$(sha256sum "$F"|awk '{print $1}')"; ACT1="$(sha1sum "$F"|awk '{print $1}')"
 [[ -n "${OPENSSL_SOURCE_SHA256:-}" && "$ACT256" == "$OPENSSL_SOURCE_SHA256" ]] || { echo SHA256_MISMATCH >&2; exit 23; }
 [[ -n "${OPENSSL_SOURCE_SHA1:-}" && "$ACT1" == "$OPENSSL_SOURCE_SHA1" ]] || { echo SHA1_MISMATCH >&2; exit 24; }
fi
echo SOURCE_VERIFICATION=PASS | tee "$ROOT/out/source-verification.txt"

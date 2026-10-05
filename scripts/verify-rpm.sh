#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config
mkdir_secure "$ROOT/work/logs"

: > "$ROOT/work/logs/rpm-signature-verification.log"
for f in "$ROOT"/artifacts/*.rpm; do
  [[ -f "$f" ]] || continue
  out="$(rpm --checksig -v "$f" 2>&1)"
  echo "$out" | tee -a "$ROOT/work/logs/rpm-signature-verification.log"
  if [[ "${REQUIRE_RPM_SIGNATURE}" == "1" ]]; then
    echo "$out" | grep -Eqi 'signature.*(OK|pgp|rsa|dsa)' || die "RPM signature verification failed: $f"
  fi
done
log "RPM signature verification completed"

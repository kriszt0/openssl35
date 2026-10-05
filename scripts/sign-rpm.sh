#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

[[ -n "${RPM_GPG_FINGERPRINT:-}" ]] || die "RPM_GPG_FINGERPRINT is required"
command -v rpmsign >/dev/null 2>&1 || die "rpmsign is required on signing host"

for f in "$ROOT"/artifacts/*.rpm; do
  [[ -f "$f" ]] || continue
  rpmsign --addsign \
    --define "_gpg_name ${RPM_GPG_FINGERPRINT}" \
    "$f"
done

log "RPM signing completed"

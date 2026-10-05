#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
: "${RPM_GPG_KEY_ID:?RPM_GPG_KEY_ID required}"
cat > "$HOME/.rpmmacros" <<MAC
%_signature gpg
%_gpg_name ${RPM_GPG_KEY_ID}
MAC
for f in "$ROOT"/out/*.rpm; do rpmsign --addsign "$f"; rpm -Kv "$f" | tee "${f}.signature.txt"; done

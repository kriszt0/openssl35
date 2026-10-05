#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

if [[ "${ALLOW_UNSIGNED:-0}" != "1" && "${REQUIRE_RPM_SIGNATURE}" == "1" ]]; then
  [[ -s "$ROOT/work/logs/rpm-signature-verification.log" ]] || die "signature verification evidence missing"
fi

DEST="$ROOT/release/openssl-${VERSION}"
rm -rf "$DEST"
mkdir -p "$DEST"/{RPMS,SRPMS,evidence,yum}

find "$ROOT/artifacts" -maxdepth 1 -type f -name '*.src.rpm' -exec cp {} "$DEST/SRPMS/" \;
find "$ROOT/artifacts" -maxdepth 1 -type f -name '*.rpm' ! -name '*.src.rpm' -exec cp {} "$DEST/RPMS/" \;
cp -a "$ROOT/artifacts/evidence/." "$DEST/evidence/"
cp -a "$ROOT/work/yumrepo/." "$DEST/yum/" 2>/dev/null || true

if [[ -s "$ROOT/repo/RPM-GPG-KEY-COMPANY" ]]; then
  cp "$ROOT/repo/RPM-GPG-KEY-COMPANY" "$DEST/"
fi

(
  cd "$DEST"
  find . -type f ! -name RELEASE-SHA256SUMS ! -name RELEASE-SHA1SUMS -print0 | sort -z | xargs -0 sha256sum > RELEASE-SHA256SUMS
  find . -type f ! -name RELEASE-SHA256SUMS ! -name RELEASE-SHA1SUMS -print0 | sort -z | xargs -0 sha1sum > RELEASE-SHA1SUMS
)

log "release assembled: $DEST"

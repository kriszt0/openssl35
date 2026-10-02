#!/usr/bin/env bash
# Host oldalon fut: letölti a forrást és SHA256-ot ellenőriz. A build konténer már hálózat nélkül fut.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG="${PKG:-openssl35}"
set -a; . "$ROOT/packaging/pkgs/$PKG.env"; set +a

[[ "$SHA256" =~ ^[0-9a-f]{64}$ ]] || { echo "HIBA: a SHA256 nincs rögzítve a pkgs/$PKG.env-ben" >&2; exit 1; }
[[ "$SOURCE_URL" == https://* ]]   || { echo "HIBA: csak https forrás engedélyezett" >&2; exit 1; }

DEST="$ROOT/work/SOURCES"
mkdir -p "$DEST"
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
     --retry 3 --max-time 600 -o "$DEST/$TARBALL" "$SOURCE_URL"
echo "$SHA256  $DEST/$TARBALL" | sha256sum -c -

#!/usr/bin/env bash
# Opcionális: feltöltés a Gitea RPM registrybe (tag build). A token nem kerül a parancssorba.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG="${PKG:-openssl35}"
set -a; . "$ROOT/packaging/pkgs/$PKG.env"; set +a
: "${GITEA_BASE_URL:?}" "${GITEA_OWNER:?}" "${PACKAGES_USER:?}" "${PACKAGES_TOKEN:?}"

shopt -s nullglob
f=( "$ROOT"/out/${NAME}-${VERSION}-${RELEASE}*.x86_64.rpm )
[[ ${#f[@]} -eq 1 ]] || { echo "HIBA: nem egyértelmű rpm" >&2; exit 1; }

printf 'user = "%s:%s"\n' "$PACKAGES_USER" "$PACKAGES_TOKEN" | \
curl -K - --fail --silent --show-error --proto '=https' --tlsv1.2 \
     --upload-file "${f[0]}" "${GITEA_BASE_URL%/}/api/packages/${GITEA_OWNER}/rpm/upload"
echo "feltöltve: ${f[0]##*/}"

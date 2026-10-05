#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

REPO="$ROOT/work/yumrepo/ol7/x86_64"
rm -rf "$ROOT/work/yumrepo"
mkdir -p "$REPO"
cp "$ROOT"/artifacts/*.rpm "$REPO/"

# Run repository tooling in a disposable container to avoid host dependencies.
podman run --rm \
  -v "$ROOT/work/yumrepo:/repo:Z" \
  "$BUILD_IMAGE" \
  bash -euxo pipefail -c '
    yum -y install createrepo || yum -y install createrepo_c
    if command -v createrepo_c >/dev/null 2>&1; then
      createrepo_c /repo/ol7/x86_64
    else
      createrepo /repo/ol7/x86_64
    fi
  '

sed \
  -e "s|__REPO_ID__|$REPO_ID|g" \
  -e "s|__REPO_NAME__|$REPO_NAME|g" \
  -e "s|__REPO_BASE_URL__|$REPO_BASE_URL|g" \
  -e "s|__REPO_GPG_KEY_URL__|$REPO_GPG_KEY_URL|g" \
  "$ROOT/repo/openssl35.repo.template" > "$ROOT/work/yumrepo/openssl35.repo"

sha256sum "$REPO/repodata/repomd.xml" > "$REPO/repodata/repomd.xml.sha256"
sha1sum "$REPO/repodata/repomd.xml" > "$REPO/repodata/repomd.xml.sha1"

log "YUM repository generated"

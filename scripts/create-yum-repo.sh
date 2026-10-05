#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
DEST="$ROOT/out/yum/ol7/x86_64"; mkdir -p "$DEST"; cp "$ROOT"/out/openssl35-*.x86_64.rpm "$DEST/"
podman run --rm -v "$ROOT:/src:Z" company/openssl35-builder:ol7 bash -lc 'createrepo /src/out/yum/ol7/x86_64'
sha256sum "$DEST/repodata/repomd.xml" > "$DEST/repodata/repomd.xml.sha256"
sha1sum "$DEST/repodata/repomd.xml" > "$DEST/repodata/repomd.xml.sha1"

#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
TARBALL="$ROOT/work/source/${SOURCE_BASENAME}.tar.gz"
ZIPFILE="$ROOT/work/source/${SOURCE_BASENAME}.zip"
LOCAL_TGZ="$ROOT/download/${SOURCE_BASENAME}.tar.gz"
LOCAL_ZIP="$ROOT/download/${SOURCE_BASENAME}.zip"
UPSTREAM="https://github.com/openssl/openssl/releases/download/${TAG}/${SOURCE_BASENAME}.tar.gz"
ORIGIN="$ROOT/work/source/origin.env"
rm -f "$TARBALL" "$ZIPFILE"
if curl --fail --location --retry 3 --connect-timeout 15 --proto '=https' "$UPSTREAM" -o "$TARBALL.tmp"; then
  mv "$TARBALL.tmp" "$TARBALL"; printf 'SOURCE_ORIGIN=upstream\nSOURCE_URL=%s\n' "$UPSTREAM" > "$ORIGIN"
elif [[ -s "$LOCAL_TGZ" ]]; then
  cp "$LOCAL_TGZ" "$TARBALL"; printf 'SOURCE_ORIGIN=offline-tarball\nSOURCE_URL=%s\n' "$LOCAL_TGZ" > "$ORIGIN"
elif [[ -s "$LOCAL_ZIP" ]]; then
  cp "$LOCAL_ZIP" "$ZIPFILE"; rm -rf "$ROOT/work/unzip"; mkdir -p "$ROOT/work/unzip"; unzip -q "$ZIPFILE" -d "$ROOT/work/unzip"
  SRC_DIR="$(find "$ROOT/work/unzip" -mindepth 1 -maxdepth 1 -type d | head -1)"; tar -C "$(dirname "$SRC_DIR")" -czf "$TARBALL" "$(basename "$SRC_DIR")"
  printf 'SOURCE_ORIGIN=offline-zip\nSOURCE_URL=%s\n' "$LOCAL_ZIP" > "$ORIGIN"
else
  rm -f "$TARBALL.tmp"; echo "No verified source available" >&2; exit 20
fi
cat "$ORIGIN"

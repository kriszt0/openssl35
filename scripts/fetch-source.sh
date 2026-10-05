#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

mkdir_secure "$ROOT/work/source"
EVIDENCE="$ROOT/work/source/fetch.env"
rm -f "$EVIDENCE"

TARBALL="openssl-${VERSION}.tar.gz"
ZIPFILE="openssl-${VERSION}.zip"
OUT="$ROOT/work/source/$TARBALL"
SIG="$ROOT/work/source/$TARBALL.asc"

UPSTREAM_BASE="${OPENSSL_SOURCE_BASE_URL:-https://github.com/openssl/openssl/releases/download/openssl-${VERSION}}"
UPSTREAM_URL="${UPSTREAM_BASE}/${TARBALL}"
UPSTREAM_SIG_URL="${UPSTREAM_URL}.asc"

origin=""
original=""

# Prefer exact offline fallback if deliberately supplied.
if [[ -s "$ROOT/download/$TARBALL" ]]; then
  cp -- "$ROOT/download/$TARBALL" "$OUT"
  origin="offline-tar"
  original="$OUT"
elif [[ -s "$ROOT/download/$ZIPFILE" ]]; then
  cp -- "$ROOT/download/$ZIPFILE" "$ROOT/work/source/$ZIPFILE"
  origin="offline-zip"
  original="$ROOT/work/source/$ZIPFILE"
else
  tmp="$OUT.part"
  rm -f "$tmp"
  if curl --fail --location --retry 3 --retry-all-errors \
      --connect-timeout 15 --max-time 300 \
      --proto '=https' --tlsv1.2 "$UPSTREAM_URL" -o "$tmp"; then
    mv "$tmp" "$OUT"
    origin="upstream"
    original="$OUT"
  else
    rm -f "$tmp"
    die "upstream unavailable and no exact offline fallback found"
  fi
fi

{
  echo "SOURCE_ORIGIN=$origin"
  echo "SOURCE_ORIGINAL_FILE=$(basename "$original")"
  echo "SOURCE_ORIGINAL_SHA256=$(sha256_file "$original")"
  echo "SOURCE_ORIGINAL_SHA1=$(sha1_file "$original")"
  echo "SOURCE_URL=$UPSTREAM_URL"
} > "$EVIDENCE"

if [[ "$origin" == "offline-zip" ]]; then
  rm -rf "$ROOT/work/source/unpack"
  mkdir "$ROOT/work/source/unpack"
  unzip -q "$original" -d "$ROOT/work/source/unpack"
  top="$(find "$ROOT/work/source/unpack" -mindepth 1 -maxdepth 1 -type d | head -1)"
  [[ -n "$top" ]] || die "ZIP has no top-level source directory"
  mv "$top" "$ROOT/work/source/openssl-${VERSION}"
  tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner \
      -czf "$OUT" -C "$ROOT/work/source" "openssl-${VERSION}"
  rm -rf "$ROOT/work/source/unpack" "$ROOT/work/source/openssl-${VERSION}"
fi

# Signature is fetched independently only for an upstream canonical tarball.
# For offline operation place the detached signature in download/.
if [[ -s "$ROOT/download/$TARBALL.asc" ]]; then
  cp -- "$ROOT/download/$TARBALL.asc" "$SIG"
elif [[ "$origin" == "upstream" ]]; then
  curl --fail --location --retry 3 --connect-timeout 15 --max-time 120 \
       --proto '=https' --tlsv1.2 "$UPSTREAM_SIG_URL" -o "$SIG" || true
fi

{
  echo "BUILD_SOURCE_FILE=$(basename "$OUT")"
  echo "BUILD_SOURCE_SHA256=$(sha256_file "$OUT")"
  echo "BUILD_SOURCE_SHA1=$(sha1_file "$OUT")"
} >> "$EVIDENCE"

log "source acquired: $origin"
cat "$EVIDENCE"

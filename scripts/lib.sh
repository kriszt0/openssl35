#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"

die() { echo "ERROR: $*" >&2; exit 1; }
log() { printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*"; }

validate_version() {
  [[ "$VERSION" =~ ^3\.5\.[0-9]+$ ]] || die "VERSION must match 3.5.x; got: $VERSION"
}

load_config() {
  validate_version
  # shellcheck disable=SC1091
  source "$ROOT/config/security.env"
  # shellcheck disable=SC1091
  source "$ROOT/config/images.env"
  # shellcheck disable=SC1091
  source "$ROOT/config/repository.env"
}

sha256_file() { sha256sum "$1" | awk '{print $1}'; }
sha1_file() { sha1sum "$1" | awk '{print $1}'; }

mkdir_secure() {
  mkdir -p "$1"
  chmod 0750 "$1" || true
}

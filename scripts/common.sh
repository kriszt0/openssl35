#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/version.env"
TAG="openssl-${OPENSSL_VERSION}"
SOURCE_BASENAME="openssl-${OPENSSL_VERSION}"
mkdir -p "$ROOT/work/source" "$ROOT/out"

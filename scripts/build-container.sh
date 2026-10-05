#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
podman build --pull=never -t company/openssl35-builder:ol7 -f "$ROOT/container/Containerfile.ol7" "$ROOT"

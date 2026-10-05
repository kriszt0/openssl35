#!/usr/bin/env bash

set -euo pipefail

RPM="${1:?Missing RPM}"

echo "=========================================="
echo "RPM SIGNATURE VERIFICATION"
echo "=========================================="

echo
echo "RPM:"
echo "$RPM"

echo

rpm -Kv "$RPM"

echo
echo "RPM signature verification successful."
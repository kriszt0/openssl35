#!/usr/bin/env bash

set -euo pipefail

RPM="${1:?Missing RPM}"

echo "=========================================="
echo "RPM VALIDATION"
echo "=========================================="

echo
echo "RPM metadata:"
rpm -qip "$RPM"

echo
echo "RPM dependencies:"
rpm -qpR "$RPM"

echo
echo "RPM file list:"
rpm -qlp "$RPM"

echo
echo "RPM payload verification:"
rpm -K "$RPM"

echo
echo "RPM validation successful."
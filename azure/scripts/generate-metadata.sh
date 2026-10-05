#!/usr/bin/env bash

set -euo pipefail

TAG="${1:?Missing Git tag}"
RPM="${2:?Missing RPM}"
OUTPUT_DIR="${3:?Missing output directory}"

source ./config/build.env

mkdir -p "$OUTPUT_DIR"

COMMIT="$(git rev-parse HEAD)"

RPM_NAME="$(basename "$RPM")"

SHA1="$(sha1sum "$RPM" | awk '{print $1}')"

SHA256="$(sha256sum "$RPM" | awk '{print $1}')"

BUILD_DATE="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

cat > "$OUTPUT_DIR/BUILDINFO.txt" <<EOF
============================================================
OPENSSL 3.5.9 RPM BUILD INFORMATION
============================================================

Package:
openssl35

RPM:
${RPM_NAME}

OpenSSL version:
${TAG#openssl-}

Git tag:
${TAG}

Git commit:
${COMMIT}

Source repository:
${SOURCE_REPOSITORY}

Azure DevOps Build ID:
${BUILD_BUILDID:-unknown}

Azure DevOps Build Number:
${BUILD_BUILDNUMBER:-unknown}

Azure Source Version:
${BUILD_SOURCEVERSION:-unknown}

Build date UTC:
${BUILD_DATE}

Build agent:
${AGENT_NAME:-unknown}

SHA1:
${SHA1}

SHA256:
${SHA256}
EOF


cat > "$OUTPUT_DIR/build-metadata.json" <<EOF
{
  "package": "openssl35",
  "version": "${TAG#openssl-}",
  "rpm": "${RPM_NAME}",
  "git_tag": "${TAG}",
  "git_commit": "${COMMIT}",
  "source_repository": "${SOURCE_REPOSITORY}",
  "azure_build_id": "${BUILD_BUILDID:-unknown}",
  "azure_build_number": "${BUILD_BUILDNUMBER:-unknown}",
  "azure_source_version": "${BUILD_SOURCEVERSION:-unknown}",
  "build_date_utc": "${BUILD_DATE}",
  "agent": "${AGENT_NAME:-unknown}",
  "sha1": "${SHA1}",
  "sha256": "${SHA256}"
}
EOF
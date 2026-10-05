#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
cd "$ROOT/out"
find . -maxdepth 1 -type f -name '*.rpm' -print0 | sort -z | xargs -0 -r sha256sum > SHA256SUMS
find . -maxdepth 1 -type f -name '*.rpm' -print0 | sort -z | xargs -0 -r sha1sum > SHA1SUMS
cat > manifest.json <<JSON
{
 "schema":"company-openssl-rpm-provenance-v1",
 "product":"openssl35",
 "openssl_version":"${OPENSSL_VERSION}",
 "openssl_tag":"${TAG}",
 "rpm_release":"${RPM_RELEASE}",
 "target":"Oracle Linux 7 x86_64",
 "pipeline_id":"${BUILD_BUILDID:-unknown}",
 "source_commit":"${BUILD_SOURCEVERSION:-unknown}",
 "build_number":"${BUILD_BUILDNUMBER:-unknown}",
 "signing_key_fingerprint":"${RPM_GPG_FINGERPRINT:-unknown}",
 "created_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
sha256sum manifest.json > manifest.json.sha256
sha1sum manifest.json > manifest.json.sha1

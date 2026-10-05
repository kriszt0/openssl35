#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"
load_config

# ----------------------------------------------------------------------
# Parallel build configuration
#
# Default:
#   make build
#       -> JOBS=1
#
# Examples:
#   make build JOBS=4
#   make build JOBS=20
#   make build JOBS="$(nproc)"
# ----------------------------------------------------------------------

JOBS="${JOBS:-1}"

if ! [[ "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
    die "invalid JOBS value: $JOBS"
fi

log "build parallelism: ${JOBS} job(s)"

# ----------------------------------------------------------------------
# Directories
# ----------------------------------------------------------------------

mkdir -p "$ROOT/artifacts"
mkdir_secure "$ROOT/work/logs"

SOURCE="$ROOT/work/source/openssl-${VERSION}.tar.gz"
SPEC="$ROOT/rpm/openssl35.spec"

[[ -f "$SOURCE" ]] || \
    die "source tarball missing: $SOURCE"

[[ -f "$SPEC" ]] || \
    die "RPM spec missing: $SPEC"

# ----------------------------------------------------------------------
# Build Oracle Linux 7 builder container
# ----------------------------------------------------------------------

log "building Oracle Linux 7 RPM builder container"

podman build \
    --pull=never \
    --build-arg "BASE_IMAGE=$BUILD_IMAGE" \
    -t "localhost/openssl35-builder:${VERSION}" \
    -f "$ROOT/container/Containerfile.build" \
    "$ROOT" \
    2>&1 | tee "$ROOT/work/logs/container-build.log"

# ----------------------------------------------------------------------
# Build RPM
#
# rpmbuild itself runs inside the container.
# BUILD/BUILDROOT/etc. are kept under /tmp and disappear when the
# container exits (--rm).
#
# Only the resulting RPM/SRPM files are copied to /output.
# ----------------------------------------------------------------------

log "building OpenSSL ${VERSION} RPM with ${JOBS} job(s)"

podman run --rm \
    -e "JOBS=$JOBS" \
    -v "$SOURCE:/input/openssl-${VERSION}.tar.gz:ro,Z" \
    -v "$SPEC:/input/openssl35.spec:ro,Z" \
    -v "$ROOT/artifacts:/output:Z" \
    "localhost/openssl35-builder:${VERSION}" \
    bash -euxo pipefail -c '

        RPMBUILD=/tmp/rpmbuild

        echo "========================================"
        echo " OpenSSL RPM build"
        echo "========================================"
        echo "Version : '"$VERSION"'"
        echo "Jobs    : ${JOBS}"
        echo "Topdir  : ${RPMBUILD}"
        echo "========================================"

        mkdir -p \
            "${RPMBUILD}/BUILD" \
            "${RPMBUILD}/BUILDROOT" \
            "${RPMBUILD}/RPMS" \
            "${RPMBUILD}/SOURCES" \
            "${RPMBUILD}/SPECS" \
            "${RPMBUILD}/SRPMS"

        # --------------------------------------------------------------
        # Prepare source
        # --------------------------------------------------------------

        cp \
            /input/openssl-'"$VERSION"'.tar.gz \
            "${RPMBUILD}/SOURCES/openssl-'"$VERSION"'.tar.gz"

        cp \
            /input/openssl35.spec \
            "${RPMBUILD}/SPECS/openssl35.spec"

        # --------------------------------------------------------------
        # RPM build
        #
        # build_jobs is consumed by openssl35.spec:
        #
        #   make -j%{build_jobs}
        #   make test -j%{build_jobs}
        # --------------------------------------------------------------

        rpmbuild -ba \
            "${RPMBUILD}/SPECS/openssl35.spec" \
            --define "_topdir ${RPMBUILD}" \
            --define "openssl_version '"$VERSION"'" \
            --define "build_jobs ${JOBS}"

        # --------------------------------------------------------------
        # Copy binary RPMs
        # --------------------------------------------------------------

        find "${RPMBUILD}/RPMS" \
            -type f \
            -name "*.rpm" \
            -exec cp -f {} /output/ \;

        # --------------------------------------------------------------
        # Copy source RPM
        # --------------------------------------------------------------

        find "${RPMBUILD}/SRPMS" \
            -type f \
            -name "*.rpm" \
            -exec cp -f {} /output/ \;

        echo
        echo "========================================"
        echo " RPM BUILD RESULT"
        echo "========================================"

        ls -lh /output/
    ' 2>&1 | tee "$ROOT/work/logs/rpmbuild.log"

# ----------------------------------------------------------------------
# Validate result
# ----------------------------------------------------------------------

RPM="$(
    find "$ROOT/artifacts" \
        -maxdepth 1 \
        -type f \
        -name "openssl35-${VERSION}-*.el7.x86_64.rpm" \
        ! -name "*debuginfo*" \
        | head -1
)"

[[ -n "$RPM" ]] || \
    die "no openssl35 ${VERSION} binary RPM produced"

# ----------------------------------------------------------------------
# Basic RPM metadata validation
# ----------------------------------------------------------------------

RPM_NAME="$(rpm -qp --qf '%{NAME}' "$RPM")"
RPM_VERSION="$(rpm -qp --qf '%{VERSION}' "$RPM")"
RPM_ARCH="$(rpm -qp --qf '%{ARCH}' "$RPM")"

[[ "$RPM_NAME" == "openssl35" ]] || \
    die "unexpected RPM name: $RPM_NAME"

[[ "$RPM_VERSION" == "$VERSION" ]] || \
    die "unexpected RPM version: $RPM_VERSION"

[[ "$RPM_ARCH" == "x86_64" ]] || \
    die "unexpected RPM architecture: $RPM_ARCH"

# ----------------------------------------------------------------------
# Validate installation layout
# ----------------------------------------------------------------------

log "validating RPM installation layout"

rpm -qpl "$RPM" | \
    grep -q '^/opt/openssl35/bin/openssl$' || \
    die "/opt/openssl35/bin/openssl missing from RPM"

if rpm -qpl "$RPM" | grep -q '^/opt/company/openssl'; then
    die "old /opt/company/openssl prefix found in RPM"
fi

# ----------------------------------------------------------------------
# Verify private OpenSSL libraries are packaged
# ----------------------------------------------------------------------

rpm -qpl "$RPM" | \
    grep -q '^/opt/openssl35/lib64/libssl\.so\.3$' || \
    die "libssl.so.3 missing from RPM"

rpm -qpl "$RPM" | \
    grep -q '^/opt/openssl35/lib64/libcrypto\.so\.3$' || \
    die "libcrypto.so.3 missing from RPM"

# ----------------------------------------------------------------------
# Ensure unwanted WWW::Curl dependency did not return
# ----------------------------------------------------------------------

if rpm -qpR "$RPM" | grep -q 'perl(WWW::Curl::Easy)'; then
    die "unwanted perl(WWW::Curl::Easy) dependency found"
fi

# ----------------------------------------------------------------------
# Result
# ----------------------------------------------------------------------

echo
echo "========================================"
echo " RPM BUILD PASS"
echo "========================================"
echo "RPM     : $(basename "$RPM")"
echo "Version : $RPM_VERSION"
echo "Arch    : $RPM_ARCH"
echo "Jobs    : $JOBS"
echo "Prefix  : /opt/openssl35"
echo "Log     : $ROOT/work/logs/rpmbuild.log"
echo "========================================"

log "RPM build PASS"
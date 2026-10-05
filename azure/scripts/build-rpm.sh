#!/usr/bin/env bash

set -euo pipefail

TAG="${1:?Missing Git tag}"
OUTPUT_DIR="${2:?Missing output directory}"

REPO_ROOT="$(pwd)"

source "$REPO_ROOT/config/build.env"

WORKDIR="$(mktemp -d)"

cleanup() {
    rm -rf "$WORKDIR"
}

trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "OPENSSL RPM BUILD"
echo "=========================================="

echo "Repository : $SOURCE_REPOSITORY"
echo "Tag        : $TAG"

if [[ ! "$TAG" =~ ^openssl-3\.5\.[0-9]+$ ]]; then
    echo "ERROR: Invalid OpenSSL tag: $TAG"
    exit 1
fi

VERSION="${TAG#openssl-}"

echo "Version    : $VERSION"

# ------------------------------------------------------------
# Clone
# ------------------------------------------------------------

git clone \
    --branch "$TAG" \
    --depth 1 \
    "$SOURCE_REPOSITORY" \
    "$WORKDIR/openssl"

cd "$WORKDIR/openssl"

COMMIT="$(git rev-parse HEAD)"

echo "Commit     : $COMMIT"

# ------------------------------------------------------------
# Verify tag
# ------------------------------------------------------------

ACTUAL_TAG="$(git describe \
    --tags \
    --exact-match \
    HEAD 2>/dev/null || true)"

if [ "$ACTUAL_TAG" != "$TAG" ]; then
    echo "ERROR: Git tag verification failed"
    exit 1
fi

# ------------------------------------------------------------
# RPM tree
# ------------------------------------------------------------

RPMTOP="$WORKDIR/rpmbuild"

mkdir -p \
    "$RPMTOP/BUILD" \
    "$RPMTOP/BUILDROOT" \
    "$RPMTOP/RPMS" \
    "$RPMTOP/SOURCES" \
    "$RPMTOP/SPECS" \
    "$RPMTOP/SRPMS"

# ------------------------------------------------------------
# Source archive
# ------------------------------------------------------------

git archive \
    --format=tar.gz \
    --prefix="openssl-${VERSION}/" \
    HEAD \
    > "$RPMTOP/SOURCES/openssl-${VERSION}.tar.gz"

# ------------------------------------------------------------
# SPEC
# ------------------------------------------------------------

cp \
    "$REPO_ROOT/packaging/openssl35.spec" \
    "$RPMTOP/SPECS/openssl35.spec"

# ------------------------------------------------------------
# Build RPM
# ------------------------------------------------------------

rpmbuild \
    --define "_topdir $RPMTOP" \
    --define "openssl_version $VERSION" \
    --define "openssl_git_tag $TAG" \
    --define "openssl_git_commit $COMMIT" \
    -ba \
    "$RPMTOP/SPECS/openssl35.spec"

# ------------------------------------------------------------
# Copy RPM
# ------------------------------------------------------------

find "$RPMTOP/RPMS" \
    -type f \
    -name "*.rpm" \
    -exec cp {} "$OUTPUT_DIR/" \;

echo
echo "RPM created:"

find "$OUTPUT_DIR" \
    -type f \
    -name "*.rpm" \
    -print